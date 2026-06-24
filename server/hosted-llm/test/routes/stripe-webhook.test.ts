// server/hosted-llm/test/routes/stripe-webhook.test.ts
import { describe, it, expect } from 'vitest';
import worker from '../../src/index';
import { makeTestDb } from '../fixtures/test-db';
import { createAccount, findAccountByBearerHash } from '../../src/db/accounts';
import { hashBearer } from '../../src/auth';

const env = (db: D1Database) => ({
  DB: db,
  STRIPE_SECRET_KEY: 'sk_test',
  STRIPE_WEBHOOK_SECRET: 'whsec_test_secret',
  ANTHROPIC_API_KEY: '',
  ANTHROPIC_BASE_URL: '',
  UPSTREAM_MODE: 'anthropic' as const,
});

describe('POST /webhooks/stripe', () => {
  it('marks subscription canceled on customer.subscription.deleted', async () => {
    const db = await makeTestDb();
    await createAccount(db, {
      stripeCustomerId: 'cus_w',
      stripeSubscriptionId: 'sub_w',
      bearerHash: await hashBearer('sl_live_w'),
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });

    const payload = JSON.stringify({
      id: 'evt_1',
      type: 'customer.subscription.deleted',
      data: { object: { id: 'sub_w' } },
    });
    const signature = await makeStripeSignature(payload, 'whsec_test_secret');

    const req = new Request('https://w/webhooks/stripe', {
      method: 'POST',
      headers: { 'Stripe-Signature': signature, 'Content-Type': 'application/json' },
      body: payload,
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(200);

    const acc = await findAccountByBearerHash(db, await hashBearer('sl_live_w'));
    expect(acc?.status).toBe('canceled');
  });

  it('is idempotent — same event id processed twice = no-op', async () => {
    const db = await makeTestDb();
    await createAccount(db, {
      stripeCustomerId: 'cus_i',
      stripeSubscriptionId: 'sub_i',
      bearerHash: await hashBearer('sl_live_i'),
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });
    const payload = JSON.stringify({
      id: 'evt_dup',
      type: 'invoice.payment_succeeded',
      data: { object: { subscription: 'sub_i' } },
    });
    const sig = await makeStripeSignature(payload, 'whsec_test_secret');
    const req = () =>
      new Request('https://w/webhooks/stripe', {
        method: 'POST',
        headers: { 'Stripe-Signature': sig, 'Content-Type': 'application/json' },
        body: payload,
      });
    expect((await worker.fetch(req(), env(db))).status).toBe(200);
    expect((await worker.fetch(req(), env(db))).status).toBe(200);
  });

  it('rejects missing signature with 400', async () => {
    const db = await makeTestDb();
    const payload = JSON.stringify({ id: 'evt_x', type: 'noop', data: { object: {} } });
    const req = new Request('https://w/webhooks/stripe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: payload,
    });
    expect((await worker.fetch(req, env(db))).status).toBe(400);
  });

  it('rejects invalid signature with 400', async () => {
    const db = await makeTestDb();
    const payload = JSON.stringify({ id: 'evt_bad', type: 'noop', data: { object: {} } });
    const req = new Request('https://w/webhooks/stripe', {
      method: 'POST',
      headers: { 'Stripe-Signature': 't=1,v1=deadbeef', 'Content-Type': 'application/json' },
      body: payload,
    });
    expect((await worker.fetch(req, env(db))).status).toBe(400);
  });

  it('rejects stale timestamps outside the 5-minute window with 400', async () => {
    const db = await makeTestDb();
    const payload = JSON.stringify({ id: 'evt_stale', type: 'noop', data: { object: {} } });
    // Sign with a timestamp 10 minutes in the past — outside the 5min replay window.
    const staleTs = Math.floor(Date.now() / 1000) - 600;
    const sig = await makeStripeSignatureAt(payload, 'whsec_test_secret', staleTs);
    const req = new Request('https://w/webhooks/stripe', {
      method: 'POST',
      headers: { 'Stripe-Signature': sig, 'Content-Type': 'application/json' },
      body: payload,
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('stale_signature');
  });

  it('idempotency is atomic — second concurrent delivery returns duplicate without re-processing', async () => {
    const db = await makeTestDb();
    await createAccount(db, {
      stripeCustomerId: 'cus_atomic',
      stripeSubscriptionId: 'sub_atomic',
      bearerHash: await hashBearer('sl_live_atomic'),
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });
    const payload = JSON.stringify({
      id: 'evt_atomic',
      type: 'invoice.payment_succeeded',
      data: { object: { subscription: 'sub_atomic' } },
    });
    const sig = await makeStripeSignature(payload, 'whsec_test_secret');
    const mkReq = () =>
      new Request('https://w/webhooks/stripe', {
        method: 'POST',
        headers: { 'Stripe-Signature': sig, 'Content-Type': 'application/json' },
        body: payload,
      });
    // Fire two deliveries concurrently — both should succeed, one duplicate=true.
    const [r1, r2] = await Promise.all([worker.fetch(mkReq(), env(db)), worker.fetch(mkReq(), env(db))]);
    expect(r1.status).toBe(200);
    expect(r2.status).toBe(200);
    const b1 = (await r1.json()) as { ok: boolean; duplicate?: boolean };
    const b2 = (await r2.json()) as { ok: boolean; duplicate?: boolean };
    // Exactly one of the two deliveries should be marked duplicate.
    expect(Boolean(b1.duplicate) !== Boolean(b2.duplicate)).toBe(true);
  });
});

async function makeStripeSignatureAt(payload: string, secret: string, timestamp: number): Promise<string> {
  const ts = timestamp.toString();
  const signedPayload = `${ts}.${payload}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sigBuf = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signedPayload));
  const sigHex = Array.from(new Uint8Array(sigBuf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `t=${ts},v1=${sigHex}`;
}

async function makeStripeSignature(payload: string, secret: string): Promise<string> {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const signedPayload = `${timestamp}.${payload}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sigBuf = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signedPayload));
  const sigHex = Array.from(new Uint8Array(sigBuf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `t=${timestamp},v1=${sigHex}`;
}
