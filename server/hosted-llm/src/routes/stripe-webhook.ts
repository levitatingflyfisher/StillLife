// server/hosted-llm/src/routes/stripe-webhook.ts
import { json } from '../auth';
import { updateStatus, resetQuota, findAccountByStripeSubscription } from '../db/accounts';
import type { Env } from '../types';

// Stripe's default replay-attack window for signed webhook payloads (5 minutes).
const STRIPE_TIMESTAMP_TOLERANCE_SECONDS = 300;

export async function handleStripeWebhook(req: Request, env: Env): Promise<Response> {
  const signature = req.headers.get('Stripe-Signature');
  const payload = await req.text();
  if (!signature) return json(400, { error: 'missing_signature' });

  const verification = await verifySignature(payload, signature, env.STRIPE_WEBHOOK_SECRET);
  if (verification === 'stale') return json(400, { error: 'stale_signature' });
  if (!verification) return json(400, { error: 'bad_signature' });

  let event: { id: string; type: string; data: { object: Record<string, unknown> } };
  try {
    event = JSON.parse(payload);
  } catch {
    return json(400, { error: 'bad_json' });
  }

  // Idempotency: INSERT first to win the race atomically. If another delivery
  // already inserted this event id, INSERT OR IGNORE reports 0 changes and we
  // short-circuit without re-processing the business logic.
  const insertResult = await env.DB.prepare(
    'INSERT OR IGNORE INTO webhook_events (id, type, processed_at) VALUES (?, ?, ?)',
  )
    .bind(event.id, event.type, Date.now())
    .run();
  if ((insertResult.meta.changes ?? 0) === 0) {
    return json(200, { ok: true, duplicate: true });
  }

  switch (event.type) {
    case 'customer.subscription.deleted': {
      const subId = event.data.object.id as string;
      await updateStatus(env.DB, subId, 'canceled');
      break;
    }
    case 'customer.subscription.updated': {
      const obj = event.data.object as { id: string; status: string };
      if (obj.status === 'active') await updateStatus(env.DB, obj.id, 'active');
      else if (obj.status === 'past_due') await updateStatus(env.DB, obj.id, 'past_due');
      else if (obj.status === 'canceled' || obj.status === 'unpaid') await updateStatus(env.DB, obj.id, 'canceled');
      break;
    }
    case 'invoice.payment_failed': {
      const subId = (event.data.object as { subscription?: string }).subscription;
      if (subId) await updateStatus(env.DB, subId, 'past_due');
      break;
    }
    case 'invoice.payment_succeeded': {
      const subId = (event.data.object as { subscription?: string }).subscription;
      if (subId) {
        const acc = await findAccountByStripeSubscription(env.DB, subId);
        if (acc) {
          await resetQuota(env.DB, acc.idHash);
          await updateStatus(env.DB, subId, 'active');
        }
      }
      break;
    }
  }

  return json(200, { ok: true });
}

type SignatureResult = boolean | 'stale';

async function verifySignature(payload: string, header: string, secret: string): Promise<SignatureResult> {
  const parts = Object.fromEntries(header.split(',').map((p) => p.split('=')));
  const ts = parts.t;
  const v1 = parts.v1;
  if (!ts || !v1) return false;

  // Reject stale or future-dated timestamps to prevent replay of captured payloads.
  const tsSeconds = parseInt(ts, 10);
  if (!Number.isFinite(tsSeconds)) return false;
  const nowSeconds = Date.now() / 1000;
  if (Math.abs(nowSeconds - tsSeconds) > STRIPE_TIMESTAMP_TOLERANCE_SECONDS) {
    return 'stale';
  }

  const signed = `${ts}.${payload}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const matches = v1.match(/.{2}/g);
  if (!matches) return false;
  const sigBytes = new Uint8Array(matches.map((h: string) => parseInt(h, 16)));
  return crypto.subtle.verify('HMAC', key, sigBytes, new TextEncoder().encode(signed));
}
