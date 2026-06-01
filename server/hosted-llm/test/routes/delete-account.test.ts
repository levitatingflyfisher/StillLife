// server/hosted-llm/test/routes/delete-account.test.ts
import { describe, it, expect, beforeEach, afterEach, beforeAll, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import worker from '../../src/index';
import { makeTestDb } from '../fixtures/test-db';
import { createAccount, findAccountByBearerHash } from '../../src/db/accounts';
import { hashBearer } from '../../src/auth';

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

describe('DELETE /v1/account', () => {
  it('cancels Stripe subscription and deletes account, returns 204', async () => {
    let stripeCalled = false;
    server.use(
      http.delete('https://api.stripe.com/v1/subscriptions/sub_del', () => {
        stripeCalled = true;
        return HttpResponse.json({ id: 'sub_del', status: 'canceled' });
      }),
    );

    const db = await makeTestDb();
    await createAccount(db, {
      stripeCustomerId: 'cus_del',
      stripeSubscriptionId: 'sub_del',
      bearerHash: await hashBearer('sl_live_del'),
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });

    const req = new Request('https://w/v1/account', {
      method: 'DELETE',
      headers: { Authorization: 'Bearer sl_live_del' },
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(204);
    expect(stripeCalled).toBe(true);

    const found = await findAccountByBearerHash(db, await hashBearer('sl_live_del'));
    expect(found).toBeNull();
  });

  it('returns 401 without bearer', async () => {
    const db = await makeTestDb();
    const req = new Request('https://w/v1/account', { method: 'DELETE' });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(401);
  });
});
