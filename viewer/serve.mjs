// Static HTTPS server for the viewer. WebXR needs a secure origin, and the
// headset reaches this machine by LAN IP, so plain HTTP won't do.
import { createServer } from 'node:https';
import { readFile, stat } from 'node:fs/promises';
import { readFileSync } from 'node:fs';
import { extname, join, normalize, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { networkInterfaces } from 'node:os';

const root = fileURLToPath(new URL('.', import.meta.url));
const port = Number(process.env.PORT ?? 8443);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.stl': 'model/stl',
};

// Only these are reachable; the certificate key must never be served.
const allowed = ['index.html', 'main.js', 'models', join('node_modules', 'three')];

function resolve(url) {
  const path = decodeURIComponent(new URL(url, 'https://x').pathname);
  const rel = normalize(path).replace(/^[/\\]+/, '') || 'index.html';
  if (rel.split(sep).includes('..')) return null;
  return allowed.some((a) => rel === a || rel.startsWith(a + sep)) ? join(root, rel) : null;
}

const server = createServer(
  { key: readFileSync(join(root, '.cert/key.pem')), cert: readFileSync(join(root, '.cert/cert.pem')) },
  async (req, res) => {
    try {
      const file = resolve(req.url);
      if (!file || !(await stat(file)).isFile()) throw new Error('not found');
      const body = await readFile(file);
      res.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream', 'cache-control': 'no-store' });
      res.end(body);
    } catch {
      res.writeHead(404).end('Not found');
    }
  },
);

server.listen(port, '0.0.0.0', () => {
  for (const nets of Object.values(networkInterfaces()))
    for (const n of nets)
      if (n.family === 'IPv4' && !n.internal) console.log(`https://${n.address}:${port}/`);
});
