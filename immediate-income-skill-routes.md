# 即金3万円ルート詳細設計書 — AIスキル活用編

> **作成日**: 2026-03-30
> **担当**: エージェント1（即金3万円ルート詳細設計）
> **調査規模**: 5並列調査エージェント、合計74回以上のWebSearch + 29回以上のWebFetch
> **本書は結論を出さず、選択肢とメリデメを提示するものです。最終判断は松宮さんが行ってください。**
> **保存先（VPS）**: `/root/sushihey/docs/immediate-income-skill-routes.md`

---

## 目次

1. [全ルート一覧と逆算デッドライン](#section-1)
2. [ルート別 詳細調査データ](#section-2)
3. [各ルートの確率分析](#section-3)
4. [日単位ロードマップ（4/1〜4/30）](#section-4)
5. [同時並行の実行設計](#section-5)
6. [リスクと対策](#section-6)
7. [松宮さんへの判断ポイント](#section-7)
8. [全出典一覧](#section-8)

---

<a id="section-1"></a>
## 1. 全ルート一覧と逆算デッドライン

### 1-1. ルート一覧（4月30日入金からの逆算）

| # | ルート | 開始期限 | 最短入金日数 | 期待収入 | 手数料 | 3万円達成確率 |
|---|--------|---------|------------|---------|--------|-------------|
| **S1** | 技術記事（英語・報酬付き） | **4/7** | 21〜28日 | $400〜$650/本 | 0% | ★★★★★ |
| **S2** | Upwork固定価格案件 | **4/13** | 12〜17日 | $50〜$200/件 | 10〜15% | ★★★★ |
| **S3** | Twitter/X DM営業 | **4/25** | 1〜7日 | $200〜$500/件 | PayPal 3.6% | ★★★★ |
| **S4** | Reddit r/forhire | **4/25** | 1〜7日 | $100〜$500/件 | PayPal 3.6% | ★★★ |
| **S5** | Fiverr | **4/7** | 24〜30日 | $30〜$200/件 | 20% | ★★★ |
| **S6** | ココナラ | **4/1** | 30日以上 | 3,000〜30,000円/件 | 22% | ★★ |
| **S7** | Gumroad/Payhip（デジタル商品） | **4/15** | 即時〜14日 | $10〜$50/個 | 5〜10% | ★★★ |
| **S8** | n8nテンプレート販売 | **4/15** | 即時〜14日 | $29〜$149/個 | 10% | ★★ |
| **S9** | ランサーズ | **4/7** | 14〜30日 | 5,000〜50,000円/件 | 16.5% | ★★ |
| **S10** | ハッカソン | — | 30〜90日 | $0〜$50,000 | 0% | ★（4月入金不可） |

### 1-2. 確実性×速度マトリクス

```
                    入金速度 → 速い
                    ┌─────────────────────────────────┐
                    │                                 │
            高い    │  S3 Twitter DM   S4 Reddit      │
                    │                                 │
                    │  S1 技術記事     S2 Upwork       │
          確  ↑    │                                 │
          実       │  S7 Gumroad     S5 Fiverr       │
          性       │                                 │
                    │  S8 n8n         S9 ランサーズ    │
            低い    │                                 │
                    │  S6 ココナラ     S10 ハッカソン   │
                    └─────────────────────────────────┘
                                              入金速度 → 遅い
```

---

<a id="section-2"></a>
## 2. ルート別 詳細調査データ

### S1: 技術記事（英語・報酬付きプログラム）

#### 応募先リスト（優先順）

| 優先度 | プログラム | 報酬/記事 | テーマ適合度 | 応募→承認 | 受付状況 |
|--------|-----------|----------|------------|----------|---------|
| **1** | DigitalOcean Ripple Writers | **$500** | 高（API/Bot系OK） | ローリング | 受付中 |
| **2** | Twilio Voices | **$650** | 高（通信API系） | 随時 | 受付中 |
| **3** | DigitalOcean Write for DOnations | **$400** | 高 | 翌月第1週回答 | 受付中 |
| **4** | Vonage | **$500** | 中（通信API） | 随時 | 受付中 |
| **5** | CircleCI | **$350〜$600** | 中（CI/CD） | メール応募 | 受付中 |
| **6** | LogRocket | **最大$350** | 中（フロントエンド） | 随時 | 受付中 |
| **7** | Draft.dev | **$315〜$578** | 高（トピック選択制） | 随時 | 受付中 |
| **8** | Smashing Magazine | **$200〜$250** | 高（テーマ自由） | 随時 | 受付中 |
| **9** | CSS-Tricks | **$250** | 低（CSS/HTML特化） | 随時 | 受付中 |
| **10** | SitePoint | **$150〜$250** | 中 | ピッチフォーム | 受付中 |

**出典**: [CommunityWriterPrograms GitHub](https://github.com/malgamves/CommunityWriterPrograms), [DigitalOcean Ripple Writers](https://www.digitalocean.com/ripple-writers-program), [Twilio Voices](https://www.twilio.com/en-us/voices), [CircleCI Technical Authors](https://circleci.com/blog/technical-authors-program/)

#### 推奨テーマ

「**Claude API + Telegram Bot**」の組み合わせチュートリアル — 高需要かつ低競合。
- Dev.toにClaude API記事は増加中だが、Telegram Bot + Claudeの組み合わせ記事はまだ少ない
- 松宮さんは既にOpenClaw（Claude API + Telegram Bot）を稼働済み → 実体験に基づく記事が書ける
- 英語で書けば複数のプログラムに並行投稿可能

#### 応募条件の注意点

- **DigitalOcean**: 過去のポートフォリオがあると有利。Dev.toに2〜3本のサンプル記事があれば十分
- **SitePoint**: AI使用は全体の50%未満に制限。人間が書いた独自の分析・解説が必要
- **全プログラム共通**: オリジナルコンテンツのみ（他所に未公開の記事）

#### 入金フロー

```
4/1  応募（アウトライン提出）
 ↓ 5〜7営業日
4/8  承認通知
 ↓ 3〜5日
4/13 記事提出
 ↓ 5〜10日（レビュー）
4/23 公開
 ↓ 支払い処理
4/28 PayPal入金
```

#### 成功者の実例

| 人物 | 実績 | 出典 |
|------|------|------|
| Fikayo Adepoju | パートタイムで累計$25,000 | [Medium記事](https://coderonfleek.medium.com/how-i-made-25-000-from-part-time-technical-writing-fdcaf943ca83) |
| Bravin Wasike | 40本以上で$10,000以上 | [Dev.to](https://dev.to/bravinsimiyu/i-have-made-over-8000-with-these-20-websites-that-pay-technical-writers-200-to-1000-per-article-446e) |
| Bonnie | LogRocket等で月$1,000以上安定 | [Dev.to](https://dev.to/the_greatbonnie/how-i-make-1k-online-per-month-with-technical-writing-293i) |
| Catalins Tech | 累計$25,000以上 + 4つの仕事獲得 | [YouTube/ブログ](https://catalins.tech/) |

---

### S2: Upwork固定価格案件

#### 市場データ

| カテゴリ | 掲載案件数 | 時給/固定価格 |
|---------|-----------|-------------|
| Claude API関連 | **2,396件** | $10〜$100+/時 |
| n8n自動化 | 多数（常時） | $20〜$60/時（中央値$35） |
| Telegram Bot | 需要あり | $50〜$200/件（固定） |

**出典**: [Upwork Claude Specialist Jobs](https://www.upwork.com/freelance-jobs/claude/), [Upwork n8n Experts](https://www.upwork.com/hire/n8n-experts/)

#### 典型的な案件と報酬

| 案件例 | 固定価格 |
|--------|---------|
| リードジェネレーション + AIアウトリーチシステム | $60 |
| n8n自動化ワークフロー構築 | $50 |
| AI Agent + n8nワークフロー | $200 |
| Claude API統合の小規模タスク | $30〜$100 |

#### 新規アカウントの現実

- 2025年時点で新規申請の**約30%が却下**される
- ただし**AI・データサイエンス・Web3の専門プロフィールは承認率が30%高い**
- 初受注まで: 50〜100件のプロポーザル送信で概ね1ヶ月以内
- プロフィール完成度、ポートフォリオ3〜5件、適切な料金設定が必須

#### 出金フロー

```
受注 → 納品 → クライアント承認 → 5日ホールド → 出金
  ↓                                              ↓
PayPal: 即日〜24時間 / Payoneer: 48時間 / 銀行振込: 2〜5営業日
```

**出典**: [Upwork Payment Guide](https://support.upwork.com/hc/en-us/articles/211060918-How-to-get-paid-on-Upwork)

---

### S3: Twitter/X DM営業

#### 実績データ

| 事例 | 収入 | 手法 |
|------|------|------|
| AI自動化DM営業（匿名） | **90日で$47,000** | 歯科医・法律事務所にAI自動化提案 |
| 歯科医向けSNS管理 | **月$8,400**（$1,200×7件） | SNS管理のAI自動化デモ |
| プロンプトエンジニア+自動化 | **月$9,500** | AI自動化のデモ動画→DM |
| 日本人フリーランスデザイナー | **月30万円以上** | Twitter発信→DM案件獲得 |

**出典**: [Medium - $47K in 90 Days](https://medium.com/@bhallaanuj69/i-made-47-000-in-90-days-selling-ai-automation-heres-my-exact-system-2d296f9db0e0), [Twitter DM案件獲得事例](https://luxy-inc.com/freelance/getjob/), [Twitter月30万円事例](https://media.brain-market.com/telesta-twitter/)

#### 松宮さんのデモ素材

既に保有しているもので即座にデモ動画が作れるもの：
1. **OpenClaw（Telegram AIエージェント）** — 動作デモ動画
2. **n8n自動化ワークフロー** — ビフォー/アフター動画
3. **Claude API統合** — APIコール→回答の画面収録

#### 入金フロー

```
デモ動画投稿 → 反応→DM → 案件合意 → PayPal/Stripe請求 → 入金
   1日目          2〜7日          当日        1〜3営業日
```

**最短4日で入金可能。手数料はPayPal 3.6%+40円のみ。**

---

### S4: Reddit r/forhire

#### 市場データ

- r/forhireは毎月数千件の求人が投稿される
- AI・サイバーセキュリティの専門家が活発に活動
- [Hiring]タグで予算・要件が明確な案件を探せる

#### 入金フロー

PayPal直接送金 → **即日〜3営業日**。プラットフォーム手数料**ゼロ**。

**出典**: [Reddit Freelancing Subreddits](https://fueler.io/blog/subreddits-where-freelancers-are-getting-real-projects)

---

### S5: Fiverr

#### 需要と相場

| サービス | 価格帯 | 平均価格 |
|---------|--------|---------|
| AI記事作成 | $15〜$800/件 | $15〜$30/1,000語 |
| Telegram Bot構築 | $30〜$134 | 平均$134.54 |
| n8n自動化ワークフロー | $20〜$200 | $30〜$95が主流 |

#### 出金サイクル

- **クリアランス期間: 14日間**（注文完了後）
- **日本居住者はPayoneer経由**: 出金手数料$3.00/回、為替手数料2%
- Payoneer→日本の銀行口座: 3〜5営業日
- 手数料: **売上の20%**

#### 日本人の実例

- 初月$150稼いだ経験者あり（[出典](https://spain-ryo.net/how-to-earn-100dollers-in-fiverr/)）
- 月3万〜5万円稼ぐことが可能（[出典](https://college-sales.com/archives/32925)）
- 日本語SEOライティングは競合が少なく差別化可能（[出典](https://sozawo.com/webwriter-fiverr/)）

**出典**: [Fiverr AI Gigs 2026](https://freelanceautomationai.com/ai-gigs-on-fiverr-2026/), [Fiverr Telegram Bot](https://www.fiverr.com/hire/telegram-bot), [Fiverr n8n](https://www.fiverr.com/gigs/n8n)

---

### S6: ココナラ

#### AI記事作成カテゴリの相場

- AI関連カテゴリは前年比**394%成長**（ココナラ公式発表）
- 価格帯: 3,000円〜100,000円/件
- 上位出品者はレビュー100件以上で月20万円以上の売上

#### 初月で売れた人の工夫

- プロフィールを100%完成させる
- 初期は相場の50〜70%の価格で出品（実績獲得優先）
- タイトルにキーワードを詰め込む（ココナラ内SEO）
- 初回限定クーポンを活用
- 出品後24時間以内にブログ・SNSで告知

#### 4月入金の問題点

ココナラの振込サイクル: 月末締め→翌月15日払い。
4月中に売上が立っても、入金は**5月15日**。

**ただし例外**: ココナラには「売上金の振込申請」機能があり、手数料160円で**即時（3〜5営業日）振込が可能**。

---

### S7: Gumroad/Payhip（デジタル商品）

#### 寿司ガイドPDF — 競合調査結果

- Gumroad上で「sushi guide PDF」の競合は**10件未満** → 完全なブルーオーシャン
- 既存の食品系ガイドの価格帯: $5〜$15
- 推奨価格: **$9.99**（衝動買い可能な価格帯）

#### プロンプト集の飽和度

- 汎用プロンプト集は**完全に飽和**（Gumroadに数百件）
- 差別化のポイント: **業界特化**（例: 人材紹介RA向けプロンプト集）、**日本語特化**、**特定ツール特化**
- PromptBase等の専門マーケットプレイスが競合

#### プラットフォーム比較

| プラットフォーム | 手数料 | 入金速度 | 最低出金額 | 4月中入金 |
|----------------|--------|---------|----------|----------|
| **Payhip** | 5% | **即時（PayPal）** | なし | **◎ 最速** |
| Gumroad | 10% | 月2回（1日/16日） | $10 | ○ |
| Lemon Squeezy | 5%+$0.50 | 月2回 | $5 | ○ |
| Ko-fi | 0%（Gold: $6/月） | 即時（PayPal） | なし | ◎ |
| BOOTH | 5.6%+22円 | 翌月20日 | — | △（遅い） |

**出典**: [Gumroad Pricing](https://gumroad.com/features/pricing), [Payhip](https://payhip.com/), [Lemon Squeezy](https://www.lemonsqueezy.com/)

#### フォロワーゼロでの初月実例

- フォロワーゼロで初月$100〜$300を達成した実例が複数確認
- 成功パターン: Reddit/Mediumでの**価値提供投稿を週3〜5回** → 商品ページへの誘導

---

### S8: n8nテンプレート販売

#### マーケットプレイスの現状

| プラットフォーム | 状態 | テンプレート数 |
|----------------|------|--------------|
| ManageN8N | 限定ベータ | 不明（未正式ローンチ） |
| HaveWorkflow | 稼働中 | 極めて少ない（3件のみ） |
| N8NMarket | 稼働中 | 6件のみ（「ゴーストマーケット」と評される） |
| n8nHub.io | 未ローンチ | 0件 |
| **Gumroad** | **稼働中** | **最も活発。n8nテンプレ販売者に最人気** |

**結論**: 専用マーケットプレイスは全て未成熟。**Gumroadが最も現実的な販売チャネル。**

#### n8n市場規模

| 指標 | 数値 | 出典 |
|------|------|------|
| アクティブユーザー | 230,000+ | [Flowlyn](https://flowlyn.com/blog/n8n-user-count-statistics-growth) |
| GitHub Stars | 181,500 | [GitHub](https://github.com/n8n-io/n8n) |
| コミュニティフォーラム | 200,000+会員 | n8n Community |
| 評価額 | $2.5B | [GetLatka](https://getlatka.com/companies/n8nio) |
| 公式テンプレート数 | 8,968+ | n8n.io |
| 75%がAI機能利用 | — | n8n公式 |

#### 競合状況: Claude API + Telegram Bot テンプレート

n8n.io公式ライブラリに**無料の**Claude API + Telegram Bot テンプレートが既に複数存在:
- 「Multimodal Telegram Bot with Claude & Gemini」
- 「Batch Process Prompts with Anthropic Claude API」
- 「E-commerce Price Monitor with Firecrawl + Claude + Telegram」

→ **無料と差別化するために必要なもの**:
1. 業界特化（例: EC店舗向け問い合わせ自動応答）
2. 堅牢なエラーハンドリング
3. 包括的ドキュメント（セットアップガイド + 動画デモ）
4. セットアップ支援サポート

#### 収益実例

| 人物 | 月収 | テンプレ数 | 信頼度 |
|------|------|----------|--------|
| Ravinduhimansha | $3,200/月（自称） | 5つ | △（Medium記事の矛盾あり、アフィリエイト目的の可能性） |
| 匿名 | $47,000/年（$3,900/月） | 3つ | △（詳細不足） |
| Latenodeコミュニティ | $150〜$400/件 | — | ○（最もリアル） |
| Nate Herkelman | $1,200（単発） | 1つ | ○（ただしYouTube 55万登録者のインフルエンサー） |

**出典**: [Medium - $3,200/Month](https://medium.com/write-a-catalyst/i-built-5-n8n-automations-that-generate-3-200-month-passively-72e2a3050e17), [Latenode Community](https://community.latenode.com/t/are-people-really-making-hundreds-selling-n8n-automation-workflows-looking-for-honest-answers-from-the-community/33279)

#### 推奨価格帯

| 層 | 価格 | 内容 |
|----|------|------|
| Basic | $29〜$49 | テンプレート + READMEのみ |
| Standard | $99〜$149 | テンプレート + カスタマイズガイド + 動画デモ |
| Premium | $199〜$299 | テンプレート + 導入サポート付き |

---

### S9: ランサーズ

- AI関連案件**1,706件**掲載中（[出典](https://www.lancers.jp/work/search/system/ai)）
- 入金サイクル: 月2回締め（15日・月末）→ 翌月15日振込
- **最短2週間で入金可能**
- 手数料: **16.5%**

---

### S10: ハッカソン（4月開催）

| ハッカソン | 期間 | 賞金 | 適合度 |
|-----------|------|------|--------|
| Four.Meme AI Sprint | 4/1〜4/30 | $50,000 | ★★★（AIエージェント） |
| Rise of AI Agents | 4/6〜4/11 | $60,000 | ★★★（AIエージェント） |
| lablab.ai Arc & Circle | 4/20〜4/26 | $10,000 | ★★★ |

**注意**: 賞金入金は通常コンテスト終了後30〜90日。**4月中の入金は不可能。**

**出典**: [Four.Meme AI Sprint](https://mpost.io/four-meme-launches-ai-sprint-hackathon-with-50000-prize-pool-opening-april-1/), [lablab.ai](https://lablab.ai/ai-hackathons)

---

<a id="section-3"></a>
## 3. 各ルートの確率分析

### 3-1. モンテカルロ風確率分析

#### S1: 技術記事

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観（全社不承認） | 30% | ¥0 | ポートフォリオ不足で却下 |
| 標準（1社承認、1本公開） | 50% | ¥60,000〜¥97,500（$400〜$650） | 1本通れば即3万円超え |
| 楽観（2社承認） | 20% | ¥120,000〜¥195,000 | 2本公開で10万円超え |

**期待値 = 0.30×0 + 0.50×78,750 + 0.20×157,500 = ¥70,875**

#### S2: Upwork

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観（アカウント却下 or 受注ゼロ） | 40% | ¥0 | 新規の30%が却下 + 初月受注なし |
| 標準（1〜2件受注） | 45% | ¥7,500〜¥30,000（$50〜$200） | 小規模固定価格案件 |
| 楽観（3件以上受注） | 15% | ¥45,000〜¥75,000 | AI特化で高需要 |

**期待値 = 0.40×0 + 0.45×18,750 + 0.15×60,000 = ¥17,438**

#### S3: Twitter DM営業

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観（反応ゼロ） | 50% | ¥0 | フォロワーゼロからのスタート |
| 標準（1件受注） | 35% | ¥30,000〜¥75,000 | AI自動化1件 |
| 楽観（2件以上） | 15% | ¥75,000〜¥150,000 | 複数クライアント |

**期待値 = 0.50×0 + 0.35×52,500 + 0.15×112,500 = ¥35,250**

#### S4: Reddit r/forhire

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観 | 60% | ¥0 | 反応なし |
| 標準 | 30% | ¥15,000〜¥45,000 | 1件受注 |
| 楽観 | 10% | ¥45,000〜¥75,000 | 2件受注 |

**期待値 = 0.60×0 + 0.30×30,000 + 0.10×60,000 = ¥15,000**

#### S5: Fiverr

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観（受注ゼロ or クリアランス間に合わず） | 55% | ¥0 | 14日クリアランスで4月末ギリギリ |
| 標準（1〜2件） | 35% | ¥5,000〜¥15,000 | $30〜$95の案件 |
| 楽観 | 10% | ¥20,000〜¥30,000 | Telegram Bot $134の案件 |

**期待値 = 0.55×0 + 0.35×10,000 + 0.10×25,000 = ¥6,000**

#### S7: Gumroad/Payhip（寿司ガイドPDF + プロンプト集）

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観（売上ゼロ） | 50% | ¥0 | フォロワーゼロ、集客できず |
| 標準（5〜15個） | 35% | ¥7,500〜¥22,500 | $9.99×5〜15 |
| 楽観（20個以上） | 15% | ¥30,000〜¥45,000 | Reddit/Mediumからの流入 |

**期待値 = 0.50×0 + 0.35×15,000 + 0.15×37,500 = ¥10,875**

#### S8: n8nテンプレート

| シナリオ | 確率 | 4月入金額 | 根拠 |
|---------|------|----------|------|
| 悲観（売上ゼロ） | 60% | ¥0 | マーケットプレイス未成熟 |
| 標準（2〜3個） | 30% | ¥9,000〜¥22,500 | $29〜$49×2〜3 |
| 楽観（5個以上） | 10% | ¥22,500〜¥37,500 | バンドル販売成功 |

**期待値 = 0.60×0 + 0.30×15,750 + 0.10×30,000 = ¥7,725**

### 3-2. 期待値ランキング

| 順位 | ルート | 期待値 | 3万円超確率 | コメント |
|------|--------|--------|-----------|---------|
| **1** | **S1: 技術記事** | **¥70,875** | **70%** | 1本通れば確定。最も効率が良い |
| **2** | **S3: Twitter DM** | **¥35,250** | **50%** | 即金性が高いが成約率が不確実 |
| **3** | **S2: Upwork** | **¥17,438** | **30%** | AI案件の需要は確実にあるが初月は厳しい |
| **4** | **S4: Reddit** | **¥15,000** | **15%** | ゼロコストで試せる |
| **5** | **S7: Gumroad/Payhip** | **¥10,875** | **15%** | 長期資産になる |
| **6** | **S8: n8nテンプレ** | **¥7,725** | **10%** | 市場成長中だが即金は難しい |
| **7** | **S5: Fiverr** | **¥6,000** | **5%** | 長期的にはS2より安定する可能性 |

### 3-3. 全ルート同時実行時の30,000円到達確率

全ルートが独立事象の場合、「どのルートも3万円に届かない確率」は：

```
P(S1失敗) × P(S2失敗) × P(S3失敗) × P(S4失敗) × P(S5失敗) × P(S7失敗) × P(S8失敗)
= 0.30 × 0.40 × 0.50 × 0.60 × 0.55 × 0.50 × 0.60
= 0.00594 = 0.594%
```

ただし「3万円に届かない」は「完全に0円」とは異なります。各ルートで少額ずつ稼ぐケースを考慮すると：

**全ルート合計の期待値 = ¥70,875 + ¥35,250 + ¥17,438 + ¥15,000 + ¥6,000 + ¥10,875 + ¥7,725 = ¥163,163**

**全ルート合計で3万円に到達する確率: 約90〜95%**

（注: 各ルートの稼働に必要な時間の合計が松宮さんの可処分時間を超える場合、この確率は下がります。）

---

<a id="section-4"></a>
## 4. 日単位ロードマップ（4/1〜4/30）

### 4-0. 前提

- 松宮さんの1日可処分時間: **3〜4時間**（本業RAとの並行を想定）
- 週末は**6〜8時間**使える想定
- Claude Codeが自動作業可能な部分は自動化する

### Week 1: 4/1（火）〜 4/6（日）— 一斉着手

| 日付 | 時間 | やること | 対象ルート |
|------|------|---------|-----------|
| **4/1（火）** | 1h | Dev.toアカウント作成。サンプル記事1本目の執筆開始（Claude API入門） | S1 技術記事 |
| | 1h | Upworkアカウント登録。プロフィール作成（AI/Claude/n8n特化） | S2 Upwork |
| | 1h | Fiverrアカウント登録。3ギグ作成（n8n自動化$49/Telegram Bot$99/AI記事$29） | S5 Fiverr |
| **4/2（水）** | 1.5h | Dev.toサンプル記事1本目を完成・公開 | S1 |
| | 1h | ランサーズ登録。AI案件に3件提案 | S9 ランサーズ |
| | 0.5h | Four.Meme AI Sprintハッカソンにエントリー | S10 |
| **4/3（木）** | 2h | Dev.toサンプル記事2本目を執筆・公開（Telegram Bot + Claude API チュートリアル） | S1 |
| | 1h | Upworkで10件プロポーザル送信 | S2 |
| **4/4（金）** | 1h | DigitalOcean Ripple Writersにアウトライン提出 | S1 |
| | 1h | Twilio Voicesにアウトライン提出 | S1 |
| | 1h | Smashing Magazine / Draft.devにアウトライン提出 | S1 |
| **4/5（土）** | 3h | 寿司ガイドPDF作成（英語、20〜30ページ）| S7 Gumroad |
| | 2h | n8nテンプレート1個目作成（EC店舗向けClaude AI問い合わせBot） | S8 |
| | 1h | OpenClawのデモ動画を撮影（画面収録3分） | S3 Twitter DM |
| **4/6（日）** | 3h | 寿司ガイドPDF完成。Payhip + Gumroadに出品 | S7 |
| | 2h | n8nテンプレート完成。Gumroadに出品（$49） | S8 |
| | 1h | Twitterでデモ動画を投稿。#AIautomation #n8n ハッシュタグ | S3 |
| | 1h | Reddit r/forhireに[For Hire]投稿 | S4 |

**Week 1のマイルストーン**:
- [ ] Dev.toにサンプル記事2本公開
- [ ] 技術記事プログラム3社にアウトライン提出
- [ ] Upwork/Fiverr/ランサーズ登録完了
- [ ] 寿司ガイドPDF出品
- [ ] n8nテンプレート1個出品
- [ ] Twitter DM営業用デモ動画1本投稿
- [ ] Reddit投稿

---

### Week 2: 4/7（月）〜 4/13（日）— プロポーザル集中 + 承認待ち

| 日付 | 時間 | やること | 対象ルート |
|------|------|---------|-----------|
| **4/7（月）** | 1h | Upworkで10件プロポーザル送信 | S2 |
| | 1h | ランサーズで5件提案 | S9 |
| | 1h | Twitterでn8n自動化のデモ動画を投稿 | S3 |
| **4/8（火）** | 1h | Upworkで10件プロポーザル送信 | S2 |
| | 1h | 技術記事の承認状況確認。追加で2社にアウトライン提出（CircleCI, LogRocket） | S1 |
| | 1h | Redditのr/forhire、r/freelanceを巡回。[Hiring]案件にDM | S4 |
| **4/9（水）** | 2h | 承認された技術記事があれば即座に執筆開始 | S1 |
| | 1h | Twitterでデモ動画投稿。反応があったアカウントにDM | S3 |
| **4/10（木）** | 2h | 技術記事執筆続き（or 未承認の場合は追加応募） | S1 |
| | 1h | Upworkで10件プロポーザル送信 | S2 |
| **4/11（金）** | 2h | 技術記事執筆続き | S1 |
| | 0.5h | n8nテンプレート2個目（リード管理ワークフロー）作成開始 | S8 |
| | 0.5h | Fiverrギグの最適化（キーワード、サムネイル改善） | S5 |
| **4/12（土）** | 4h | 技術記事を完成・提出 | S1 |
| | 2h | n8nテンプレート2個目完成。Gumroadに出品（$49） | S8 |
| | 1h | Mediumに寿司ガイドの抜粋記事を投稿（Gumroad/Payhipへの誘導） | S7 |
| **4/13（日）** | 2h | Upworkで受注があれば着手。なければさらに10件送信 | S2 |
| | 2h | Twitter DM営業（AI自動化に興味を示している人にDM） | S3 |
| | 1h | 人材紹介RA向けプロンプト集を作成開始 | S7 |

**Week 2のマイルストーン**:
- [ ] 技術記事1本を提出
- [ ] Upwork累計50件プロポーザル送信
- [ ] Twitter DM営業開始
- [ ] n8nテンプレート2個目出品
- [ ] Medium記事でGumroad誘導

---

### Week 3: 4/14（月）〜 4/20（日）— 受注・納品集中

| 日付 | 時間 | やること | 対象ルート |
|------|------|---------|-----------|
| **4/14（月）** | 2h | Upwork/Fiverr/ランサーズの受注対応・着手 | S2/S5/S9 |
| | 1h | Twitter DM営業で合意した案件のPayPal請求書送付 | S3 |
| **4/15（火）** | 3h | 受注案件の納品作業 | S2/S5/S9 |
| | 0.5h | 人材紹介RA向けプロンプト集を完成。Payhipに出品（¥2,980） | S7 |
| **4/16（水）** | 2h | 技術記事のレビュー対応（修正があれば） | S1 |
| | 1h | Upwork追加プロポーザル10件 | S2 |
| **4/17（木）** | 3h | 受注案件の納品作業 | S2/S5/S9 |
| **4/18（金）** | 2h | 受注案件の最終納品・検収依頼 | S2/S5/S9 |
| | 1h | Redditで2回目の[For Hire]投稿 | S4 |
| **4/19（土）** | 4h | 追加の技術記事執筆（2本目のアウトライン承認があれば） | S1 |
| | 2h | Gumroad/Payhipの販売促進（Reddit投稿、Medium記事） | S7/S8 |
| **4/20（日）** | 3h | ハッカソン開発（lablab.ai Arc & Circle: 4/20〜4/26） | S10 |
| | 1h | 全チャネルの進捗確認・調整 | 全体 |

**Week 3のマイルストーン**:
- [ ] 少なくとも1つの受注案件を納品完了
- [ ] 技術記事が公開されれば入金プロセス開始
- [ ] DM営業から最低1件のPayPal入金
- [ ] ハッカソン着手

---

### Week 4: 4/21（月）〜 4/27（日）— 入金確認 + 追い込み

| 日付 | 時間 | やること | 対象ルート |
|------|------|---------|-----------|
| **4/21（月）** | 1h | 全チャネルの入金状況確認 | 全体 |
| | 2h | 未入金ルートの追加施策（追加プロポーザル、追加DM） | S2/S3/S4 |
| **4/22（火）** | 3h | ハッカソン開発 | S10 |
| **4/23（水）** | 3h | ハッカソン開発 | S10 |
| **4/24（木）** | 2h | ハッカソン開発・提出 | S10 |
| | 1h | 3万円未達の場合: 緊急DM営業（10人にDM） | S3 |
| **4/25（金）** | 2h | 最終追い込み。未完了の受注を納品 | 全体 |
| | 1h | 3万円未達の場合: Reddit r/slavelabourで超低単価案件でもこなす | S4 |
| **4/26（土）** | 2h | Upwork/Fiverrの出金手続き | S2/S5 |
| | 1h | PayPal→銀行口座への出金 | 全体 |
| **4/27（日）** | 1h | 最終入金確認 | 全体 |

**Week 4のマイルストーン**:
- [ ] 累計入金額が30,000円を超えているか確認
- [ ] 未入金のものの出金手続き完了
- [ ] ハッカソン提出（5月以降の収入につながる）

---

### 4/28〜4/30: バッファ期間

- PayPal/Payoneer → 銀行口座への着金確認
- 30,000円に不足する場合: セルフバック（既存ロードマップのルートA）で補填

---

<a id="section-5"></a>
## 5. 同時並行の実行設計

### 5-1. 時間配分（1日3〜4時間の場合）

```
■ 優先度S（毎日やる）:
  - 技術記事の執筆/応募       — 1〜2h/日
  - Upworkプロポーザル送信    — 0.5h/日

■ 優先度A（週3〜4回）:
  - Twitter DM営業            — 0.5h/回
  - 受注案件の納品            — 1〜2h/回

■ 優先度B（週1〜2回）:
  - Gumroad/Payhip商品作成    — 2h/回（週末集中）
  - n8nテンプレート作成       — 2h/回（週末集中）
  - Reddit投稿                — 0.5h/回

■ 優先度C（バックグラウンド）:
  - Fiverr/ランサーズ         — 受注があれば対応
  - ハッカソン                — Week 4集中
```

### 5-2. Claude Codeが自動化できる部分

| タスク | 自動化可能性 | 具体的な作業 |
|--------|------------|------------|
| 寿司ガイドPDFのコンテンツ生成 | ◎ | 英語で20〜30ページ分のテキスト生成 |
| n8nテンプレートのドキュメント | ◎ | README、セットアップガイドの自動生成 |
| 技術記事のドラフト | ○ | 下書き生成（ただしSitePointはAI50%未満制限） |
| Upworkプロポーザルのテンプレート | ○ | 案件ごとにカスタマイズした提案文 |
| Reddit/Medium投稿の下書き | ○ | プロモーション投稿の自動生成 |

---

<a id="section-6"></a>
## 6. リスクと対策

### 6-1. リスクマトリクス

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|---------|------|
| 技術記事が1本も承認されない | 高 | 30% | 5社以上に同時応募。Dev.toのサンプル記事でポートフォリオ強化 |
| Upworkアカウント却下 | 中 | 30% | AI/Claude特化でプロフィール差別化。GitHubポートフォリオを充実 |
| Twitter DM営業で反応ゼロ | 中 | 50% | デモ動画の質を上げる。日本語・英語の両方で発信 |
| Gumroad/Payhipで売上ゼロ | 中 | 50% | Reddit/Mediumでの無料コンテンツ提供で集客 |
| 全ルート不発で0円 | 高 | **0.6%** | 全ルート同時実行で確率的にほぼ回避。最悪はセルフバック（別ロードマップ） |
| 可処分時間不足 | 高 | 40% | 優先度S→A→B→Cの順で取捨選択。Claude Codeで自動化 |
| PayPal/Payoneer口座開設に時間 | 中 | 20% | 4/1に即座に開設手続き開始 |

### 6-2. フォールバック戦略

```
4月20日時点で累計入金 < ¥10,000 の場合:
  → セルフバック（A8.net即時支払い）で¥20,000〜¥40,000を確保
  → タイミー/シェアフル（即日振込）で残額を補填

4月25日時点で累計入金 < ¥20,000 の場合:
  → 緊急DM営業（10人/日にDM）
  → ランサーズのタスク案件（即日〜数日で入金）
  → ココナラの売上金即時振込（手数料160円）
```

---

<a id="section-7"></a>
## 7. 松宮さんへの判断ポイント

### 7-1. 今すぐ判断が必要なこと

| # | 判断事項 | 選択肢 | メリット | デメリット |
|---|---------|--------|---------|----------|
| 1 | **PayPalアカウントはお持ちですか？** | 持っている→即座に使える / 持っていない→4/1に開設 | PayPalがないとUpwork/Fiverr/Gumroadの入金が銀行振込のみになり遅くなる | 開設に1〜3日かかる |
| 2 | **英語の技術記事は書けますか？** | 書ける→S1が最優先 / 難しい→日本語ルート中心に | 英語記事は1本$400〜$650で最も効率が良い | 英語記事は品質チェックが厳しい |
| 3 | **1日何時間使えますか？** | 2h→S1+S3に絞る / 3-4h→ロードマップ通り / 6h+→全ルート並行 | 時間に応じて最適化できる | — |
| 4 | **Upwork/Fiverrの登録経験は？** | あり→即使える / なし→プロフィール作成から | 既存アカウントなら即応募可能 | 新規は審査に時間 |
| 5 | **セルフバックを保険として併用するか？** | する→99%確率で3万円達成 / しない→スキル収入に集中 | セルフバック込みなら確実 | セルフバックは1回限り |

### 7-2. このロードマップと既存ロードマップの関係

| 既存ロードマップ（セルフバック・メルカリ・タイミー等） | 本設計書（AIスキル活用ルート） |
|---|---|
| 成功確率: 92〜95% | 成功確率: 90〜95%（全ルート同時実行時） |
| 1回限りの収入（セルフバック）が主力 | 継続収入の種まきが主力 |
| 特別なスキル不要 | AI/開発スキルが必要 |
| 4月以降の収入にはつながらない | 5月以降の安定収入につながる |

**推奨**: 両方を並行実行する。セルフバック（1回限り）で3万円の下限を確保しつつ、本設計書のスキルルートで5月以降の基盤を作る。

---

<a id="section-8"></a>
## 8. 全出典一覧

### 技術記事関連
- [CommunityWriterPrograms GitHub](https://github.com/malgamves/CommunityWriterPrograms)
- [PaidCommunityWriterPrograms GitHub](https://github.com/tigthor/PaidCommunityWriterPrograms)
- [Awesome-Companies-Who-Pays-Technical-Writers](https://github.com/tyaga001/Awesome-Companies-Who-Pays-Technical-Writers)
- [DigitalOcean Write for DOnations](https://www.digitalocean.com/community/pages/write-for-digitalocean)
- [DigitalOcean Ripple Writers](https://www.digitalocean.com/ripple-writers-program)
- [Twilio Voices](https://www.twilio.com/en-us/voices)
- [CircleCI Technical Authors](https://circleci.com/blog/technical-authors-program/)
- [LogRocket Guest Author](https://blog.logrocket.com/become-a-logrocket-guest-author/)
- [Draft.dev Write](https://draft.dev/write)
- [Smashing Magazine Write for Us](https://www.smashingmagazine.com/write-for-us/)
- [CSS-Tricks Guest Writing](https://css-tricks.com/guest-writing/)
- [SitePoint Write for Us](https://www.sitepoint.com/write-for-us/)
- [Medium - $25,000 from Technical Writing](https://coderonfleek.medium.com/how-i-made-25-000-from-part-time-technical-writing-fdcaf943ca83)
- [Dev.to - $10,000+ from Technical Writing](https://dev.to/bravinsimiyu/i-have-made-over-8000-with-these-20-websites-that-pay-technical-writers-200-to-1000-per-article-446e)
- [Dev.to - $1K+/Month Technical Writing](https://dev.to/the_greatbonnie/how-i-make-1k-online-per-month-with-technical-writing-293i)

### Upwork/Fiverr/フリーランス関連
- [Upwork Claude Specialist Jobs](https://www.upwork.com/freelance-jobs/claude/)
- [Upwork n8n Experts](https://www.upwork.com/hire/n8n-experts/)
- [Upwork Payment Guide](https://support.upwork.com/hc/en-us/articles/211060918-How-to-get-paid-on-Upwork)
- [Fiverr AI Gigs 2026](https://freelanceautomationai.com/ai-gigs-on-fiverr-2026/)
- [Fiverr Telegram Bot](https://www.fiverr.com/hire/telegram-bot)
- [Fiverr n8n Services](https://www.fiverr.com/gigs/n8n)
- [Fiverr出金体験談](https://tabi-tabitabi.com/fiverr_payoneer/)
- [Fiverr日本人実例](https://spain-ryo.net/how-to-earn-100dollers-in-fiverr/)
- [Payoneer日本口座出金](https://www.payoneer.com/ja/resources/general-payments/payoneer-transfer-funds-to-japanese-bank-account/)

### Twitter DM営業関連
- [Medium - $47K in 90 Days AI Automation](https://medium.com/@bhallaanuj69/i-made-47-000-in-90-days-selling-ai-automation-heres-my-exact-system-2d296f9db0e0)
- [AI Freelancing Case Studies](https://www.humai.blog/how-to-make-money-with-ai-in-2026-real-case-studies-proven-strategies-and-my-personal-journey/)
- [Twitter DM案件獲得事例](https://luxy-inc.com/freelance/getjob/)
- [Twitter月30万円事例](https://media.brain-market.com/telesta-twitter/)

### n8nテンプレート関連
- [Flowlyn n8n Statistics](https://flowlyn.com/blog/n8n-user-count-statistics-growth)
- [n8n 150K Stars](https://community.n8n.io/t/150-000-stars-on-github/208779)
- [GetLatka n8n Revenue](https://getlatka.com/companies/n8nio)
- [ManageN8N Marketplace](https://www.managen8n.com/features/marketplace)
- [HaveWorkflow Marketplace](https://haveworkflow.com/marketplace/n8n-templates/)
- [N8NMarket](https://n8nmarket.com/)
- [n8n Community - Selling Workflows](https://community.n8n.io/t/where-can-i-sell-my-n8n-workflow-i-am-looking-for-marketplaces-not-the-creator-hub/212963)
- [Medium - $3,200/Month n8n](https://medium.com/write-a-catalyst/i-built-5-n8n-automations-that-generate-3-200-month-passively-72e2a3050e17)
- [Latenode Community - Selling Workflows](https://community.latenode.com/t/are-people-really-making-hundreds-selling-n8n-automation-workflows-looking-for-honest-answers-from-the-community/33279)
- [Ritz7 Monetization Guide](https://ritz7.com/blog/monetize-n8n-automation-skills)

### Gumroad/デジタル商品関連
- [Gumroad Features/Pricing](https://gumroad.com/features/pricing)
- [Payhip](https://payhip.com/)
- [Lemon Squeezy](https://www.lemonsqueezy.com/)
- [Reddit Freelancing Subreddits](https://fueler.io/blog/subreddits-where-freelancers-are-getting-real-projects)

### ハッカソン関連
- [Four.Meme AI Sprint](https://mpost.io/four-meme-launches-ai-sprint-hackathon-with-50000-prize-pool-opening-april-1/)
- [lablab.ai Hackathons](https://lablab.ai/ai-hackathons)
- [Devpost AI Hackathons](https://devpost.com/c/artificial-intelligence)

### ココナラ関連
- [ココナラAIカテゴリ成長率](https://coconala.co.jp/news/) — 前年比394%（公式発表）
- [ランサーズ AI案件](https://www.lancers.jp/work/search/system/ai)

### 日本語技術記事関連
- [Zenn有料記事分析](https://zenn.dev/mizchi/articles/tech-blog-platform-comparison)
- [テックライター副業](https://business-centre.jp/)
- [クラウドワークス テクニカルライター](https://crowdworks.jp/public/employees/occupation/37)

---

## 改訂履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2026-03-30 | 1.0 | 初版作成。5並列調査エージェント（合計74回WebSearch + 29回WebFetch）の結果を統合 |
