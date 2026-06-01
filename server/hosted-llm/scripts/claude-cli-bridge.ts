// server/hosted-llm/scripts/claude-cli-bridge.ts
import http from 'node:http';
import { spawn } from 'node:child_process';

// Minimal HTTP server that receives Anthropic-shaped requests and answers
// by shelling out to `claude --print`. Used for local dev only.
const PORT = 9999;

http.createServer((req, res) => {
  if (req.method !== 'POST' || !req.url?.endsWith('/v1/messages')) {
    res.writeHead(404);
    res.end();
    return;
  }
  let body = '';
  req.on('data', (chunk) => (body += chunk));
  req.on('end', async () => {
    try {
      const payload = JSON.parse(body);
      const messages = payload.messages as Array<{
        content: string | Array<{ type: string; text?: string }>;
      }>;
      const text = messages
        .map((m) => {
          if (typeof m.content === 'string') return m.content;
          return m.content
            .filter((c) => c.type === 'text')
            .map((c) => c.text)
            .join('\n');
        })
        .join('\n---\n');

      const child = spawn('claude', ['--print', '--bare', '--max-budget-usd', '0.10', text]);
      let out = '';
      child.stdout.on('data', (d) => (out += d.toString()));
      child.on('close', () => {
        const response = {
          id: 'msg_dev_' + Date.now(),
          type: 'message',
          role: 'assistant',
          content: [{ type: 'text', text: out }],
          model: payload.model,
          stop_reason: 'end_turn',
          usage: { input_tokens: text.length, output_tokens: out.length },
        };
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(response));
      });
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: String(e) }));
    }
  });
}).listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`claude-cli bridge listening on :${PORT}`);
});
