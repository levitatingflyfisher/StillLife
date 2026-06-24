// server/hosted-llm/test/routes/messages.test.ts
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
  STRIPE_SECRET_KEY: '',
  STRIPE_WEBHOOK_SECRET: '',
  ANTHROPIC_API_KEY: 'sk-ant-test',
  ANTHROPIC_BASE_URL: 'https://api.anthropic.com',
  UPSTREAM_MODE: 'anthropic' as const,
});

const seed = async (db: D1Database, bearer: string, cap = 50000) => {
  await createAccount(db, {
    stripeCustomerId: 'cus_x',
    stripeSubscriptionId: 'sub_x',
    bearerHash: await hashBearer(bearer),
    tokensMonthCap: cap,
    monthResetAt: 1e12,
  });
};

describe('POST /v1/messages', () => {
  it('forwards request and increments tokens on success', async () => {
    server.use(
      http.post('https://api.anthropic.com/v1/messages', () =>
        HttpResponse.json({
          id: 'msg_1',
          content: [{ type: 'text', text: 'hi' }],
          usage: { input_tokens: 10, output_tokens: 20 },
        }),
      ),
    );
    const db = await makeTestDb();
    await seed(db, 'sl_live_x');
    const req = new Request('https://w/v1/messages', {
      method: 'POST',
      headers: { Authorization: 'Bearer sl_live_x', 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'still_life:fast', max_tokens: 100, messages: [] }),
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(200);

    const acc = await findAccountByBearerHash(db, await hashBearer('sl_live_x'));
    expect(acc?.tokensUsedMonth).toBe(30);
  });

  it('returns 429 quota_exceeded when cap would be exceeded', async () => {
    const db = await makeTestDb();
    await seed(db, 'sl_live_y', 10);
    const req = new Request('https://w/v1/messages', {
      method: 'POST',
      headers: { Authorization: 'Bearer sl_live_y', 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'still_life:fast', max_tokens: 100, messages: [] }),
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(429);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('quota_exceeded');
  });

  it('two concurrent requests near the cap: exactly one wins, the other is 429', async () => {
    let upstreamCalls = 0;
    server.use(
      http.post('https://api.anthropic.com/v1/messages', () => {
        upstreamCalls++;
        return HttpResponse.json({
          id: 'msg_c',
          content: [{ type: 'text', text: 'ok' }],
          usage: { input_tokens: 5, output_tokens: 5 },
        });
      }),
    );
    const db = await makeTestDb();
    // Cap of 150 with max_tokens=100 each: only one of two concurrent reservations can fit.
    await seed(db, 'sl_live_race', 150);
    const mkReq = () =>
      new Request('https://w/v1/messages', {
        method: 'POST',
        headers: { Authorization: 'Bearer sl_live_race', 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: 'still_life:fast', max_tokens: 100, messages: [] }),
      });

    const [r1, r2] = await Promise.all([worker.fetch(mkReq(), env(db)), worker.fetch(mkReq(), env(db))]);
    const statuses = [r1.status, r2.status].sort();
    expect(statuses).toEqual([200, 429]);
    // Critically: the rejected request must NOT have called upstream.
    expect(upstreamCalls).toBe(1);

    // Final usage = actual tokens for the winner (10), not the reserved 100.
    const acc = await findAccountByBearerHash(db, await hashBearer('sl_live_race'));
    expect(acc?.tokensUsedMonth).toBe(10);
  });

  it('passes streaming responses through with text/event-stream content type', async () => {
    const sseBody =
      'event: message_start\ndata: {"type":"message_start"}\n\n' +
      'event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"text":"hi"}}\n\n' +
      'event: message_stop\ndata: {"type":"message_stop"}\n\n';
    server.use(
      http.post('https://api.anthropic.com/v1/messages', () =>
        new HttpResponse(sseBody, {
          status: 200,
          headers: { 'Content-Type': 'text/event-stream' },
        }),
      ),
    );
    const db = await makeTestDb();
    await seed(db, 'sl_live_stream', 5000);
    const req = new Request('https://w/v1/messages', {
      method: 'POST',
      headers: { Authorization: 'Bearer sl_live_stream', 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'still_life:fast',
        max_tokens: 500,
        stream: true,
        messages: [],
      }),
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toBe('text/event-stream');
    // Body must arrive unparsed — read it as text and verify SSE framing survived.
    const text = await res.text();
    expect(text).toContain('content_block_delta');
    expect(text).toContain('message_stop');

    // Conservative accounting: we cannot parse usage out of a stream in v1,
    // so the reserved 500 stays charged in full.
    const acc = await findAccountByBearerHash(db, await hashBearer('sl_live_stream'));
    expect(acc?.tokensUsedMonth).toBe(500);
  });

  it('rolls back the reservation when upstream returns a non-2xx error', async () => {
    server.use(
      http.post('https://api.anthropic.com/v1/messages', () =>
        HttpResponse.json({ type: 'error', error: { message: 'upstream down' } }, { status: 502 }),
      ),
    );
    const db = await makeTestDb();
    await seed(db, 'sl_live_fail', 1000);
    const req = new Request('https://w/v1/messages', {
      method: 'POST',
      headers: { Authorization: 'Bearer sl_live_fail', 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'still_life:fast', max_tokens: 200, messages: [] }),
    });
    const res = await worker.fetch(req, env(db));
    expect(res.status).toBe(502);
    const acc = await findAccountByBearerHash(db, await hashBearer('sl_live_fail'));
    // Reservation must be fully refunded so the failed call costs nothing.
    expect(acc?.tokensUsedMonth).toBe(0);
  });
});
