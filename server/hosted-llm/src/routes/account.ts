// server/hosted-llm/src/routes/account.ts
import { requireAuth, json } from '../auth';
import type { Env } from '../types';

export async function handleAccount(req: Request, env: Env): Promise<Response> {
  const auth = await requireAuth(env.DB, req);
  if ('response' in auth) return auth.response;
  const a = auth.account;
  return json(200, {
    tier: a.tier,
    status: a.status,
    tokens_used_month: a.tokensUsedMonth,
    tokens_month_cap: a.tokensMonthCap,
    month_reset_at: a.monthResetAt,
  });
}
