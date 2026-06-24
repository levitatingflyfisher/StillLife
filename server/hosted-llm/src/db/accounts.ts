// server/hosted-llm/src/db/accounts.ts
import type { Account } from '../types';

interface CreateAccountInput {
  stripeCustomerId: string;
  stripeSubscriptionId: string;
  bearerHash: string;
  tokensMonthCap: number;
  monthResetAt: number;
}

export async function createAccount(db: D1Database, input: CreateAccountInput): Promise<Account> {
  const now = Date.now();
  const idHash = await sha256Hex(input.stripeCustomerId);
  await db.prepare(
    `INSERT INTO accounts (id_hash, stripe_customer_id, stripe_subscription_id, tier, status, bearer_hash, tokens_used_month, tokens_month_cap, month_reset_at, created_at, updated_at)
     VALUES (?, ?, ?, 'pro', 'active', ?, 0, ?, ?, ?, ?)`,
  ).bind(idHash, input.stripeCustomerId, input.stripeSubscriptionId, input.bearerHash, input.tokensMonthCap, input.monthResetAt, now, now).run();
  const account = await findAccountByBearerHash(db, input.bearerHash);
  if (!account) throw new Error('insert-then-select returned no row');
  return account;
}

export async function findAccountByBearerHash(db: D1Database, bearerHash: string): Promise<Account | null> {
  const row = await db.prepare('SELECT * FROM accounts WHERE bearer_hash = ?').bind(bearerHash).first();
  return row ? rowToAccount(row) : null;
}

export async function findAccountByStripeSubscription(db: D1Database, subId: string): Promise<Account | null> {
  const row = await db.prepare('SELECT * FROM accounts WHERE stripe_subscription_id = ?').bind(subId).first();
  return row ? rowToAccount(row) : null;
}

export async function incrementTokens(db: D1Database, idHash: string, delta: number): Promise<boolean> {
  const result = await db.prepare(
    `UPDATE accounts
     SET tokens_used_month = tokens_used_month + ?, updated_at = ?
     WHERE id_hash = ? AND tokens_used_month + ? <= tokens_month_cap`,
  ).bind(delta, Date.now(), idHash, delta).run();
  return (result.meta.changes ?? 0) > 0;
}

/**
 * Atomically reserves `amount` tokens against the account's monthly quota.
 *
 * Returns true if the reservation succeeded. Returns false (without modifying
 * the row) if the request would have pushed the running total above the cap.
 * This is the same UPDATE shape as `incrementTokens`, but exposed under a
 * different name to make the call-site intent explicit: callers MUST follow a
 * successful reservation with a corresponding `adjustTokens` once the upstream
 * response is known (positive delta to top-up, negative to refund/rollback).
 */
export async function tryReserveTokens(db: D1Database, idHash: string, amount: number): Promise<boolean> {
  const result = await db.prepare(
    `UPDATE accounts
     SET tokens_used_month = tokens_used_month + ?, updated_at = ?
     WHERE id_hash = ? AND tokens_used_month + ? <= tokens_month_cap`,
  ).bind(amount, Date.now(), idHash, amount).run();
  return (result.meta.changes ?? 0) > 0;
}

/**
 * Applies a signed adjustment to the running token usage. Used to reconcile a
 * prior reservation with actual upstream usage (delta = actual - reserved) or
 * to fully roll back a reservation when the upstream call fails.
 *
 * The MAX(0, ...) guard prevents underflow if a refund would otherwise push
 * the counter negative (defensive — should not happen in practice).
 */
export async function adjustTokens(db: D1Database, idHash: string, delta: number): Promise<void> {
  if (delta === 0) return;
  await db.prepare(
    `UPDATE accounts
     SET tokens_used_month = MAX(0, tokens_used_month + ?), updated_at = ?
     WHERE id_hash = ?`,
  ).bind(delta, Date.now(), idHash).run();
}

export async function resetQuota(db: D1Database, idHash: string): Promise<void> {
  const now = Date.now();
  const nextReset = now + 30 * 86400 * 1000;
  await db.prepare(
    'UPDATE accounts SET tokens_used_month = 0, month_reset_at = ?, updated_at = ? WHERE id_hash = ?',
  ).bind(nextReset, now, idHash).run();
}

export async function rotateBearer(db: D1Database, idHash: string, newBearerHash: string): Promise<void> {
  await db.prepare(
    'UPDATE accounts SET bearer_hash = ?, updated_at = ? WHERE id_hash = ?',
  ).bind(newBearerHash, Date.now(), idHash).run();
}

export async function updateStatus(db: D1Database, subId: string, status: Account['status']): Promise<void> {
  await db.prepare(
    'UPDATE accounts SET status = ?, updated_at = ? WHERE stripe_subscription_id = ?',
  ).bind(status, Date.now(), subId).run();
}

export async function deleteAccount(db: D1Database, idHash: string): Promise<void> {
  await db.prepare('DELETE FROM accounts WHERE id_hash = ?').bind(idHash).run();
}

function rowToAccount(row: Record<string, unknown>): Account {
  return {
    idHash: row.id_hash as string,
    stripeCustomerId: row.stripe_customer_id as string,
    stripeSubscriptionId: row.stripe_subscription_id as string | null,
    tier: row.tier as 'pro',
    status: row.status as Account['status'],
    bearerHash: row.bearer_hash as string,
    tokensUsedMonth: row.tokens_used_month as number,
    tokensMonthCap: row.tokens_month_cap as number,
    monthResetAt: row.month_reset_at as number,
    createdAt: row.created_at as number,
    updatedAt: row.updated_at as number,
  };
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const buf = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, '0')).join('');
}
