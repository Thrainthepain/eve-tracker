// EVE Online Character Tracker - Minimal Server Implementation
// Created by: ThrainthepainNow
// Last Updated: 2025-05-04 16:06:31

const http = require('http');

const PORT = process.env.PORT || 5000;

// Simple server
const server = http.createServer((req, res) => {
  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', message: 'System is running' }));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});