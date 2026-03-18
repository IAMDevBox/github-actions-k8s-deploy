'use strict';

const http = require('http');

const PORT = process.env.PORT || 8080;

// Simple in-memory readiness gate — set to false during graceful shutdown
let isReady = true;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', uptime: process.uptime() }));
    return;
  }

  if (req.url === '/ready') {
    if (!isReady) {
      res.writeHead(503, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'not ready' }));
      return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ready' }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ message: 'Hello from IAMDevBox demo app!' }));
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Graceful shutdown: stop accepting new requests, drain in-flight
process.on('SIGTERM', () => {
  console.log('SIGTERM received — starting graceful shutdown');
  isReady = false;
  setTimeout(() => {
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
  }, 5000); // 5s drain window matches terminationGracePeriodSeconds
});
