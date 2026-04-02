#!/usr/bin/env bash
# ================================================================
# OpenClaw Auth Migration Script
# ================================================================
# Migrates from unstable auth (OAuth / setup-token / CLI login)
# to stable Anthropic API Key authentication.
#
# Run this ON THE VPS:
#   chmod +x migrate-auth.sh
#   ./migrate-auth.sh
# ================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  OpenClaw Auth Migration"
echo "  OAuth/setup-token → Anthropic API Key"
echo "============================================"
echo ""

# ─── Step 1: Check current auth method ───
echo "--- Step 1: Diagnosing current auth method ---"

CURRENT_AUTH="unknown"

# Check for API key in environment
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    if [[ "$ANTHROPIC_API_KEY" == sk-ant-api03-* ]]; then
        log "Found ANTHROPIC_API_KEY in environment (format OK)"
        CURRENT_AUTH="api-key"
    else
        warn "ANTHROPIC_API_KEY set but format unexpected: ${ANTHROPIC_API_KEY:0:15}..."
        CURRENT_AUTH="api-key-suspect"
    fi
fi

# Check for conflicting env vars
for VAR in ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL CLAUDE_API_KEY; do
    if env | grep -q "^${VAR}="; then
        warn "Found conflicting env var: $VAR — this may override API key auth"
    fi
done

# Check OpenClaw config
if command -v openclaw &>/dev/null; then
    OC_STATUS=$(openclaw status --all 2>&1 || echo "")
    if echo "$OC_STATUS" | grep -qi 'setup-token\|subscription'; then
        warn "OpenClaw is using setup-token / subscription auth (UNSTABLE)"
        CURRENT_AUTH="setup-token"
    elif echo "$OC_STATUS" | grep -qi 'api.key\|api-key'; then
        log "OpenClaw reports API key auth"
        CURRENT_AUTH="api-key"
    elif echo "$OC_STATUS" | grep -qi 'cli.backend\|cli-backend'; then
        warn "OpenClaw is using Claude CLI backend auth (UNSTABLE)"
        CURRENT_AUTH="cli-backend"
    fi
    echo ""
    echo "Current openclaw status:"
    echo "$OC_STATUS" | head -20
else
    warn "openclaw command not found — may be running in Docker only"
fi

echo ""
echo "Detected auth method: $CURRENT_AUTH"
echo ""

# ─── Step 2: Validate or request API key ───
echo "--- Step 2: Validate Anthropic API Key ---"

if [[ "$CURRENT_AUTH" == "api-key" ]] && [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    # Validate existing key
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' \
        -X POST https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' \
        --connect-timeout 10 --max-time 15 2>/dev/null)

    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "400" ]]; then
        log "Existing API key is VALID"
    else
        err "Existing API key returned HTTP $HTTP_CODE — may be invalid"
        echo ""
        echo "Please get a new key from: https://console.anthropic.com/settings/keys"
        read -p "Paste new API key (sk-ant-api03-...): " NEW_KEY
        ANTHROPIC_API_KEY="$NEW_KEY"
    fi
else
    echo "No valid API key found."
    echo "Please get one from: https://console.anthropic.com/settings/keys"
    echo ""
    read -p "Paste API key (sk-ant-api03-...): " NEW_KEY
    ANTHROPIC_API_KEY="$NEW_KEY"
fi

# Validate format
if [[ "$ANTHROPIC_API_KEY" != sk-ant-api03-* ]]; then
    err "Key format invalid. Must start with sk-ant-api03-"
    exit 1
fi

echo ""

# ─── Step 3: Clean up conflicting auth ───
echo "--- Step 3: Clean up conflicting auth ---"

# Remove conflicting env vars from shell profiles
for PROFILE in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.profile; do
    if [[ -f "$PROFILE" ]]; then
        for VAR in ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL CLAUDE_API_KEY; do
            if grep -q "export $VAR=" "$PROFILE" 2>/dev/null; then
                warn "Removing 'export $VAR' from $PROFILE"
                sed -i "/export ${VAR}=/d" "$PROFILE"
            fi
        done
    fi
done

# Unset from current session
unset ANTHROPIC_AUTH_TOKEN 2>/dev/null || true
unset ANTHROPIC_BASE_URL 2>/dev/null || true
unset CLAUDE_API_KEY 2>/dev/null || true

log "Conflicting env vars cleaned"

# ─── Step 4: Update .env file ───
echo "--- Step 4: Update .env ---"

ENV_FILE="$SCRIPT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
    # Update existing ANTHROPIC_API_KEY line
    if grep -q '^ANTHROPIC_API_KEY=' "$ENV_FILE"; then
        sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY|" "$ENV_FILE"
        log "Updated ANTHROPIC_API_KEY in $ENV_FILE"
    else
        echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$ENV_FILE"
        log "Added ANTHROPIC_API_KEY to $ENV_FILE"
    fi
else
    warn "$ENV_FILE not found — creating from .env.example"
    if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
        cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
        sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY|" "$ENV_FILE"
        warn "Created $ENV_FILE — please fill in remaining values"
    fi
fi

# ─── Step 5: Update OpenClaw config ───
echo "--- Step 5: Reconfigure OpenClaw ---"

if command -v openclaw &>/dev/null; then
    openclaw onboard --anthropic-api-key "$ANTHROPIC_API_KEY" 2>/dev/null && \
        log "OpenClaw reconfigured with API key" || \
        warn "openclaw onboard failed — will use env var fallback"
fi

# ─── Step 6: Restart services ───
echo "--- Step 6: Restart services ---"

if [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
    cd "$SCRIPT_DIR"
    docker compose down
    docker compose up -d
    log "Docker stack restarted"

    echo ""
    echo "Waiting 15s for services to initialize..."
    sleep 15

    # Run health check
    if [[ -x "$SCRIPT_DIR/healthcheck.sh" ]]; then
        bash "$SCRIPT_DIR/healthcheck.sh"
    fi
else
    warn "No docker-compose.yml found in $SCRIPT_DIR"
fi

# ─── Step 7: Install cron health check ───
echo "--- Step 7: Install health check cron ---"

CRON_LINE="*/30 * * * * $SCRIPT_DIR/healthcheck.sh --cron >> /var/log/openclaw-health.log 2>&1"
if ! crontab -l 2>/dev/null | grep -qF "healthcheck.sh"; then
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    log "Installed health check cron (every 30 min)"
else
    log "Health check cron already installed"
fi

# ─── Done ───
echo ""
echo "============================================"
echo "  Migration Complete"
echo "============================================"
echo ""
echo "Auth method: Anthropic API Key (does NOT expire)"
echo "Health check: every 30 min via cron"
echo "Logs: /var/log/openclaw-health.log"
echo ""
echo "Verify with:"
echo "  ./healthcheck.sh"
echo "  docker logs openclaw-n8n --tail 20"
echo "  docker logs openclaw-gateway --tail 20"
echo ""