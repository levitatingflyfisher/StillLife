// server/hosted-llm/src/routes/messages.ts
import { requireAuth, json } from '../auth';
import { tryReserveTokens, adjustTokens } from '../db/accounts';
import { forwardMessages, extractTokenCount } from '../upstream';
import type { Env } from '../types';

export async function handleMessages(req: Request, env: Env): Promise<Response> {
  const auth = await requireAuth(env.DB, req);
  if ('response' in auth) return auth.response;

  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return json(400, { error: 'bad_json' });
  }

  // Reserve the worst-case spend up front in a single atomic UPDATE — this
  // closes the TOCTOU window where two concurrent requests could each pass a
  // pre-check and both call Anthropic.
  const reserved = typeof body.max_tokens === 'number' ? body.max_tokens : 1024;
  const claimed = await tryReserveTokens(env.DB, auth.account.idHash, reserved);
  if (!claimed) {
    return json(429, { error: 'quota_exceeded' });
  }

  const isStreaming = body.stream === true;

  let upstreamResp: Response;
  try {
    upstreamResp = await forwardMessages(body, env);
  } catch (err) {
    // Network failure before we even got a status — refund the reservation.
    await adjustTokens(env.DB, auth.account.idHash, -reserved);
    throw err;
  }

  if (isStreaming) {
    // Non-2xx from upstream arrives as JSON, not SSE — parse, refund, return.
    if (!upstreamResp.ok) {
      const errPayload = (await upstreamResp.json()) as Record<string, unknown>;
      await adjustTokens(env.DB, auth.account.idHash, -reserved);
      return new Response(JSON.stringify(errPayload), {
        status: upstreamResp.status,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    // TODO(v2): parse Anthropic SSE message_delta usage frames to reconcile
    // streaming token usage. For now we conservatively keep the full
    // reservation as spent rather than risk under-charging the account.
    return new Response(upstreamResp.body, {
      status: upstreamResp.status,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    });
  }

  const payload = (await upstreamResp.json()) as {
    usage?: { input_tokens: number; output_tokens: number };
  };

  if (upstreamResp.ok) {
    // Reconcile the reservation with actual usage (may be negative if the
    // model used fewer tokens than max_tokens, releasing the unused quota).
    const actual = extractTokenCount(payload);
    await adjustTokens(env.DB, auth.account.idHash, actual - reserved);
  } else {
    // Roll back the full reservation — a failed upstream call costs nothing.
    await adjustTokens(env.DB, auth.account.idHash, -reserved);
  }

  return new Response(JSON.stringify(payload), {
    status: upstreamResp.status,
    headers: { 'Content-Type': 'application/json' },
  });
}
