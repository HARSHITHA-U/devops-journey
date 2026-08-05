const client = require('prom-client');
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const requestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests received',
  registers: [register]
});

const http = require('http');
const message = process.env.APP_MESSAGE || 'Default message - no config found';
const apiKey = process.env.API_KEY || 'no-key-found';

const server = http.createServer(async (req, res) => {

  requestCounter.inc();

  if (req.url === '/metrics') {
    res.writeHead(200, { 'Content-Type': register.contentType });
    res.end(await register.metrics());
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain' })
  res.end(message + ' | API_KEY loaded: ' + (apiKey !== 'no-key-found') + '\n');
});

server.listen(8000, () => {
  console.log('Server running at http://localhost:8000 ... press Ctrl+C to stop');
});
