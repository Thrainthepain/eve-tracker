# Modern Dockerfile for Python 3.12 compatibility
# Last Updated: 2025-05-04 15:09:22

# Node.js base for the backend
FROM node:20-slim AS backend

WORKDIR /app

# Install modern tooling including Python 3.12 support
RUN apt-get update && apt-get install -y \
    python3-full \
    python3-pip \
    python3-venv \
    mongodb-clients \
    curl \
    wget \
    tzdata \
    bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create log directories and other needed directories with proper permissions
RUN mkdir -p logs backups uploads public \
    && chmod -R 755 logs backups uploads public

# Copy package files first for better caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application files - FIXED to only copy existing directories
COPY server/ ./server/
COPY config/ ./config/ 2>/dev/null || :

# Set correct permissions
RUN find . -type d -exec chmod 755 {} \; \
    && find . -type f -exec chmod 644 {} \; \
    && find ./server -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

# Metadata
LABEL org.opencontainers.image.created="2025-05-04T15:09:22Z" \
      org.opencontainers.image.authors="Thrainthepain" \
      org.opencontainers.image.title="EVE Online Character Tracker - Backend" \
      org.opencontainers.image.version="2.0"

# Set environment variables
ENV NODE_ENV=production \
    TZ=UTC

# Health check that works with modern Docker
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -q --spider http://localhost:${PORT:-5000}/api/health || exit 1

# Command to run the server
CMD ["node", "server/server.js"]
