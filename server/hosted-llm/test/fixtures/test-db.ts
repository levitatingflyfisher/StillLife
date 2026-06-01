// server/hosted-llm/test/fixtures/test-db.ts
import { Miniflare } from 'miniflare';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MIGRATIONS_DIR = path.resolve(__dirname, '../../migrations');

export async function makeTestDb(): Promise<D1Database> {
  const mf = new Miniflare({
    modules: true,
    script: 'export default { fetch() { return new Response("ok"); } };',
    d1Databases: ['DB'],
  });
  const db = (await mf.getD1Database('DB')) as unknown as D1Database;
  // Apply every migration file in lexical order so tests stay in sync with prod.
  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.sql'))
    .sort();
  for (const file of files) {
    const schema = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
    const stripped = schema
      .split('\n')
      .map((line) => line.replace(/--.*$/, ''))
      .join('\n');
    for (const stmt of stripped.split(';').map((s) => s.trim()).filter(Boolean)) {
      await db.exec(stmt.replace(/\n/g, ' '));
    }
  }
  return db;
}
