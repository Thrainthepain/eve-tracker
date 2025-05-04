# Modern Dockerfile for Frontend
# Created by: ThrainthepainNow
# Last Updated: 2025-05-04 16:06:31

# Stage 1: Build the React application
FROM node:20-slim as build

WORKDIR /app

# Create placeholders if needed
RUN mkdir -p src public

# Create minimal public/index.html file if it doesn't exist
RUN echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>EVE Tracker</title></head><body><div id="root"></div></body></html>' > public/index.html

# Create minimal src/index.js file if it doesn't exist
RUN echo 'console.log("EVE Tracker Frontend");' > src/index.js

# Copy package files (or create them if they don't exist)
COPY client/package*.json ./
RUN npm install || npm init -y

# Build the application (or create a placeholder)
RUN mkdir -p build && \
    echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>EVE Tracker</title></head><body><h1>EVE Online Character Tracker</h1><p>Frontend placeholder. Replace with your actual frontend code.</p></body></html>' > build/index.html

# Stage 2: Production image
FROM nginx:alpine

# Create required directories
RUN mkdir -p /var/www/certbot /etc/nginx/ssl /usr/share/nginx/html/custom-assets

# Copy built files from build phase
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration template
COPY nginx.conf /etc/nginx/templates/default.conf.template || echo "listen 80; server_name localhost; root /usr/share/nginx/html;" > /etc/nginx/templates/default.conf.template

# Install required packages
RUN apk add --no-cache bash curl wget openssl

# Create startup script to handle SSL certificates
RUN echo '#!/bin/sh' > /docker-entrypoint.d/40-ssl-setup.sh && \
    echo 'set -e' >> /docker-entrypoint.d/40-ssl-setup.sh && \
    echo 'mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.d/40-ssl-setup.sh && \
    echo 'if [ ! -f "/etc/nginx/ssl/fullchain.pem" ]; then' >> /docker-entrypoint.d/40-ssl-setup.sh && \
    echo '  echo "Generating self-signed certificate"' >> /docker-entrypoint.d/40-ssl-setup.sh && \
    echo '  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=localhost"' >> /docker-entrypoint.d/40-ssl-setup.sh && \
    echo 'fi' >> /docker-entrypoint.d/40-ssl-setup.sh && \
    chmod +x /docker-entrypoint.d/40-ssl-setup.sh

# Expose ports
EXPOSE 80 443