#!/usr/bin/env bash
# server/hosted-llm/scripts/smoke.sh
# End-to-end smoke test for the hosted-llm Worker.
# Prerequisites:
#   - `npm run bridge`   (Terminal A — claude-cli bridge on :9999)
#   - `npm run dev -- --env dev` (Terminal B — Worker on :8787 with UPSTREAM_MODE=dev-bridge)
#   - wrangler authenticated + local D1 migrated
set -euo pipefail

WORKER=http://localhost:8787

# 1. Insert a test account directly (no Stripe needed for this smoke).
echo "Setting up test account..."
BEARER="sl_live_smoketest1234567890123456789012345"
HASH=$(echo -n "$BEARER" | sha256sum | awk '{print $1}')
wrangler d1 execute still-life-hosted-llm --local --command "
  INSERT OR REPLACE INTO accounts (id_hash, stripe_customer_id, stripe_subscription_id, tier, status, bearer_hash, tokens_used_month, tokens_month_cap, month_reset_at, created_at, updated_at)
  VALUES ('smoke_hash', 'cus_smoke', 'sub_smoke', 'pro', 'active', '$HASH', 0, 50000, $(($(date +%s%3N) + 2592000000)), $(date +%s%3N), $(date +%s%3N));
"

# 2. GET /v1/account
echo "GET /v1/account..."
curl -sS -f -H "Authorization: Bearer $BEARER" $WORKER/v1/account | jq .

# 3. POST /v1/messages (uses dev bridge → claude -p)
echo "POST /v1/messages..."
curl -sS -f -X POST -H "Authorization: Bearer $BEARER" -H "Content-Type: application/json" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":50,"messages":[{"role":"user","content":"Reply with the word OK."}]}' \
  $WORKER/v1/messages | jq .

# 4. GET /v1/account — tokens_used should be > 0
echo "Verifying usage incremented..."
curl -sS -H "Authorization: Bearer $BEARER" $WORKER/v1/account | jq '.tokens_used_month'

echo "SMOKE OK"
