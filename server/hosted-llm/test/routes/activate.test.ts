// server/hosted-llm/test/routes/activate.test.ts
import { describe, it, expect, beforeEach, afterEach, beforeAll, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import worker from '../../src/index';
import { makeTestDb } from '../fixtures/test-db';

const server = setupServer();

beforeAll(() => server.listen({ onUnhandledRequest: 'bypass' }));
afterAll(() => server.close());
beforeEach(() => {});
afterEach(() => server.resetHandlers());

const env = (db: D1Database) => ({
  DB: db,
  STRIPE_SECRET_KEY: 'sk_test',
  STRIPE_WEBHOOK_SECRET: '',
  ANTHROPIC_API_KEY: '',
  ANTHROPIC_BASE_URL: '',
  UPSTREAM_MODE: 'anthropic' as const,
});

describe('POST /v1/activate', () => {
  it('creates account from valid Stripe session, returns bearer', async () => {
    server.use(
      http.get('https://api.stripe.com/v1/checkout/sessions/cs_test_valid', () =>
        HttpResponse.json({
          id: 'cs_test_valid',
          customer: 'cus_new',
          subscription: 'sub_new',
          status: 'complete',
        }),
      ),
    );

    const db = await makeTestDb();
    const req = new Request('https://w/v1/activate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: 'cs_test_valid' }),
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { bearer: string; tier: string };
    expect(body.bearer).toMatch(/^sl_live_[A-Za-z0-9_-]{40}$/);
    expect(body.tier).toBe('pro');
  });

  it('rejects incomplete session with 400', async () => {
    server.use(
      http.get('https://api.stripe.com/v1/checkout/sessions/cs_incomplete', () =>
        HttpResponse.json({ id: 'cs_incomplete', status: 'open' }),
      ),
    );
    const db = await makeTestDb();
    const req = new Request('https://w/v1/activate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: 'cs_incomplete' }),
    });
    expect((await worker.fetch(req, env(db))).status).toBe(400);
  });

  it('first activation succeeds; replay of same session returns 409 session_already_consumed', async () => {
    server.use(
      http.get('https://api.stripe.com/v1/checkout/sessions/cs_replay', () =>
        HttpResponse.json({
          id: 'cs_replay',
          customer: 'cus_replay',
          subscription: 'sub_replay',
          status: 'complete',
        }),
      ),
    );

    const db = await makeTestDb();
    const mkReq = () =>
      new Request('https://w/v1/activate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ session_id: 'cs_replay' }),
      });

    const first = await worker.fetch(mkReq(), env(db));
    expect(first.status).toBe(200);
    const firstBody = (await first.json()) as { bearer: string };
    const originalBearer = firstBody.bearer;

    const second = await worker.fetch(mkReq(), env(db));
    expect(second.status).toBe(409);
    const secondBody = (await second.json()) as { error: string };
    expect(secondBody.error).toBe('session_already_consumed');

    // The original bearer must still be valid — replay must NOT have rotated it.
    const accountReq = new Request('https://w/v1/account', {
      headers: { Authorization: `Bearer ${originalBearer}` },
    });
    const accountRes = await worker.fetch(accountReq, env(db));
    expect(accountRes.status).toBe(200);
  });
});
