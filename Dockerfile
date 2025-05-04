# Modern Dockerfile for Python 3.12 compatibility
# Created by: ThrainthepainNow
# Last Updated: 2025-05-04 16:06:31

# Node.js base for the backend
FROM node:20-slim AS backend

WORKDIR /app

# Install modern tooling including Python 3.12 support
# Removed mongodb-clients which was causing the build failure
RUN apt-get update && apt-get install -y \
    python3-full \
    python3-pip \
    python3-venv \
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
RUN npm ci --only=production || npm install --only=production

# Copy application files - with conditional copy to prevent failures
COPY server/ ./server/
COPY config/ ./config/ 2>/dev/null || echo "No config directory found."

# Set correct permissions
RUN find . -type d -exec chmod 755 {} \; \
    && find . -type f -exec chmod 644 {} \; \
    && find ./server -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

# Set environment variables
ENV NODE_ENV=production \
    TZ=UTC

# Health check that works with modern Docker
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -q --spider http://localhost:${PORT:-5000}/api/health || exit 1

# Command to run the server
CMD ["node", "server/server.js"]