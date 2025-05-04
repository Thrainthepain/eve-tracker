# Modern Dockerfile for Frontend with Python 3.12 compatibility
# Last Updated: 2025-05-04 14:57:40

# Stage 1: Build the React application
FROM node:20-slim as build

WORKDIR /app

# Copy package files
COPY client/package*.json ./
RUN npm ci --only=production

# Copy source files
COPY client/src ./src
COPY client/public ./public

# Build the React app
RUN npm run build

# Stage 2: Production image
FROM nginx:alpine

# Create required directories
RUN mkdir -p /var/www/certbot /etc/nginx/ssl /usr/share/nginx/html/custom-assets

# Copy built files from build phase
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration template
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Install required packages
RUN apk add --no-cache bash curl wget openssl

# Create a startup script compatible with modern Docker
RUN echo '#!/bin/sh' > /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo 'set -e' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '# Generate self-signed cert for HTTPS if needed and not provided' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo 'if [ "$SERVER_PROTOCOL" = "https" ] && [ "$SSL_MODE" = "skip" ] && [ ! -f "/etc/nginx/ssl/fullchain.pem" ]; then' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '    mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '    echo "Generating self-signed certificate for development..."' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo 'fi' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '# Check if the certificates exist for letsencrypt mode' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo 'if [ "$SERVER_PROTOCOL" = "https" ] && [ "$SSL_MODE" = "letsencrypt" ]; then' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '    if [ -d "/etc/letsencrypt/live/$FULL_DOMAIN" ]; then' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '        echo "Using Let'"'"'s Encrypt certificates for $FULL_DOMAIN"' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '        ln -sf /etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem /etc/nginx/ssl/fullchain.pem' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '        ln -sf /etc/letsencrypt/live/$FULL_DOMAIN/privkey.pem /etc/nginx/ssl/privkey.pem' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '    else' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '        echo "Let'"'"'s Encrypt certificates not found for $FULL_DOMAIN. Generating temporary self-signed certificate..."' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '        mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=$FULL_DOMAIN" -addext "subjectAltName=DNS:$FULL_DOMAIN"' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo '    fi' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    echo 'fi' >> /docker-entrypoint.d/40-eve-tracker-ssl.sh && \
    chmod +x /docker-entrypoint.d/40-eve-tracker-ssl.sh

# Metadata
LABEL org.opencontainers.image.created="2025-05-04T14:57:40Z" \
      org.opencontainers.image.authors="Thrainthepaindocker" \
      org.opencontainers.image.title="EVE Online Character Tracker - Frontend" \
      org.opencontainers.image.version="2.0"

# Add a healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1

# Expose ports
EXPOSE 80 443