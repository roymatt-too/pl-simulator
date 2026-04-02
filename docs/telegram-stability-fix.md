# OpenClaw Telegram Bot 安定化ガイド — Telegram チャネル側

**対象**: 5〜6時間おきにボットが無応答になる問題
**担当範囲**: Telegram polling/webhook/network/timeout/監視/復旧
**VPSパス**: `/root/sushihey/`, `/root/.openclaw/`
**スタック**: Python, Claude API, Telegram Bot API, n8n, SQLite, Ubuntu VPS

---

## 1. 根本原因の診断

### 1.1 最も可能性の高い原因（優先度順）

| # | 原因 | 確率 | メカニズム | なぜ5-6時間か |
|---|------|------|-----------|-------------|
| **1** | **stale TCP接続 + ウォッチドッグ不在** | **最高** | ロングポーリング中にTCP接続が半開き状態（remote側がFIN/RSTなしに切断）→ HTTPクライアントが死んだソケットで無限待機 → メッセージ受信停止 | TCP keepaliveデフォルト7200秒（2時間）+ 接続が劣化するまでの累積時間。VPS↔Telegram間の経路上のNAT/ロードバランサーがアイドル接続を切断するタイミングと合致 |
| **2** | **IPv6フォールバック遅延** | **高** | Node.js 22+ / Python 3.12+ のデフォルトがIPv6優先。`api.telegram.org`のIPv6アドレスへのTLSハンドシェイクがタイムアウト → IPv4にフォールバック → リトライ/エラーが蓄積 → 最終的にプロセスがハング | IPv6タイムアウト（各30秒）が断続的に発生し、エラーカウンタやコネクションプールが徐々に劣化 |
| **3** | **httpx/aiohttp コネクションプール枯渇** | **高** | 長時間運用でプール内の接続がstale化 → `ConnectionResetError: [Errno 104]` → エラーハンドリングが不十分な場合、ポーリングループが停止 | python-telegram-bot Issue #1352: 「10時間以上処理後にHTTPSコネクションプール読み取りタイムアウト」 |
| **4** | **n8n Telegram Trigger の webhook 失効** | **中** | n8n再起動時やSSL証明書更新時にTelegramへのwebhook登録が外れる → メッセージが届かなくなる | Let's Encrypt証明書更新（90日ごと）やDocker再起動のタイミングと重なるケースあり |
| **5** | **複数インスタンス競合（409 Conflict）** | **中** | 同じbotトークンで複数の`getUpdates`が走る → 片方がメッセージを奪う → もう片方がデッドロック | デプロイ時のゾンビプロセスや、n8nとPython botの共存 |

### 1.2 VPS上での確認コマンド

```bash
# 1. 現在のポーリング/webhook状態を確認
BOT_TOKEN="YOUR_BOT_TOKEN"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" | python3 -m json.tool

# 結果の読み方:
# - "url": "" → ポーリングモード（webhookなし）
# - "url": "https://..." → webhookモード
# - "last_error_date" / "last_error_message" → 直近のエラー
# - "pending_update_count" → 未処理メッセージ数（大量ならハング中）

# 2. IPv6接続テスト
curl -6 -v --connect-timeout 5 https://api.telegram.org/bot${BOT_TOKEN}/getMe 2>&1 | head -20
# タイムアウトしたらIPv6が原因の可能性大

# 3. IPv4接続テスト
curl -4 -v --connect-timeout 5 https://api.telegram.org/bot${BOT_TOKEN}/getMe 2>&1 | head -20

# 4. DNS解決の確認
dig api.telegram.org AAAA  # IPv6
dig api.telegram.org A     # IPv4

# 5. 実行中のbot関連プロセス確認
ps aux | grep -E "(python|node|n8n|telegram|openclaw)" | grep -v grep

# 6. 複数インスタンスの競合確認
ps aux | grep -c "bot\|openclaw\|telegram"  # 2以上なら競合の疑い

# 7. TCP接続状態の確認
ss -tnp | grep "149.154\|api.telegram"  # Telegram APIへのTCP接続

# 8. システムログでOOM/kill確認
journalctl -u openclaw --since "6 hours ago" --no-pager | tail -50
dmesg | grep -i "oom\|kill" | tail -10

# 9. n8nのwebhook状態確認
docker logs n8n --since "6h" 2>&1 | grep -i "telegram\|webhook\|error" | tail -20
```

---

## 2. 現在の運用方式の判定と推奨

### 2.1 ポーリング vs Webhook の判定

OpenClaw の記事内容から、**n8n の Telegram Trigger ノード（webhook方式）** と **Python bot スクリプト（ポーリング方式の可能性）** が共存していると推定されます。

```bash
# VPSで実行して判定
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" | python3 -m json.tool
```

| `url` フィールド | 判定 | 対処 |
|---|---|---|
| 空文字 `""` | ポーリングモード | → セクション3（ポーリング安定化）またはセクション5（webhook移行） |
| `https://...` | webhookモード | → セクション4（webhook安定化） |

### 2.2 最も安定する運用方式の結論

**Webhook モード + systemd 外部プロセス管理 + ヘルスチェック監視**

理由:
- ポーリングはTCP接続の維持が必要 → stale接続で沈黙
- WebhookはTelegram側がメッセージをPUSHしてくる → 接続維持不要
- Telegram側がdelivery失敗時に自動リトライ（最大24時間）
- ロードバランサー背後で複数サーバー運用も可能
- Bot API 7.5（2025年3月）でwebhookタイムアウト上限が90秒に拡張

---

## 3. ポーリングモードの安定化（webhook移行前の応急処置）

### 3.1 Python bot のタイムアウト修正

**ファイル**: `/root/sushihey/bot.py`（またはメインボットスクリプト）

#### Before（典型的な不安定コード）
```python
from telegram.ext import Application

app = Application.builder().token(BOT_TOKEN).build()
app.run_polling()
```

#### After（安定化済みコード）
```python
import socket
import logging
from telegram.ext import Application
from telegram.request import HTTPXRequest

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# === IPv4強制 ===
# api.telegram.org のIPv6アドレスへのTLSハンドシェイクがタイムアウトする問題を回避
original_getaddrinfo = socket.getaddrinfo
def ipv4_only_getaddrinfo(*args, **kwargs):
    responses = original_getaddrinfo(*args, **kwargs)
    return [r for r in responses if r[0] == socket.AF_INET] or responses
socket.getaddrinfo = ipv4_only_getaddrinfo

# === タイムアウト明示設定 ===
request = HTTPXRequest(
    read_timeout=30.0,        # デフォルト5秒 → 30秒（ポーリング応答待ち）
    write_timeout=30.0,       # デフォルト5秒 → 30秒
    connect_timeout=15.0,     # デフォルト5秒 → 15秒
    pool_timeout=10.0,        # デフォルト1秒 → 10秒（プール枯渇時の待ち時間）
    connection_pool_size=20,  # デフォルト1 → 20（並行リクエスト対応）
)

app = (
    Application.builder()
    .token(BOT_TOKEN)
    .request(request)
    .get_updates_request(HTTPXRequest(
        read_timeout=30.0,
        write_timeout=30.0,
        connect_timeout=15.0,
        pool_timeout=10.0,
    ))
    .build()
)

# === エラーハンドラ ===
async def error_handler(update, context):
    logger.error(f"Exception while handling update: {context.error}", exc_info=context.error)
    # NetworkError は自動リトライに任せる（run_polling が処理する）
    # それ以外の致命的エラーはログに記録

app.add_error_handler(error_handler)

# === ポーリング開始（安定化オプション付き） ===
app.run_polling(
    poll_interval=1.0,          # ポーリング間隔（秒）
    timeout=30,                 # getUpdates の long polling timeout
    drop_pending_updates=True,  # 起動時に未処理メッセージを破棄（重複防止）
    allowed_updates=["message", "callback_query"],  # 必要な更新タイプのみ
    read_timeout=30,            # ソケット読み取りタイムアウト
    write_timeout=30,
    connect_timeout=15,
    pool_timeout=10,
)
```

### 3.2 なぜこの変更で5-6時間おきの落ちが改善するか

| 変更点 | 解決する原因 | メカニズム |
|--------|------------|-----------|
| IPv4強制 | IPv6タイムアウト蓄積 | IPv6へのフォールバック試行が排除され、各リクエストが即座にIPv4で接続 |
| `read_timeout=30` | stale TCP接続の無限待機 | 30秒で応答がなければ接続を切断→ `run_polling`の内部リトライが新しい接続で再開 |
| `connect_timeout=15` | 接続確立の遅延 | 接続が15秒以内に確立しなければ即座にリトライ |
| `pool_timeout=10` | コネクションプール枯渇 | プールから接続を取得できなければ10秒でタイムアウト→新規接続を作成 |
| `connection_pool_size=20` | 並行リクエスト不足 | 同時リクエスト数の上限を引き上げ |
| `error_handler` | 未捕捉例外による停止 | 全エラーをキャッチしてログ記録、ポーリングループを停止させない |

---

## 4. Webhook モードの安定化（n8n 経由の場合）

### 4.1 n8n Telegram Trigger の確認

```bash
# n8n内のwebhook登録状態を確認
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" | python3 -m json.tool

# 正常な出力例:
# {
#   "ok": true,
#   "result": {
#     "url": "https://your-domain.com/webhook/xxx-xxx-xxx",
#     "has_custom_certificate": false,
#     "pending_update_count": 0,
#     "last_error_date": null,
#     "max_connections": 40
#   }
# }
```

### 4.2 n8n Docker Compose の安定化

**ファイル**: `/root/sushihey/docker-compose.yml`（または同等）

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=your-domain.com
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://your-domain.com/
      - NODE_ENV=production
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      # === Telegram安定化: IPv4強制 ===
      - NODE_OPTIONS=--dns-result-order=ipv4first
      # === undici（Node.js built-in fetch）のIPv4強制 ===
      - UV_USE_IO_URING=0
    volumes:
      - n8n_data:/home/node/.n8n
    # === ヘルスチェック ===
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/healthz"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 30s
    # === メモリ制限（OOM防止） ===
    deploy:
      resources:
        limits:
          memory: 1G
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### 4.3 webhook 再登録スクリプト

n8n 再起動時や証明書更新後に webhook が外れることがあります。cron で定期的に確認・再登録する方式を推奨します。

**ファイル**: `/root/sushihey/scripts/check-webhook.sh`

```bash
#!/bin/bash
# Telegram Webhook 状態確認・再登録スクリプト
# cron: */30 * * * * /root/sushihey/scripts/check-webhook.sh >> /var/log/telegram-webhook-check.log 2>&1

set -euo pipefail

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-YOUR_BOT_TOKEN}"
WEBHOOK_URL="https://your-domain.com/webhook/YOUR_N8N_WEBHOOK_PATH"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# 現在のwebhook状態を取得
WEBHOOK_INFO=$(curl -sf "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" 2>/dev/null || echo '{"ok":false}')

CURRENT_URL=$(echo "$WEBHOOK_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('url',''))" 2>/dev/null || echo "")
PENDING=$(echo "$WEBHOOK_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('pending_update_count',0))" 2>/dev/null || echo "0")
LAST_ERROR=$(echo "$WEBHOOK_INFO" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result',{}); print(r.get('last_error_message','none'))" 2>/dev/null || echo "unknown")

echo "${LOG_PREFIX} URL=${CURRENT_URL} PENDING=${PENDING} LAST_ERROR=${LAST_ERROR}"

# webhookが未設定または異なるURLの場合、再登録
if [ "$CURRENT_URL" != "$WEBHOOK_URL" ]; then
    echo "${LOG_PREFIX} WARN: Webhook mismatch. Re-registering..."
    RESULT=$(curl -sf "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook" \
        -d "url=${WEBHOOK_URL}" \
        -d "max_connections=40" \
        -d "drop_pending_updates=false" \
        -d "allowed_updates=[\"message\",\"callback_query\"]" \
        2>/dev/null || echo '{"ok":false}')
    echo "${LOG_PREFIX} setWebhook result: ${RESULT}"
fi

# 未処理メッセージが大量に溜まっている場合（ハングの兆候）
if [ "$PENDING" -gt 100 ]; then
    echo "${LOG_PREFIX} ALERT: ${PENDING} pending updates! Bot may be hung."
    # ここにアラート送信を追加（Telegram通知、メール等）
fi
```

---

## 5. Webhook モードへの移行手順（ポーリング → Webhook）

### 5.1 前提条件

- HTTPS対応のドメイン（Let's Encrypt可）
- ポート443, 80, 88, または8443のいずれかが公開
- SSL証明書が有効（自己署名証明書の場合はTelegram APIに証明書アップロードが必要）

### 5.2 Python bot を Webhook モードに変更

**ファイル**: `/root/sushihey/bot.py`

```python
import socket
import logging
from telegram.ext import Application
from telegram.request import HTTPXRequest

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# IPv4強制
original_getaddrinfo = socket.getaddrinfo
def ipv4_only_getaddrinfo(*args, **kwargs):
    responses = original_getaddrinfo(*args, **kwargs)
    return [r for r in responses if r[0] == socket.AF_INET] or responses
socket.getaddrinfo = ipv4_only_getaddrinfo

# タイムアウト設定
request = HTTPXRequest(
    read_timeout=30.0,
    write_timeout=30.0,
    connect_timeout=15.0,
    pool_timeout=10.0,
    connection_pool_size=20,
)

BOT_TOKEN = "YOUR_BOT_TOKEN"
WEBHOOK_URL = "https://your-domain.com/webhook/bot"
WEBHOOK_PORT = 8443  # Telegramが許可するポート: 443, 80, 88, 8443

app = (
    Application.builder()
    .token(BOT_TOKEN)
    .request(request)
    .build()
)

# ハンドラ登録（既存のものを維持）
# app.add_handler(...)

async def error_handler(update, context):
    logger.error(f"Exception: {context.error}", exc_info=context.error)

app.add_error_handler(error_handler)

# === Webhook モードで起動 ===
app.run_webhook(
    listen="0.0.0.0",
    port=WEBHOOK_PORT,
    url_path="webhook/bot",
    webhook_url=WEBHOOK_URL,
    drop_pending_updates=True,
    allowed_updates=["message", "callback_query"],
    # SSL証明書（Nginx/Caddyでリバプロする場合は不要）
    # cert="/path/to/cert.pem",
    # key="/path/to/key.pem",
)
```

### 5.3 Nginx リバースプロキシ設定（webhookモード用）

**ファイル**: `/etc/nginx/sites-available/telegram-webhook`

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Telegram webhook エンドポイント
    location /webhook/bot {
        proxy_pass http://127.0.0.1:8443/webhook/bot;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # タイムアウト設定
        proxy_connect_timeout 10s;
        proxy_read_timeout 90s;   # Bot API 7.5のwebhookタイムアウト上限に合わせる
        proxy_send_timeout 30s;
    }

    # n8n（既存）
    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
    }
}
```

---

## 6. authが正常でも落ちるケースの対策

### 6.1 ケース一覧と対策

| ケース | 症状 | 対策 |
|--------|------|------|
| **stale TCP接続** | プロセスは生存、メッセージ受信なし | タイムアウト明示設定 + ウォッチドッグ |
| **IPv6タイムアウト** | 断続的な接続失敗 | IPv4強制（socket.getaddrinfo パッチ） |
| **OOM kill** | プロセス突然消失 | メモリ制限 + systemd restart |
| **未捕捉例外** | プロセスクラッシュ | グローバルエラーハンドラ + systemd restart |
| **コネクションプール枯渇** | 新規リクエスト不可 | pool_timeout + connection_pool_size |
| **Telegram API一時障害** | 5xx エラー | エクスポネンシャルバックオフリトライ |
| **webhook URL変更** | n8n再起動後にメッセージ不達 | cron でwebhook状態監視・再登録 |
| **複数インスタンス競合** | 409 Conflict | デプロイ前に旧プロセスkill確認 |
| **SSL証明書失効** | webhook delivery失敗 | certbot auto-renew + post-hook |

### 6.2 システムレベルの安定化

**ファイル**: `/etc/sysctl.d/99-telegram-bot.conf`

```ini
# TCP keepalive: デフォルト7200秒 → 60秒
# stale接続を早期検知するため
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6

# IPv4優先（IPv6フォールバック遅延防止）
# 完全無効化する場合は net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.all.prefer_ipv4 = 1
```

```bash
# 適用
sudo sysctl -p /etc/sysctl.d/99-telegram-bot.conf
```

---

## 7. 監視と自動復旧

### 7.1 systemd サービスユニット

**ファイル**: `/etc/systemd/system/openclaw-bot.service`

```ini
[Unit]
Description=OpenClaw Telegram Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/sushihey
ExecStart=/root/sushihey/venv/bin/python bot.py
Restart=always
RestartSec=5
StartLimitIntervalSec=300
StartLimitBurst=10

# 環境変数
EnvironmentFile=/root/sushihey/.env

# メモリ制限（OOM時にsystemdが管理下で再起動）
MemoryMax=512M

# ウォッチドッグ（90秒以内にsd_notify必要）
WatchdogSec=90

# ログ
StandardOutput=journal
StandardError=journal
SyslogIdentifier=openclaw-bot

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw-bot
sudo systemctl start openclaw-bot
sudo systemctl status openclaw-bot
```

### 7.2 アプリケーション内ウォッチドッグ

**ファイル**: `/root/sushihey/watchdog.py`

```python
"""
Telegram Bot ウォッチドッグ
- 最終メッセージ受信時刻を監視
- 閾値（300秒）を超えたらgetMeでヘルスチェック
- ヘルスチェック失敗ならプロセスを終了 → systemdが再起動
"""
import asyncio
import time
import logging
import signal
import os
from telegram import Bot

logger = logging.getLogger(__name__)

class TelegramWatchdog:
    def __init__(self, bot: Bot, timeout_seconds: int = 300):
        self.bot = bot
        self.timeout = timeout_seconds
        self.last_activity = time.time()
        self._running = False

    def heartbeat(self):
        """メッセージ受信時に呼ぶ"""
        self.last_activity = time.time()

    async def _health_check(self) -> bool:
        """Telegram APIへの疎通確認"""
        try:
            me = await self.bot.get_me()
            return me is not None
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False

    async def run(self):
        """ウォッチドッグループ"""
        self._running = True
        logger.info(f"Watchdog started (timeout={self.timeout}s)")

        while self._running:
            await asyncio.sleep(30)  # 30秒ごとにチェック

            elapsed = time.time() - self.last_activity
            if elapsed < self.timeout:
                continue

            logger.warning(f"No activity for {elapsed:.0f}s (threshold: {self.timeout}s)")

            # ヘルスチェック実行
            if await self._health_check():
                logger.info("Health check passed. Bot is alive but idle.")
                self.last_activity = time.time()  # リセット
            else:
                logger.error("Health check FAILED. Terminating for restart.")
                # systemd WatchdogSec と連携: プロセス終了 → systemdが再起動
                os.kill(os.getpid(), signal.SIGTERM)
                break

    def stop(self):
        self._running = False
```

**bot.py への統合:**

```python
# bot.py に追加
from watchdog import TelegramWatchdog

# Application構築後
watchdog = TelegramWatchdog(app.bot, timeout_seconds=300)

# 全メッセージハンドラの先頭で呼ぶ
async def handle_message(update, context):
    watchdog.heartbeat()  # ← これを追加
    # ... 既存の処理 ...

# 起動時にウォッチドッグを開始
async def post_init(application):
    asyncio.create_task(watchdog.run())

app.post_init = post_init
```

### 7.3 外部ヘルスチェック（cron）

**ファイル**: `/root/sushihey/scripts/health-check.sh`

```bash
#!/bin/bash
# Telegram Bot 外部ヘルスチェック
# cron: */5 * * * * /root/sushihey/scripts/health-check.sh >> /var/log/telegram-health.log 2>&1

set -euo pipefail

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-YOUR_BOT_TOKEN}"
ADMIN_CHAT_ID="YOUR_ADMIN_CHAT_ID"  # 管理者のTelegram chat ID
SERVICE_NAME="openclaw-bot"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# 1. Telegram API疎通チェック
API_OK=$(curl -sf -o /dev/null -w "%{http_code}" \
    --connect-timeout 10 \
    --max-time 15 \
    -4 \
    "https://api.telegram.org/bot${BOT_TOKEN}/getMe" 2>/dev/null || echo "000")

if [ "$API_OK" != "200" ]; then
    echo "${LOG_PREFIX} CRITICAL: Telegram API unreachable (HTTP ${API_OK})"
    # systemdサービスを再起動
    sudo systemctl restart "$SERVICE_NAME"
    echo "${LOG_PREFIX} Service restarted"
    exit 1
fi

# 2. プロセス生存チェック
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "${LOG_PREFIX} CRITICAL: Service ${SERVICE_NAME} is not running"
    sudo systemctl start "$SERVICE_NAME"
    echo "${LOG_PREFIX} Service started"

    # 管理者にアラート送信
    curl -sf "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${ADMIN_CHAT_ID}" \
        -d "text=[ALERT] OpenClaw bot was down and has been restarted at $(date)" \
        > /dev/null 2>&1 || true
    exit 1
fi

# 3. Webhook状態チェック（webhookモードの場合）
WEBHOOK_INFO=$(curl -sf "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" 2>/dev/null || echo '{}')
PENDING=$(echo "$WEBHOOK_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('pending_update_count',0))" 2>/dev/null || echo "0")

if [ "$PENDING" -gt 50 ]; then
    echo "${LOG_PREFIX} WARNING: ${PENDING} pending updates. Possible hang."
    sudo systemctl restart "$SERVICE_NAME"

    curl -sf "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${ADMIN_CHAT_ID}" \
        -d "text=[ALERT] OpenClaw bot restarted due to ${PENDING} pending updates" \
        > /dev/null 2>&1 || true
fi

echo "${LOG_PREFIX} OK: API=${API_OK} PENDING=${PENDING}"
```

```bash
# cron 登録
chmod +x /root/sushihey/scripts/health-check.sh
crontab -e
# 追加: */5 * * * * /root/sushihey/scripts/health-check.sh >> /var/log/telegram-health.log 2>&1
```

### 7.4 channel probe（能動的な死活監視）

**ファイル**: `/root/sushihey/scripts/probe-bot.py`

```python
"""
Channel Probe: ボットに実際にメッセージを送り、応答を確認する
cron: 0 */1 * * * /root/sushihey/venv/bin/python /root/sushihey/scripts/probe-bot.py

注意: 別のbot（probe用）からOpenClawにメッセージを送る方式。
または管理者アカウントから直接 /health コマンドを送る方式。
"""
import asyncio
import time
import os
import subprocess
from telegram import Bot

PROBE_BOT_TOKEN = os.environ.get("PROBE_BOT_TOKEN", "")  # 別のbot
TARGET_CHAT_ID = os.environ.get("PROBE_CHAT_ID", "")       # テスト用チャット
ADMIN_CHAT_ID = os.environ.get("ADMIN_CHAT_ID", "")
MAIN_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
TIMEOUT_SECONDS = 60

async def probe():
    bot = Bot(token=MAIN_BOT_TOKEN)

    # getMe で基本的な疎通確認
    try:
        me = await bot.get_me()
        print(f"[OK] Bot is alive: @{me.username}")
    except Exception as e:
        print(f"[FAIL] Bot unreachable: {e}")
        # サービス再起動
        subprocess.run(["sudo", "systemctl", "restart", "openclaw-bot"], check=True)

        # アラート
        alert_bot = Bot(token=PROBE_BOT_TOKEN or MAIN_BOT_TOKEN)
        await alert_bot.send_message(
            chat_id=ADMIN_CHAT_ID,
            text=f"[PROBE ALERT] OpenClaw bot failed health check. Restarted.\nError: {e}"
        )

if __name__ == "__main__":
    asyncio.run(probe())
```

---

## 8. 手元確認手順（デプロイ後のチェックリスト）

### 8.1 即時確認

```bash
# 1. サービス状態
sudo systemctl status openclaw-bot

# 2. ログ確認（最新20行）
journalctl -u openclaw-bot -n 20 --no-pager

# 3. Telegram API疎通（IPv4）
curl -4 -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | python3 -m json.tool

# 4. Webhook状態
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" | python3 -m json.tool

# 5. TCP接続状態
ss -tnp | grep "149.154"

# 6. IPv6テスト（タイムアウトすることを確認 = IPv4強制が正しい判断）
timeout 5 curl -6 -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe" || echo "IPv6 timeout confirmed"
```

### 8.2 安定性テスト（6時間後）

```bash
# 1. プロセスのuptime確認
ps -p $(pgrep -f "bot.py") -o etime=

# 2. 過去6時間のログでエラーを検索
journalctl -u openclaw-bot --since "6 hours ago" | grep -i "error\|warning\|restart\|timeout" | tail -20

# 3. ヘルスチェックログ
tail -20 /var/log/telegram-health.log

# 4. webhook チェックログ
tail -20 /var/log/telegram-webhook-check.log

# 5. メモリ使用量の推移
journalctl -u openclaw-bot --since "6 hours ago" | grep -i "memory" || echo "No memory issues"
ps -p $(pgrep -f "bot.py") -o rss=  # KB単位
```

### 8.3 継続監視ダッシュボード（簡易）

```bash
# リアルタイム監視（watch コマンド）
watch -n 10 'echo "=== Service ===" && systemctl is-active openclaw-bot && echo "=== Uptime ===" && ps -p $(pgrep -f "bot.py" 2>/dev/null || echo 1) -o etime= 2>/dev/null && echo "=== Memory ===" && ps -p $(pgrep -f "bot.py" 2>/dev/null || echo 1) -o rss= 2>/dev/null && echo "=== TCP ===" && ss -tnp | grep -c "149.154" && echo "=== Webhook ===" && curl -sf "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo" 2>/dev/null | python3 -c "import sys,json; r=json.load(sys.stdin).get(\"result\",{}); print(f\"pending={r.get(\"pending_update_count\",0)} last_err={r.get(\"last_error_message\",\"none\")}\")" 2>/dev/null'
```

---

## 9. 変更ファイル一覧

| ファイル | 操作 | 内容 |
|---------|------|------|
| `/root/sushihey/bot.py` | **修正** | IPv4強制、タイムアウト明示、エラーハンドラ、ウォッチドッグ統合 |
| `/root/sushihey/watchdog.py` | **新規** | アプリケーション内ウォッチドッグ |
| `/root/sushihey/scripts/health-check.sh` | **新規** | 外部ヘルスチェック（cron 5分間隔） |
| `/root/sushihey/scripts/check-webhook.sh` | **新規** | Webhook状態監視・再登録（cron 30分間隔） |
| `/root/sushihey/scripts/probe-bot.py` | **新規** | 能動的死活監視 |
| `/etc/systemd/system/openclaw-bot.service` | **新規** | systemd サービスユニット |
| `/etc/sysctl.d/99-telegram-bot.conf` | **新規** | TCP keepalive + IPv4優先 |
| `/root/sushihey/docker-compose.yml` | **修正** | NODE_OPTIONS追加、ヘルスチェック追加（n8n使用時） |
| `/etc/nginx/sites-available/telegram-webhook` | **新規** | Webhook用リバプロ（webhook移行時のみ） |

### auth担当とのファイル競合回避

| このドキュメントの変更対象 | auth担当の想定変更対象 | 競合 |
|---|---|---|
| bot.py（接続/タイムアウト部分） | bot.py（認証/トークン管理部分） | **要調整**: bot.py の変更箇所が異なるため、git merge可能。ただし同時編集は避ける |
| watchdog.py（新規） | — | なし |
| scripts/*（新規） | — | なし |
| systemd service（新規） | — | なし |
| docker-compose.yml（env追加） | docker-compose.yml（env追加の可能性） | **要調整**: 同じファイルに別のenv追加。事前に連携 |

---

## 10. まとめ: 推奨実施順序

```
Phase 1: 即時対応（ダウンタイムなし）
├── [1] IPv4強制（bot.py に socket パッチ追加）
├── [2] タイムアウト明示設定（bot.py の HTTPXRequest 設定）
├── [3] エラーハンドラ追加（bot.py）
└── [4] TCP keepalive 短縮（sysctl.conf）

Phase 2: プロセス管理（短時間再起動あり）
├── [5] systemd サービスユニット作成・有効化
└── [6] 既存の起動方法から systemd に切り替え

Phase 3: 監視と復旧
├── [7] ウォッチドッグ統合（watchdog.py + bot.py 修正）
├── [8] 外部ヘルスチェック cron 設定
└── [9] webhook 状態監視 cron 設定

Phase 4: webhook 移行（オプション、最も安定）
├── [10] bot.py を run_polling → run_webhook に変更
├── [11] Nginx リバプロ設定
└── [12] Telegram API に webhook 登録
```

**Phase 1 だけで 5-6時間落ちの大半が解消する見込みです。** Phase 2-3 で「落ちても自動復旧」を保証し、Phase 4 で根本的にポーリングの脆弱性を排除します。
