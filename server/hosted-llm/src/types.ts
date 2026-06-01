// server/hosted-llm/src/types.ts
export interface Env {
  DB: D1Database;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  ANTHROPIC_API_KEY: string;
  ANTHROPIC_BASE_URL: string;
  UPSTREAM_MODE: 'anthropic' | 'dev-bridge';
}

export interface Account {
  idHash: string;
  stripeCustomerId: string;
  stripeSubscriptionId: string | null;
  tier: 'pro';
  status: 'active' | 'canceled' | 'past_due';
  bearerHash: string;
  tokensUsedMonth: number;
  tokensMonthCap: number;
  monthResetAt: number;
  createdAt: number;
  updatedAt: number;
}
