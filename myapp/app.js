const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello! This is my first DevOps app, running live.\n');
});

server.listen(8000, () => {
  console.log('Server running at http://localhost:8000 ... press Ctrl+C to stop');
});
