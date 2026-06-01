// server/hosted-llm/src/upstream.ts
import type { Env } from './types';

const MODEL_ALIASES: Record<string, string> = {
  'still_life:fast': 'claude-haiku-4-5',
  'still_life:smart': 'claude-sonnet-4-6',
};

export async function forwardMessages(
  body: Record<string, unknown>,
  env: Env,
  fetchImpl: typeof fetch = fetch,
): Promise<Response> {
  const model = typeof body.model === 'string' ? body.model : '';
  const mappedModel = MODEL_ALIASES[model] ?? model;
  const forwardBody = { ...body, model: mappedModel };

  return fetchImpl(`${env.ANTHROPIC_BASE_URL}/v1/messages`, {
    method: 'POST',
    headers: {
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(forwardBody),
  });
}

export interface AnthropicUsage {
  input_tokens: number;
  output_tokens: number;
  server_tool_use?: { web_search_requests?: number };
}

export function extractTokenCount(response: { usage?: AnthropicUsage }): number {
  const u = response.usage;
  if (!u) return 0;
  return u.input_tokens + u.output_tokens;
}
