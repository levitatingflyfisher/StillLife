// server/hosted-llm/test/routes/analyze.test.ts
import { describe, it, expect, beforeEach, afterEach, beforeAll, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import worker from '../../src/index';
import { makeTestDb } from '../fixtures/test-db';
import { createAccount } from '../../src/db/accounts';
import { hashBearer } from '../../src/auth';

const server = setupServer();
beforeAll(() => server.listen({ onUnhandledRequest: 'bypass' }));
afterAll(() => server.close());
beforeEach(() => {});
afterEach(() => server.resetHandlers());

const env = (db: D1Database) => ({
  DB: db,
  STRIPE_SECRET_KEY: '',
  STRIPE_WEBHOOK_SECRET: '',
  ANTHROPIC_API_KEY: 'sk-ant-test',
  ANTHROPIC_BASE_URL: 'https://api.anthropic.com',
  UPSTREAM_MODE: 'anthropic' as const,
});

describe('POST /api/v1/analyze', () => {
  it('sends image to Anthropic and returns parsed AnalysisResult', async () => {
    server.use(
      http.post('https://api.anthropic.com/v1/messages', () =>
        HttpResponse.json({
          id: 'msg_1',
          content: [
            {
              type: 'text',
              text: JSON.stringify({
                item_name: 'Blender',
                brand: 'Vitamix',
                model: '5200',
                description: 'High-power',
                category: 'Kitchen',
                estimated_price: 450,
                confidence: 0.9,
              }),
            },
          ],
          usage: { input_tokens: 100, output_tokens: 50 },
        }),
      ),
    );

    const db = await makeTestDb();
    await createAccount(db, {
      stripeCustomerId: 'cus_a',
      stripeSubscriptionId: 'sub_a',
      bearerHash: await hashBearer('sl_live_a'),
      tokensMonthCap: 50000,
      monthResetAt: 1e12,
    });

    const req = new Request('https://w/api/v1/analyze', {
      method: 'POST',
      headers: { Authorization: 'Bearer sl_live_a', 'Content-Type': 'application/json' },
      body: JSON.stringify({ image: 'AAAA' }),
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { item_name: string; category: string };
    expect(body.item_name).toBe('Blender');
    expect(body.category).toBe('Kitchen');
  });
});
