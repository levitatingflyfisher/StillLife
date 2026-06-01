// server/hosted-llm/src/routes/delete-account.ts
import { requireAuth } from '../auth';
import { deleteAccount } from '../db/accounts';
import type { Env } from '../types';

export async function handleDeleteAccount(req: Request, env: Env): Promise<Response> {
  const auth = await requireAuth(env.DB, req);
  if ('response' in auth) return auth.response;

  // Cancel Stripe subscription at period end.
  if (auth.account.stripeSubscriptionId) {
    try {
      await fetch(`https://api.stripe.com/v1/subscriptions/${auth.account.stripeSubscriptionId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${env.STRIPE_SECRET_KEY}` },
      });
    } catch {
      // Best-effort; proceed with local deletion regardless.
    }
  }

  await deleteAccount(env.DB, auth.account.idHash);
  return new Response(null, { status: 204 });
}
