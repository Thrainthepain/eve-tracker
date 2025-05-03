# Build stage
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

# Production stage
FROM nginx:alpine

# Copy built files
COPY --from=build /app/build /usr/share/nginx/html

# Setup for templates
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Create entrypoint script
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'envsubst "\$SERVER_PROTOCOL \$FULL_DOMAIN \$BACKEND_PORT" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]