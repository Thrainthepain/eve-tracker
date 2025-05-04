# Stage 1: Build the React application - Ubuntu compatible
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY client/package*.json ./
RUN npm install --production

# Copy source files
COPY client/src ./src
COPY client/public ./public

# Build the React app
RUN npm run build

# Stage 2: Create the production image - Ubuntu compatible
FROM nginx:alpine

# Create required directories
RUN mkdir -p /var/www/certbot /etc/nginx/ssl /usr/share/nginx/html/custom-assets

# Copy built files from build phase
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Install required packages for Ubuntu compatibility
RUN apk add --no-cache bash curl wget openssl

# Create a startup script for Ubuntu compatibility
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo '# Process template' >> /docker-entrypoint.sh && \
    echo 'envsubst "\$SERVER_PROTOCOL \$FULL_DOMAIN \$BACKEND_PORT" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo '# Generate self-signed cert for HTTPS if needed and not provided' >> /docker-entrypoint.sh && \
    echo 'if [ "$SERVER_PROTOCOL" = "https" ] && [ "$SSL_MODE" = "skip" ] && [ ! -f "/etc/nginx/ssl/fullchain.pem" ]; then' >> /docker-entrypoint.sh && \
    echo '    mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.sh && \
    echo '    echo "Generating self-signed certificate for development..."' >> /docker-entrypoint.sh && \
    echo '    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo '# Check if the certificates exist for letsencrypt mode' >> /docker-entrypoint.sh && \
    echo 'if [ "$SERVER_PROTOCOL" = "https" ] && [ "$SSL_MODE" = "letsencrypt" ]; then' >> /docker-entrypoint.sh && \
    echo '    if [ -d "/etc/letsencrypt/live/$FULL_DOMAIN" ]; then' >> /docker-entrypoint.sh && \
    echo '        echo "Using Let'"'"'s Encrypt certificates for $FULL_DOMAIN"' >> /docker-entrypoint.sh && \
    echo '        ln -sf /etc/letsencrypt/live/$FULL_DOMAIN/fullchain.pem /etc/nginx/ssl/fullchain.pem' >> /docker-entrypoint.sh && \
    echo '        ln -sf /etc/letsencrypt/live/$FULL_DOMAIN/privkey.pem /etc/nginx/ssl/privkey.pem' >> /docker-entrypoint.sh && \
    echo '    else' >> /docker-entrypoint.sh && \
    echo '        echo "Let'"'"'s Encrypt certificates not found for $FULL_DOMAIN. Generating temporary self-signed certificate..."' >> /docker-entrypoint.sh && \
    echo '        mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.sh && \
    echo '        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=$FULL_DOMAIN" -addext "subjectAltName=DNS:$FULL_DOMAIN"' >> /docker-entrypoint.sh && \
    echo '    fi' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Label with build date for tracking
LABEL org.opencontainers.image.created="2025-05-04T03:19:37Z" \
      org.opencontainers.image.authors="Thrainthepain" \
      org.opencontainers.image.title="EVE Online Character Tracker - Frontend"

# Add a healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1

EXPOSE 80 443

# Use the script as entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]