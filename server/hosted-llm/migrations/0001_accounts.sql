-- server/hosted-llm/migrations/0001_accounts.sql
CREATE TABLE accounts (
    id_hash                TEXT PRIMARY KEY NOT NULL,
    stripe_customer_id     TEXT UNIQUE NOT NULL,
    stripe_subscription_id TEXT UNIQUE,
    tier                   TEXT NOT NULL DEFAULT 'pro',
    status                 TEXT NOT NULL DEFAULT 'active',
    bearer_hash            TEXT UNIQUE NOT NULL,
    tokens_used_month      INTEGER NOT NULL DEFAULT 0,
    tokens_month_cap       INTEGER NOT NULL DEFAULT 50000,
    month_reset_at         INTEGER NOT NULL,
    created_at             INTEGER NOT NULL,
    updated_at             INTEGER NOT NULL
);

CREATE INDEX idx_accounts_bearer ON accounts (bearer_hash);
CREATE INDEX idx_accounts_stripe_sub ON accounts (stripe_subscription_id);

CREATE TABLE webhook_events (
    id           TEXT PRIMARY KEY NOT NULL,
    type         TEXT NOT NULL,
    processed_at INTEGER NOT NULL
);
