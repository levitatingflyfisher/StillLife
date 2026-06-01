// server/hosted-llm/test/routes/account.test.ts
import { describe, it, expect } from 'vitest';
import worker from '../../src/index';
import { makeTestDb } from '../fixtures/test-db';
import { createAccount } from '../../src/db/accounts';
import { hashBearer } from '../../src/auth';

const makeEnv = (db: D1Database) => ({
  DB: db,
  STRIPE_SECRET_KEY: '',
  STRIPE_WEBHOOK_SECRET: '',
  ANTHROPIC_API_KEY: '',
  ANTHROPIC_BASE_URL: '',
  UPSTREAM_MODE: 'anthropic' as const,
});

describe('GET /v1/account', () => {
  it('returns account data for valid bearer', async () => {
    const db = await makeTestDb();
    const bearer = 'sl_live_testbearer';
    const hash = await hashBearer(bearer);
    await createAccount(db, {
      stripeCustomerId: 'cus_a',
      stripeSubscriptionId: 'sub_a',
      bearerHash: hash,
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });

    const req = new Request('https://w/v1/account', { headers: { Authorization: `Bearer ${bearer}` } });
    const res = await worker.fetch(req, makeEnv(db));
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      tier: string;
      status: string;
      tokens_used_month: number;
      tokens_month_cap: number;
      month_reset_at: number;
    };
    expect(body.tier).toBe('pro');
    expect(body.status).toBe('active');
    expect(body.tokens_used_month).toBe(0);
    expect(body.tokens_month_cap).toBe(50000);
    expect(body.month_reset_at).toBe(1e12);
  });

  it('returns 401 for missing bearer', async () => {
    const db = await makeTestDb();
    const req = new Request('https://w/v1/account');
    const res = await worker.fetch(req, makeEnv(db));
    expect(res.status).toBe(401);
  });
});
