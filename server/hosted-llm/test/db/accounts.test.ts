// server/hosted-llm/test/db/accounts.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { createAccount, findAccountByBearerHash, incrementTokens, resetQuota } from '../../src/db/accounts';
import { makeTestDb } from '../fixtures/test-db';

describe('accounts DAO', () => {
  let db: D1Database;

  beforeEach(async () => {
    db = await makeTestDb();
  });

  it('creates and retrieves account by bearer hash', async () => {
    const now = Date.now();
    await createAccount(db, {
      stripeCustomerId: 'cus_test1',
      stripeSubscriptionId: 'sub_test1',
      bearerHash: 'hash1',
      tokensMonthCap: 50000,
      monthResetAt: now + 30 * 86400 * 1000,
    });

    const found = await findAccountByBearerHash(db, 'hash1');
    expect(found?.stripeCustomerId).toBe('cus_test1');
    expect(found?.tokensUsedMonth).toBe(0);
  });

  it('incrementTokens returns true when under cap, false when over', async () => {
    const account = await createAccount(db, {
      stripeCustomerId: 'cus_test2',
      stripeSubscriptionId: 'sub_test2',
      bearerHash: 'hash2',
      tokensMonthCap: 100,
      monthResetAt: Date.now() + 30 * 86400 * 1000,
    });

    expect(await incrementTokens(db, account.idHash, 50)).toBe(true);
    expect(await incrementTokens(db, account.idHash, 60)).toBe(false); // 50+60 > 100
  });

  it('resetQuota zeroes used and bumps month_reset_at', async () => {
    const now = Date.now();
    const account = await createAccount(db, {
      stripeCustomerId: 'cus_test3',
      stripeSubscriptionId: 'sub_test3',
      bearerHash: 'hash3',
      tokensMonthCap: 100,
      monthResetAt: now,
    });
    await incrementTokens(db, account.idHash, 75);
    await resetQuota(db, account.idHash);
    const after = await findAccountByBearerHash(db, 'hash3');
    expect(after?.tokensUsedMonth).toBe(0);
    expect(after?.monthResetAt).toBeGreaterThan(now);
  });
});
