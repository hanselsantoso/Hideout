import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const port = Number(process.env.PORT || 5455);
const root = path.resolve(process.argv[2] || 'build/web');
const types = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

http
  .createServer((req, res) => {
    const cleanUrl = decodeURIComponent((req.url || '/').split('?')[0]);
    const route = cleanUrl === '/' || cleanUrl === '' ? '/index.html' : cleanUrl;
    let file = path.join(root, route);
    if (!file.startsWith(root)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    fs.stat(file, (statError, stat) => {
      if (statError || !stat.isFile()) file = path.join(root, 'index.html');
      fs.readFile(file, (readError, bytes) => {
        if (readError) {
          res.writeHead(404);
          res.end('Not found');
          return;
        }
        res.writeHead(200, {
          'Cache-Control': 'no-store',
          'Content-Type': types[path.extname(file)] || 'application/octet-stream',
        });
        res.end(bytes);
      });
    });
  })
  .listen(port, '127.0.0.1');
