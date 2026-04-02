#!/usr/bin/env bash
# ================================================================
# OpenClaw Auth Health Check
# ================================================================
# Checks:
#   1. Anthropic API key is valid (lightweight /v1/messages call)
#   2. Telegram webhook is registered and reachable
#   3. n8n is responding
#   4. OpenClaw gateway is alive
#
# Usage:
#   ./healthcheck.sh           # Run all checks
#   ./healthcheck.sh --cron    # Run + auto-fix (for crontab)
#
# Crontab entry (every 30 minutes):
#   */30 * * * * /root/openclaw-infra/healthcheck.sh --cron >> /var/log/openclaw-health.log 2>&1
# ================================================================

set -euo pipefail

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

AUTOFIX=false
[[ "${1:-}" == "--cron" ]] && AUTOFIX=true

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
FAILED=0

log() { echo "[$TIMESTAMP] $1"; }
pass() { log "OK: $1"; }
fail() { log "FAIL: $1"; FAILED=1; }

# ────────────────────────────────────────────
# 1. Anthropic API Key Validation
# ────────────────────────────────────────────
check_anthropic() {
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        fail "ANTHROPIC_API_KEY is not set"
        return
    fi

    # Minimal API call: send an empty-ish request to trigger a known error
    # A valid key returns 400 (bad request); an invalid key returns 401
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
        -X POST https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' \
        --connect-timeout 10 \
        --max-time 15 \
    )

    case "$HTTP_CODE" in
        200) pass "Anthropic API key valid (200)" ;;
        400) pass "Anthropic API key valid (400 = expected for minimal request)" ;;
        401) fail "Anthropic API key INVALID or REVOKED (401)" ;;
        403) fail "Anthropic API key FORBIDDEN — check billing (403)" ;;
        429) pass "Anthropic API key valid but RATE LIMITED (429) — reduce load" ;;
        529) fail "Anthropic API OVERLOADED (529) — transient, retry later" ;;
        000) fail "Anthropic API UNREACHABLE — network issue" ;;
        *)   fail "Anthropic API unexpected status: $HTTP_CODE" ;;
    esac
}

# ────────────────────────────────────────────
# 2. Telegram Webhook Check
# ────────────────────────────────────────────
check_telegram() {
    if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
        fail "TELEGRAM_BOT_TOKEN is not set"
        return
    fi

    WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo" --connect-timeout 10)

    # Check if webhook URL is set
    WEBHOOK_URL_SET=$(echo "$WEBHOOK_INFO" | grep -o '"url":"[^"]*"' | head -1)
    if [[ -z "$WEBHOOK_URL_SET" ]] || echo "$WEBHOOK_URL_SET" | grep -q '"url":""'; then
        fail "Telegram webhook URL is EMPTY"
        if $AUTOFIX; then
            log "AUTO-FIX: Re-registering Telegram webhook..."
            fix_telegram_webhook
        fi
        return
    fi

    # Check for errors
    LAST_ERROR=$(echo "$WEBHOOK_INFO" | grep -o '"last_error_message":"[^"]*"' | head -1 || true)
    PENDING=$(echo "$WEBHOOK_INFO" | grep -o '"pending_update_count":[0-9]*' | grep -o '[0-9]*' || echo "0")

    if [[ -n "$LAST_ERROR" ]]; then
        fail "Telegram webhook error: $LAST_ERROR (pending: $PENDING)"
        if $AUTOFIX && [[ "$PENDING" -gt 50 ]]; then
            log "AUTO-FIX: Re-registering webhook due to high pending count..."
            fix_telegram_webhook
        fi
    else
        pass "Telegram webhook active (pending: $PENDING)"
    fi
}

fix_telegram_webhook() {
    if [[ -z "${N8N_HOST:-}" ]]; then
        fail "Cannot auto-fix: N8N_HOST not set"
        return
    fi

    # Get the webhook path from n8n (assumes standard Telegram Trigger path)
    # You may need to adjust this path to match your actual n8n workflow webhook
    WEBHOOK_PATH="${TELEGRAM_WEBHOOK_PATH:-/webhook/telegram}"
    FULL_URL="https://${N8N_HOST}${WEBHOOK_PATH}"

    RESULT=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook?url=${FULL_URL}" --connect-timeout 10)

    if echo "$RESULT" | grep -q '"ok":true'; then
        log "AUTO-FIX: Webhook re-registered to $FULL_URL"
    else
        fail "AUTO-FIX FAILED: $RESULT"
    fi
}

# ────────────────────────────────────────────
# 3. n8n Health
# ────────────────────────────────────────────
check_n8n() {
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
        "http://localhost:5678/healthz" \
        --connect-timeout 5 \
        --max-time 10 \
    )

    if [[ "$HTTP_CODE" == "200" ]]; then
        pass "n8n is healthy (200)"
    else
        fail "n8n is DOWN (HTTP $HTTP_CODE)"
        if $AUTOFIX; then
            log "AUTO-FIX: Restarting n8n container..."
            docker restart openclaw-n8n 2>/dev/null || fail "AUTO-FIX: docker restart failed"
        fi
    fi
}

# ────────────────────────────────────────────
# 4. OpenClaw Gateway
# ────────────────────────────────────────────
check_openclaw() {
    if ! docker ps --format '{{.Names}}' | grep -q 'openclaw-gateway'; then
        fail "OpenClaw gateway container is NOT running"
        if $AUTOFIX; then
            log "AUTO-FIX: Starting openclaw-gateway..."
            cd "$SCRIPT_DIR" && docker compose up -d openclaw 2>/dev/null || fail "AUTO-FIX: docker compose up failed"
        fi
        return
    fi

    # Check if the gateway reports healthy auth
    AUTH_STATUS=$(docker exec openclaw-gateway openclaw status --all 2>&1 || echo "EXEC_FAILED")
    if echo "$AUTH_STATUS" | grep -qi 'anthropic.*ok\|anthropic.*active'; then
        pass "OpenClaw gateway auth is active"
    elif echo "$AUTH_STATUS" | grep -qi 'EXEC_FAILED'; then
        fail "Cannot exec into openclaw-gateway container"
    else
        fail "OpenClaw gateway auth issue: $(echo "$AUTH_STATUS" | head -3)"
        if $AUTOFIX; then
            log "AUTO-FIX: Restarting openclaw-gateway..."
            docker restart openclaw-gateway 2>/dev/null || true
        fi
    fi
}

# ────────────────────────────────────────────
# 5. Memory Check
# ────────────────────────────────────────────
check_memory() {
    # Check n8n container memory usage
    MEM_USAGE=$(docker stats --no-stream --format '{{.MemPerc}}' openclaw-n8n 2>/dev/null | tr -d '%' || echo "0")
    MEM_INT=${MEM_USAGE%.*}

    if [[ "$MEM_INT" -gt 85 ]]; then
        fail "n8n memory usage HIGH: ${MEM_USAGE}% — OOM risk"
        if $AUTOFIX; then
            log "AUTO-FIX: Restarting n8n to free memory..."
            docker restart openclaw-n8n 2>/dev/null || true
        fi
    elif [[ "$MEM_INT" -gt 70 ]]; then
        log "WARN: n8n memory usage elevated: ${MEM_USAGE}%"
    else
        pass "n8n memory usage OK: ${MEM_USAGE}%"
    fi
}

# ────────────────────────────────────────────
# Run all checks
# ────────────────────────────────────────────
log "=== OpenClaw Health Check Start ==="
check_anthropic
check_telegram
check_n8n
check_openclaw
check_memory
log "=== OpenClaw Health Check End (failures: $FAILED) ==="

exit $FAILED
