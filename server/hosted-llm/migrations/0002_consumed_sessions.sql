-- server/hosted-llm/migrations/0002_consumed_sessions.sql
-- Tracks Stripe Checkout session ids that have already been redeemed via
-- POST /v1/activate so the deep-link cannot be replayed to silently rotate a
-- bearer (see polish-v0.23.1 task 3).
CREATE TABLE consumed_sessions (
    session_id   TEXT PRIMARY KEY NOT NULL,
    consumed_at  INTEGER NOT NULL
);
