// server/hosted-llm/test/upstream.test.ts
import { describe, it, expect } from 'vitest';
import { forwardMessages } from '../src/upstream';
import type { Env } from '../src/types';

const mockEnv = (overrides: Partial<Env> = {}): Env => ({
  DB: undefined as unknown as D1Database,
  STRIPE_SECRET_KEY: 'sk_test',
  STRIPE_WEBHOOK_SECRET: 'whsec_test',
  ANTHROPIC_API_KEY: 'sk-ant-test',
  ANTHROPIC_BASE_URL: 'https://api.example.test',
  UPSTREAM_MODE: 'anthropic',
  ...overrides,
});

describe('forwardMessages', () => {
  it('injects x-api-key and forwards body verbatim', async () => {
    const fetchMock = async (_input: RequestInfo | URL, init?: RequestInit) => {
      const headers = new Headers(init?.headers);
      expect(headers.get('x-api-key')).toBe('sk-ant-test');
      expect(headers.get('anthropic-version')).toBe('2023-06-01');
      const body = JSON.parse(init?.body as string);
      expect(body.model).toBe('claude-sonnet-4-6');
      return new Response(JSON.stringify({ usage: { input_tokens: 10, output_tokens: 20 } }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    };
    const res = await forwardMessages(
      { model: 'claude-sonnet-4-6', max_tokens: 10, messages: [] },
      mockEnv(),
      fetchMock as unknown as typeof fetch,
    );
    expect(res.status).toBe(200);
    const payload = (await res.json()) as { usage: { output_tokens: number } };
    expect(payload.usage.output_tokens).toBe(20);
  });

  it('rewrites still_life:fast alias to claude-haiku-4-5', async () => {
    let seenModel = '';
    const fetchMock = async (_: RequestInfo | URL, init?: RequestInit) => {
      seenModel = JSON.parse(init?.body as string).model;
      return new Response(JSON.stringify({ usage: { input_tokens: 1, output_tokens: 1 } }));
    };
    await forwardMessages(
      { model: 'still_life:fast', max_tokens: 10, messages: [] },
      mockEnv(),
      fetchMock as unknown as typeof fetch,
    );
    expect(seenModel).toBe('claude-haiku-4-5');
  });
});
