// server/hosted-llm/src/stripe.ts
import type { Env } from './types';

export interface CheckoutSession {
  id: string;
  customer: string;
  subscription: string | null;
  status: 'open' | 'complete' | 'expired';
}

export async function fetchCheckoutSession(
  sessionId: string,
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<CheckoutSession> {
  const res = await fetchImpl(
    `https://api.stripe.com/v1/checkout/sessions/${sessionId}`,
    { headers: { Authorization: `Bearer ${env.STRIPE_SECRET_KEY}` } },
  );
  if (!res.ok) throw new Error(`stripe ${res.status}`);
  return res.json() as Promise<CheckoutSession>;
}
