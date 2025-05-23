#!/bin/bash

# EVE Online Character Tracker - All-In-One Docker Setup Script
# Created by: ThrainthepainFix
# Last Updated: 2025-05-05 00:56:35

echo "==================================================================="
echo "EVE Online Character Tracker - All-In-One Docker Setup Script"
echo "Created by: ThrainthepainFix"
echo "Last Updated: 2025-05-05 00:56:35"
echo "==================================================================="

# Function to set up directory structure
setup_directories() {
  echo "Setting up directory structure..."
  
  # Create all required directories
  directories=(
    "logs"
    "backups"
    "uploads"
    "public"
    "config"
    "server"
    "client/public/custom-assets"
    "certbot/www"
  )

  for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir"
      echo "Created directory: $dir"
    else
      echo "Directory already exists: $dir"
    fi
  done

  # Create minimal placeholder files if needed
  if [ ! -f "server/server.js" ]; then
    echo "Creating minimal server.js file..."
    cat > server/server.js << 'EOF'
const http = require('http');

const PORT = process.env.PORT || 5000;

// Simple server
const server = http.createServer((req, res) => {
  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', message: 'System is running' }));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF
    echo "Created minimal server.js file"
  fi

  # Create empty package.json if it doesn't exist
  if [ ! -f "package.json" ]; then
    echo "Creating minimal package.json..."
    cat > package.json << 'EOF'
{
  "name": "eve-online-character-tracker",
  "version": "1.0.0",
  "description": "EVE Online Character Tracker",
  "main": "server/server.js",
  "scripts": {
    "start": "node server/server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "engines": {
    "node": ">=14"
  }
}
EOF
    echo "Created minimal package.json file"
  fi

  # Create client-side package.json if it doesn't exist
  if [ ! -f "client/package.json" ]; then
    mkdir -p client
    echo "Creating minimal client package.json..."
    cat > client/package.json << 'EOF'
{
  "name": "eve-online-character-tracker-client",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "scripts": {
    "build": "echo \"This is a placeholder build script\" && mkdir -p build && touch build/index.html"
  }
}
EOF
    echo "Created minimal client package.json file"
  fi

  # Create basic nginx.conf if it doesn't exist
  if [ ! -f "nginx.conf" ]; then
    echo "Creating minimal nginx.conf..."
    cat > nginx.conf << 'EOF'
# Simple Nginx configuration
# Last Updated: 2025-05-05 00:56:35

server {
    listen 80;
    server_name ${FULL_DOMAIN};

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:${BACKEND_PORT}/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }

    # For Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl;
    server_name ${FULL_DOMAIN};

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:${BACKEND_PORT}/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
EOF
    echo "Created minimal nginx.conf file"
  fi

  # Create a sample config file if needed
  if [ ! -f "config/default.json" ]; then
    echo "Creating sample config file..."
    mkdir -p config
    cat > config/default.json << 'EOF'
{
  "app": {
    "name": "EVE Online Character Tracker"
  }
}
EOF
    echo "Created sample config file"
  fi

  echo "Creating backend Dockerfile..."
  cat > Dockerfile << EOF
# Node.js backend for EVE Online Character Tracker
# Created by: ThrainthepainFix
# Last Updated: 2025-05-05 00:56:35

FROM node:14

WORKDIR /app

# Create necessary directories
RUN mkdir -p logs backups uploads public config

# Copy package files first for better caching
COPY package*.json ./
RUN npm ci --only=production || npm install --only=production

# Copy application files
COPY server/ ./server/
COPY config/ ./config/

# Set environment variables
ENV NODE_ENV=production \\
    TZ=UTC

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \\
  CMD curl -f http://localhost:\${PORT:-5000}/api/health || exit 1

# Command to run the server
CMD ["node", "server/server.js"]
EOF
  echo "Created backend Dockerfile"

  echo "Creating frontend Dockerfile..."
  mkdir -p client
  cat > client/Dockerfile << EOF
# Frontend Dockerfile for EVE Online Character Tracker
# Created by: ThrainthepainFix
# Last Updated: 2025-05-05 00:56:35

# Stage 1: Build the React application
FROM node:14 AS build

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
RUN mkdir -p build && \\
    echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>EVE Tracker</title></head><body><h1>EVE Online Character Tracker</h1><p>Frontend placeholder. Replace with your actual frontend code.</p></body></html>' > build/index.html

# Stage 2: Production image
FROM nginx:alpine

# Create required directories
RUN mkdir -p /var/www/certbot /etc/nginx/ssl /usr/share/nginx/html/custom-assets

# Copy built files from build phase
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration template
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Create startup script to handle SSL certificates
RUN echo '#!/bin/sh' > /docker-entrypoint.d/40-ssl-setup.sh && \\
    echo 'set -e' >> /docker-entrypoint.d/40-ssl-setup.sh && \\
    echo 'mkdir -p /etc/nginx/ssl' >> /docker-entrypoint.d/40-ssl-setup.sh && \\
    echo 'if [ ! -f "/etc/nginx/ssl/fullchain.pem" ]; then' >> /docker-entrypoint.d/40-ssl-setup.sh && \\
    echo '  echo "Generating self-signed certificate"' >> /docker-entrypoint.d/40-ssl-setup.sh && \\
    echo '  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/privkey.pem -out /etc/nginx/ssl/fullchain.pem -subj "/CN=localhost"' >> /docker-entrypoint.d/40-ssl-setup.sh && \\
    echo 'fi' >> /docker-entrypoint.d/40-ssl-setup.sh && \\
    chmod +x /docker-entrypoint.d/40-ssl-setup.sh

# Expose ports
EXPOSE 80 443
EOF
  echo "Created frontend Dockerfile"
}

# Function to check Docker and Docker Compose
check_docker() {
  echo "Checking Docker and Docker Compose installation..."
  
  # Check for Docker
  if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker before running this script."
    exit 1
  else
    echo "Docker is installed."
  fi
  
  # Check for Docker Compose
  if docker compose version &> /dev/null; then
    compose_cmd="docker compose"
    echo "Using Docker Compose v2 plugin."
  elif command -v docker-compose &> /dev/null; then
    compose_cmd="docker-compose"
    echo "Using standalone docker-compose."
  else
    echo "Docker Compose not found. Please install Docker Compose before running this script."
    exit 1
  fi
  
  echo "Using compose command: $compose_cmd"
  return 0
}

# Clean up any existing Docker resources to avoid conflicts
cleanup_docker_resources() {
  echo "Cleaning up any existing Docker resources..."
  
  # Determine if sudo is needed
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -e "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  # Stop existing containers
  echo "Stopping any existing containers..."
  $sudo_cmd docker stop eve-tracker-frontend eve-tracker-backend eve-tracker-mongodb 2>/dev/null || true
  
  # Remove existing containers
  echo "Removing any existing containers..."
  $sudo_cmd docker rm eve-tracker-frontend eve-tracker-backend eve-tracker-mongodb 2>/dev/null || true
  
  # Remove existing network
  echo "Removing existing Docker network if it exists..."
  $sudo_cmd docker network rm eve-network 2>/dev/null || true
  
  # Wait for cleanup to complete
  sleep 2
  echo "Cleanup completed."
}

# Update docker-compose.yml
update_compose_file() {
  echo "Creating/Updating docker-compose.yml..."
  
  # Backup existing file if it exists
  if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.bak
    echo "Backed up existing docker-compose.yml to docker-compose.yml.bak"
  fi
  
  cat > docker-compose.yml << 'EOF'
# EVE Online Character Tracker - Docker Compose Configuration
# Created by: ThrainthepainFix
# Last Updated: 2025-05-05 00:56:35
version: '3.8'

services:
  mongodb:
    image: mongo:4
    container_name: eve-tracker-mongodb
    volumes:
      - mongo_data:/data/db
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_INITDB_ROOT_USERNAME:-root}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_INITDB_ROOT_PASSWORD:-password}
      TZ: UTC
    networks:
      - eve-network

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: eve-tracker-backend
    restart: unless-stopped
    depends_on:
      - mongodb
    environment:
      PORT: ${PORT:-5000}
      MONGO_URI: ${MONGO_URI:-mongodb://root:${MONGO_INITDB_ROOT_PASSWORD:-password}@mongodb:27017/eve-tracker?authSource=admin}
      CLIENT_URL: ${CLIENT_URL:-http://localhost}
      SERVER_URL: ${SERVER_URL:-http://localhost:5000}
      EVE_CLIENT_ID: ${EVE_CLIENT_ID:-your_client_id}
      EVE_CLIENT_SECRET: ${EVE_CLIENT_SECRET:-your_client_secret}
      SESSION_SECRET: ${SESSION_SECRET:-session_secret_placeholder}
      NODE_ENV: ${NODE_ENV:-production}
      WEBSITE_NAME: ${WEBSITE_NAME:-EVE Character Tracker}
      TZ: UTC
    ports:
      - "${BACKEND_PORT:-5000}:${PORT:-5000}"
    volumes:
      - ./logs:/app/logs
      - ./backups:/app/backups
      - ./uploads:/app/uploads
    networks:
      - eve-network

  frontend:
    build:
      context: .
      dockerfile: client/Dockerfile
    container_name: eve-tracker-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      SERVER_PROTOCOL: ${SERVER_PROTOCOL:-http}
      FULL_DOMAIN: ${FULL_DOMAIN:-localhost}
      BACKEND_PORT: ${BACKEND_PORT:-5000}
      SSL_MODE: ${SSL_MODE:-skip}
      TZ: UTC
    ports:
      - "${FRONTEND_PORT:-80}:80"
      - "443:443"
    networks:
      - eve-network
    volumes:
      - ./client/public:/usr/share/nginx/html/custom-assets
      - ./nginx.conf:/etc/nginx/templates/default.conf.template
      - ssl_certs:/etc/nginx/ssl
      - ./certbot/www:/var/www/certbot

networks:
  eve-network:
    name: eve-network

volumes:
  mongo_data:
    name: eve-tracker-mongodb-data
  ssl_certs:
    name: eve-tracker-ssl-certs
EOF

  echo "docker-compose.yml file updated."
}

# Setup .env file if it doesn't exist
setup_env() {
  if [ ! -f .env ]; then
    echo "Creating .env file..."
    
    # Generate random secure strings for passwords
    session_secret=$(head -c 32 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 32 || echo "secure_session_secret_$(date +%s)")
    mongo_password=$(head -c 16 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 16 || echo "mongo_password_$(date +%s)")
    
    # Simple input for required API credentials
    read -p "Enter EVE ESI Client ID (or leave blank for placeholder): " eve_client_id
    eve_client_id=${eve_client_id:-"your_client_id"}
    
    read -p "Enter EVE ESI Client Secret (or leave blank for placeholder): " eve_client_secret
    eve_client_secret=${eve_client_secret:-"your_client_secret"}
    
    read -p "Enter Developer Email (or leave blank for placeholder): " dev_email
    dev_email=${dev_email:-"developer@example.com"}
    
    # Create the .env file
    cat > .env << EOF
# EVE Online Character Tracker Environment Configuration
# Created by: ThrainthepainFix
# Last Updated: 2025-05-05 00:56:35

# Server Configuration
PORT=5000
NODE_ENV=production
SESSION_SECRET=${session_secret}

# Database Configuration
MONGO_URI=mongodb://root:${mongo_password}@mongodb:27017/eve-tracker?authSource=admin
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=${mongo_password}

# URL Configuration
SERVER_PROTOCOL=http
SERVER_DOMAIN=localhost
SERVER_SUBDOMAIN=
FULL_DOMAIN=localhost
CLIENT_URL=http://localhost:80
SERVER_URL=http://localhost:5000

# Docker Configuration
FRONTEND_PORT=80
BACKEND_PORT=5000

# EVE Online API Configuration
EVE_CLIENT_ID=${eve_client_id}
EVE_CLIENT_SECRET=${eve_client_secret}
DEV_EMAIL=${dev_email}

# Application Settings
WEBSITE_NAME="EVE Character Tracker"
DATA_REFRESH_INTERVAL=30

# SSL Configuration
SSL_MODE=skip
LETSENCRYPT_EMAIL=${dev_email}

# Worker Settings
BACKUP_RETENTION_DAYS=7
BACKUP_TIME=2:00
TOKEN_REFRESH_INTERVAL=15
DB_MAINTENANCE_TIME=3:00
EOF

    echo ".env file created successfully."
  else
    echo ".env file already exists, skipping creation."
  fi
}

# Start Docker containers
start_containers() {
  echo "Starting Docker containers..."
  
  # Determine if sudo is needed
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -e "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  # Determine which compose command to use
  if docker compose version &> /dev/null; then
    compose_cmd="docker compose"
  elif command -v docker-compose &> /dev/null; then
    compose_cmd="docker-compose"
  else
    echo "No Docker Compose command found. Please install Docker Compose."
    exit 1
  fi
  
  # Handle rebuild flag
  if [ "$1" = "rebuild" ]; then
    echo "Performing clean rebuild of all containers..."
    $sudo_cmd $compose_cmd build --no-cache
    $sudo_cmd $compose_cmd up -d --force-recreate
  else
    $sudo_cmd $compose_cmd up -d
  fi
  
  # Check if containers started successfully
  if [ $? -ne 0 ]; then
    echo "Failed to start containers. See logs above for details."
    exit 1
  fi
  
  echo "Docker containers started successfully."
}

# Function to verify application is running
verify_application() {
  echo "Verifying application is running..."
  
  # Determine if sudo is needed
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -e "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  # Determine which compose command to use
  if docker compose version &> /dev/null; then
    compose_cmd="docker compose"
  elif command -v docker-compose &> /dev/null; then
    compose_cmd="docker-compose"
  else
    compose_cmd="docker compose" # Default to newer command
  fi
  
  # Wait for services to start
  echo "Waiting for services to fully start (10 seconds)..."
  sleep 10
  
  # Check if containers are running
  container_status=$($sudo_cmd $compose_cmd ps -a)
  echo "Container status:"
  echo "$container_status"
  
  # Try to access the backend API health endpoint
  if command -v curl &> /dev/null; then
    echo "Checking backend API health..."
    if curl -s --connect-timeout 5 http://localhost:5000/api/health | grep -q "healthy"; then
      echo "Backend API is healthy!"
    else
      echo "Warning: Backend API health check failed. Service may still be starting up."
    fi
  fi
}

# Function to show application info
show_application_info() {
  # Read configuration from .env if available
  if [ -f .env ]; then
    # Extract needed information
    server_protocol=$(grep "^SERVER_PROTOCOL=" .env | cut -d= -f2-)
    full_domain=$(grep "^FULL_DOMAIN=" .env | cut -d= -f2-)
    frontend_port=$(grep "^FRONTEND_PORT=" .env | cut -d= -f2-)
    backend_port=$(grep "^BACKEND_PORT=" .env | cut -d= -f2-)
    website_name=$(grep "^WEBSITE_NAME=" .env | cut -d= -f2- | tr -d '"')
  else
    # Default values
    server_protocol="http"
    full_domain="localhost"
    frontend_port="80"
    backend_port="5000"
    website_name="EVE Character Tracker"
  fi
  
  # Determine which compose command to use
  if docker compose version &> /dev/null; then
    compose_cmd="docker compose"
  elif command -v docker-compose &> /dev/null; then
    compose_cmd="docker-compose"
  else
    compose_cmd="docker compose" # Default to newer command
  fi
  
  # Determine if sudo is needed
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -e "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  echo ""
  echo "==================================================================="
  echo "$website_name is now running!"
  echo "==================================================================="
  echo "Frontend URL: ${server_protocol}://${full_domain}:${frontend_port}"
  echo "Backend API: ${server_protocol}://${full_domain}:${backend_port}/api"
  echo ""
  echo "Useful commands:"
  echo "  $sudo_cmd $compose_cmd down              - Stop all containers"
  echo "  $sudo_cmd $compose_cmd logs -f           - View logs"
  echo "  $sudo_cmd $compose_cmd restart           - Restart containers"
  echo "  $sudo_cmd $compose_cmd up -d --build     - Rebuild and restart containers"
  echo "==================================================================="
  echo ""
  echo "If this is your first run, please edit the .env file to enter"
  echo "your actual EVE ESI API credentials before using the application."
  echo "==================================================================="
}

# Main function to orchestrate everything
main() {
  # Check arguments
  rebuild_flag=""
  if [ "$1" = "--rebuild" ] || [ "$1" = "-r" ]; then
    rebuild_flag="rebuild"
    echo "Will perform a complete rebuild of all containers."
  fi

  # Step 1: Set up directories and create necessary files
  setup_directories
  
  # Step 2: Check for Docker and Docker Compose
  check_docker
  
  # Step 3: Clean up existing Docker resources
  cleanup_docker_resources
  
  # Step 4: Update the docker-compose.yml file
  update_compose_file
  
  # Step 5: Set up the environment variables file
  setup_env
  
  # Step 6: Start the containers
  start_containers "$rebuild_flag"
  
  # Step 7: Verify the application is running
  verify_application
  
  # Step 8: Show application information
  show_application_info
}

# Parse command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: bash docker-run.sh [OPTIONS]"
  echo "Options:"
  echo "  --rebuild, -r    Rebuild all containers"
  echo "  --help, -h       Show this help message"
  exit 0
fi

# Run the main function
main "$1"