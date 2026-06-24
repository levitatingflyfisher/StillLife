// server/hosted-llm/src/index.ts
import type { Env } from './types';
import { handleAccount } from './routes/account';
import { handleRotate } from './routes/rotate';
import { handleActivate } from './routes/activate';
import { handleMessages } from './routes/messages';
import { handleAnalyze } from './routes/analyze';
import { handleStripeWebhook } from './routes/stripe-webhook';
import { handleDeleteAccount } from './routes/delete-account';

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const route = `${req.method} ${url.pathname}`;

    switch (route) {
      case 'GET /v1/account':
        return handleAccount(req, env);
      case 'POST /v1/rotate':
        return handleRotate(req, env);
      case 'POST /v1/activate':
        return handleActivate(req, env);
      case 'POST /v1/messages':
        return handleMessages(req, env);
      case 'POST /api/v1/analyze':
        return handleAnalyze(req, env);
      case 'POST /webhooks/stripe':
        return handleStripeWebhook(req, env);
      case 'DELETE /v1/account':
        return handleDeleteAccount(req, env);
      default:
        return new Response(JSON.stringify({ error: 'not_found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' },
        });
    }
  },
};
