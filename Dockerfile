# Modern Dockerfile for Python 3.12 compatibility
# Last Updated: 2025-05-04 14:57:40

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

# Create log directories with proper permissions
RUN mkdir -p logs backups uploads \
    && chmod -R 755 logs backups uploads

# Copy package files first for better caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application files
COPY server/ ./server/
COPY config/ ./config/
COPY public/ ./public/

# Set correct permissions
RUN find . -type d -exec chmod 755 {} \; \
    && find . -type f -exec chmod 644 {} \; \
    && find ./server -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

# Metadata
LABEL org.opencontainers.image.created="2025-05-04T14:57:40Z" \
      org.opencontainers.image.authors="Thrainthepaindocker" \
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