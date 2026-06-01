# Still Life Hosted LLM Worker

Cloudflare Worker that proxies Anthropic Messages API for Pro subscribers.

## Dev setup
1. `npm install`
2. `cp .dev.vars.example .dev.vars` and fill in Stripe test + Anthropic keys.
3. Terminal A: `npm run bridge` (runs claude-cli upstream on :9999 for dev)
4. Terminal B: `npm run dev -- --env dev` (Worker on :8787, upstream = bridge)
5. Terminal C: `stripe listen --forward-to localhost:8787/webhooks/stripe`

## Tests
- `npm test` — Vitest, no network, uses MSW for Stripe + Anthropic mocks.

## Deploy (operator only)
1. `wrangler d1 create still-life-hosted-llm` -> paste database_id into wrangler.toml
2. `wrangler d1 migrations apply still-life-hosted-llm --remote`
3. `wrangler secret put STRIPE_SECRET_KEY` (and ANTHROPIC_API_KEY, STRIPE_WEBHOOK_SECRET)
4. `wrangler deploy`
