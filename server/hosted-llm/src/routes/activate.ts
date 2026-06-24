// server/hosted-llm/src/routes/activate.ts
import { json, generateBearer, hashBearer } from '../auth';
import { createAccount, findAccountByStripeSubscription, rotateBearer } from '../db/accounts';
import { fetchCheckoutSession } from '../stripe';
import type { Env } from '../types';

export async function handleActivate(req: Request, env: Env): Promise<Response> {
  let body: { session_id?: string };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: 'bad_json' });
  }
  if (!body.session_id) return json(400, { error: 'missing_session_id' });

  let session;
  try {
    session = await fetchCheckoutSession(body.session_id, env);
  } catch {
    return json(400, { error: 'invalid_session' });
  }

  if (session.status !== 'complete' || !session.subscription) {
    return json(400, { error: 'session_incomplete' });
  }

  // Single-use redemption: claim the session id atomically. If another caller
  // (or a malicious replay of the deep-link URL) already consumed it, refuse
  // to rotate the bearer.
  const claim = await env.DB.prepare(
    'INSERT OR IGNORE INTO consumed_sessions (session_id, consumed_at) VALUES (?, ?)',
  )
    .bind(body.session_id, Date.now())
    .run();
  if ((claim.meta.changes ?? 0) === 0) {
    return json(409, { error: 'session_already_consumed' });
  }

  const bearer = generateBearer();
  const bearerHash = await hashBearer(bearer);
  const monthResetAt = Date.now() + 30 * 86400 * 1000;

  const existing = await findAccountByStripeSubscription(env.DB, session.subscription);
  if (existing) {
    await rotateBearer(env.DB, existing.idHash, bearerHash);
  } else {
    await createAccount(env.DB, {
      stripeCustomerId: session.customer,
      stripeSubscriptionId: session.subscription,
      bearerHash,
      tokensMonthCap: 50000,
      monthResetAt,
    });
  }

  return json(200, { bearer, tier: 'pro', tokens_month_cap: 50000, month_reset_at: monthResetAt });
}
