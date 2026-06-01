// server/hosted-llm/src/auth.ts
import { findAccountByBearerHash } from './db/accounts';
import type { Account } from './types';

export function generateBearer(): string {
  const bytes = new Uint8Array(30);
  crypto.getRandomValues(bytes);
  const b64 = btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
  return 'sl_live_' + b64.slice(0, 40);
}

export async function hashBearer(token: string): Promise<string> {
  const data = new TextEncoder().encode(token);
  const buf = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function extractBearer(header: string | null): string | null {
  if (!header) return null;
  const parts = header.trim().split(/\s+/);
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null;
  return parts[1].trim() || null;
}

export type AuthResult =
  | { account: Account }
  | { response: Response };

export async function requireAuth(db: D1Database, req: Request): Promise<AuthResult> {
  const token = extractBearer(req.headers.get('Authorization'));
  if (!token) return { response: json(401, { error: 'missing_bearer' }) };
  const account = await findAccountByBearerHash(db, await hashBearer(token));
  if (!account) return { response: json(401, { error: 'invalid_bearer' }) };
  if (account.status === 'canceled') return { response: json(403, { error: 'subscription_canceled' }) };
  if (account.status === 'past_due') return { response: json(402, { error: 'subscription_past_due' }) };
  return { account };
}

export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
