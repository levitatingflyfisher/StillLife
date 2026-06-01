// server/hosted-llm/test/auth.test.ts
import { describe, it, expect } from 'vitest';
import { generateBearer, hashBearer, extractBearer, requireAuth } from '../src/auth';
import { makeTestDb } from './fixtures/test-db';
import { createAccount } from '../src/db/accounts';

describe('auth', () => {
  it('generateBearer returns "sl_live_" + 40 url-safe base64 chars', () => {
    const token = generateBearer();
    expect(token).toMatch(/^sl_live_[A-Za-z0-9_-]{40}$/);
  });

  it('hashBearer is deterministic SHA-256 hex', async () => {
    const a = await hashBearer('sl_live_abc');
    const b = await hashBearer('sl_live_abc');
    const c = await hashBearer('sl_live_xyz');
    expect(a).toBe(b);
    expect(a).not.toBe(c);
    expect(a).toMatch(/^[a-f0-9]{64}$/);
  });

  it('extractBearer parses Authorization header', () => {
    expect(extractBearer('Bearer sl_live_abc')).toBe('sl_live_abc');
    expect(extractBearer('Bearer  ')).toBeNull();
    expect(extractBearer('wrong scheme sl_live_abc')).toBeNull();
    expect(extractBearer(null)).toBeNull();
  });

  it('requireAuth returns account on valid bearer, 401 on invalid', async () => {
    const db = await makeTestDb();
    const hash = await hashBearer('sl_live_valid');
    await createAccount(db, {
      stripeCustomerId: 'cus_1',
      stripeSubscriptionId: 'sub_1',
      bearerHash: hash,
      tokensMonthCap: 50000,
      monthResetAt: Date.now() + 1e9,
    });

    const okReq = new Request('https://w.dev', { headers: { Authorization: 'Bearer sl_live_valid' } });
    const ok = await requireAuth(db, okReq);
    expect('account' in ok).toBe(true);

    const badReq = new Request('https://w.dev', { headers: { Authorization: 'Bearer sl_live_wrong' } });
    const bad = await requireAuth(db, badReq);
    expect('response' in bad).toBe(true);
    expect((bad as { response: Response }).response.status).toBe(401);
  });
});
