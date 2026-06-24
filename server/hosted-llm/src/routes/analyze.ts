// server/hosted-llm/src/routes/analyze.ts
import { requireAuth, json } from '../auth';
import { tryReserveTokens, adjustTokens } from '../db/accounts';
import { forwardMessages, extractTokenCount } from '../upstream';
import type { Env } from '../types';

const ANALYZE_PROMPT = `You are identifying a household inventory item from a photo. Respond with JSON matching this schema:
{"item_name": string, "brand"?: string, "model"?: string, "description": string, "category": string, "estimated_price"?: number, "confidence": number}
No prose, no markdown, just the JSON object.`;

export async function handleAnalyze(req: Request, env: Env): Promise<Response> {
  const auth = await requireAuth(env.DB, req);
  if ('response' in auth) return auth.response;

  let body: { image?: string; existing_label?: string; context_frame?: string };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: 'bad_json' });
  }
  if (!body.image) return json(400, { error: 'missing_image' });

  const reserved = 500;
  // Atomic reservation guards against two concurrent analyze calls both
  // squeaking under the cap and both invoking Anthropic.
  const claimed = await tryReserveTokens(env.DB, auth.account.idHash, reserved);
  if (!claimed) {
    return json(429, { error: 'quota_exceeded' });
  }

  const content: Array<Record<string, unknown>> = [
    { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: body.image } },
    {
      type: 'text',
      text: body.existing_label ? `Existing label: ${body.existing_label}` : 'Identify this item.',
    },
  ];

  let upstreamResp: Response;
  try {
    upstreamResp = await forwardMessages(
      {
        model: 'claude-sonnet-4-6',
        max_tokens: reserved,
        system: ANALYZE_PROMPT,
        messages: [{ role: 'user', content }],
      },
      env,
    );
  } catch (err) {
    await adjustTokens(env.DB, auth.account.idHash, -reserved);
    throw err;
  }

  const payload = (await upstreamResp.json()) as {
    content?: Array<{ type: string; text?: string }>;
    usage?: { input_tokens: number; output_tokens: number };
  };

  if (!upstreamResp.ok) {
    // Refund the reservation — the upstream call did not consume real quota.
    await adjustTokens(env.DB, auth.account.idHash, -reserved);
    return new Response(JSON.stringify(payload), {
      status: upstreamResp.status,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const text = payload.content?.find((c) => c.type === 'text')?.text ?? '{}';
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = { item_name: 'Unknown', description: text, category: 'Other', confidence: 0.3 };
  }

  // Reconcile reservation with actual upstream usage.
  const actual = extractTokenCount(payload);
  await adjustTokens(env.DB, auth.account.idHash, actual - reserved);

  return json(200, parsed);
}
