# Ubuntu-compatible Dockerfile for Backend
FROM node:18-alpine

WORKDIR /app

# Create necessary directories with proper Linux permissions
RUN mkdir -p logs backups uploads \
    && chmod -R 755 logs backups uploads

# Install required tools (compatible with Ubuntu)
RUN apk add --no-cache mongodb-tools tzdata bash curl wget

# Copy package.json files
COPY package*.json ./
RUN npm install --production

# Copy server files
COPY server/ ./server/
COPY config/ ./config/
COPY public/ ./public/

# Set correct permissions for Linux/Ubuntu
RUN find . -type d -exec chmod 755 {} \; \
    && find . -type f -exec chmod 644 {} \; \
    && find ./server -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

# Label with build date for tracking
LABEL org.opencontainers.image.created="2025-05-04T03:19:37Z" \
      org.opencontainers.image.authors="Thrainthepain" \
      org.opencontainers.image.title="EVE Online Character Tracker - Backend"

# Add healthcheck that works with both Docker Desktop and Ubuntu's Docker
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -q --spider http://localhost:${PORT:-5000}/api/health || exit 1

# Command to run the server (works on both Docker Desktop and Ubuntu)
CMD ["node", "server/server.js"]