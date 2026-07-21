const http = require('http');
const message = process.env.APP_MESSAGE || 'Default message - no config found';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' })
  res.end(message + '\n');
});

server.listen(8000, () => {
  console.log('Server running at http://localhost:8000 ... press Ctrl+C to stop');
});
