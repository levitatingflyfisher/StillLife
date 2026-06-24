// server/hosted-llm/src/routes/rotate.ts
import { requireAuth, json, generateBearer, hashBearer } from '../auth';
import { rotateBearer } from '../db/accounts';
import type { Env } from '../types';

export async function handleRotate(req: Request, env: Env): Promise<Response> {
  const auth = await requireAuth(env.DB, req);
  if ('response' in auth) return auth.response;
  const newBearer = generateBearer();
  await rotateBearer(env.DB, auth.account.idHash, await hashBearer(newBearer));
  return json(200, { bearer: newBearer });
}
