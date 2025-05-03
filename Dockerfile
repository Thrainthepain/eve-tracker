# Backend Node.js Application
FROM node:18-alpine as backend

WORKDIR /app

# Create necessary directories
RUN mkdir -p logs backups

# Copy package.json files first for better caching
COPY package*.json ./
RUN npm install

# Copy server files
COPY server/ ./server/
COPY config/ ./config/
COPY .env ./.env

# Install tools for database backup
RUN apk add --no-cache mongodb-tools

# Set proper permissions
RUN chmod -R 755 ./logs
RUN chmod -R 755 ./backups

# Command to run the server
CMD ["node", "server/server.js"]