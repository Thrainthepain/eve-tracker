FROM node:18-alpine

WORKDIR /app

# Create necessary directories
RUN mkdir -p logs backups uploads

# Install required tools
RUN apk add --no-cache mongodb-tools tzdata bash

# Copy package files
COPY package*.json ./
RUN npm install

# Copy server files
COPY server/ ./server/
COPY config/ ./config/
COPY public/ ./public/

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -q --spider http://localhost:${PORT:-5000}/api/health || exit 1

CMD ["node", "server/server.js"]