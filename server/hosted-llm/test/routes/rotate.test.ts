// server/hosted-llm/test/routes/rotate.test.ts
import { describe, it, expect } from 'vitest';
import worker from '../../src/index';
import { makeTestDb } from '../fixtures/test-db';
import { createAccount } from '../../src/db/accounts';
import { hashBearer } from '../../src/auth';

const env = (db: D1Database) => ({
  DB: db,
  STRIPE_SECRET_KEY: '',
  STRIPE_WEBHOOK_SECRET: '',
  ANTHROPIC_API_KEY: '',
  ANTHROPIC_BASE_URL: '',
  UPSTREAM_MODE: 'anthropic' as const,
});

describe('POST /v1/rotate', () => {
  it('issues new bearer and invalidates old', async () => {
    const db = await makeTestDb();
    const old = 'sl_live_old';
    await createAccount(db, {
      stripeCustomerId: 'cus_r',
      stripeSubscriptionId: 'sub_r',
      bearerHash: await hashBearer(old),
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });

    const req = new Request('https://w/v1/rotate', {
      method: 'POST',
      headers: { Authorization: `Bearer ${old}` },
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { bearer: string };
    expect(body.bearer).toMatch(/^sl_live_[A-Za-z0-9_-]{40}$/);

    // Old bearer no longer works
    const oldReq = new Request('https://w/v1/account', { headers: { Authorization: `Bearer ${old}` } });
    expect((await worker.fetch(oldReq, env(db))).status).toBe(401);

    // New bearer works
    const newReq = new Request('https://w/v1/account', { headers: { Authorization: `Bearer ${body.bearer}` } });
    expect((await worker.fetch(newReq, env(db))).status).toBe(200);
  });
});
