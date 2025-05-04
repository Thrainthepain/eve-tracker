# Stage 1: Build the React application - Ubuntu compatible
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY client/package*.json ./
RUN npm install

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

# Create a startup script for Ubuntu compatibility
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo 'envsubst "\$SERVER_PROTOCOL \$FULL_DOMAIN \$BACKEND_PORT" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo '# Generate self-signed cert for HTTPS if needed and not provided' >> /docker-entrypoint.sh && \
    echo 'if [ "$SERVER_PROTOCOL" = "https" ] && [ "$SSL_MODE" != "skip" ] && [ ! -f "/etc/nginx/ssl/fullchain.pem" ]; then' >> /docker-entrypoint.sh && \
    echo '    mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.sh && \
    echo '    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Add a healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1

EXPOSE 80 443

# Use the script as entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]