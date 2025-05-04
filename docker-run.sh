#!/bin/bash

# EVE Online Character Tracker - Docker Setup Script
# Created by: Thrainthepaindocker
# Last Updated: 2025-05-04 14:50:54

# IMPORTANT: DO NOT USE COLOR CODES OR FANCY ECHO FORMATTING

echo "Starting EVE Online Character Tracker setup..."

# Check for Docker installation
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed. Please install Docker first."
  exit 1
fi

# Check for Docker Compose
compose_cmd=""
if command -v docker-compose >/dev/null 2>&1; then
  echo "Docker Compose standalone is installed."
  compose_cmd="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin is installed."
  compose_cmd="docker compose"
else
  echo "ERROR: Docker Compose not found. Please install Docker Compose."
  exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running."
  exit 1
fi

# Set up sudo if needed
sudo_cmd=""
if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
  echo "Docker socket is not writable by current user. Using sudo for Docker commands."
  sudo_cmd="sudo"
fi

# Check for required files
echo "Checking for required files..."
required_files=("Dockerfile" "client/Dockerfile" "docker-compose.yml" "nginx.conf")
missing_files=0

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Required file missing: $file"
    missing_files=1
  else
    echo "Found: $file"
  fi
done

if [ $missing_files -eq 1 ]; then
  echo "ERROR: Required files are missing. Please check your current directory."
  exit 1
fi

# Fix docker-compose.yml
echo "Updating docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup

# Create a fixed docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:4.4
    container_name: eve-tracker-mongodb
    volumes:
      - mongo_data:/data/db
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME:-root}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD:-password}
      - TZ=UTC
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
      - PORT=${PORT:-5000}
      - MONGO_URI=${MONGO_URI}
      - CLIENT_URL=${CLIENT_URL:-http://localhost}
      - SERVER_URL=${SERVER_URL:-http://localhost:5000}
      - EVE_CLIENT_ID=${EVE_CLIENT_ID}
      - EVE_CLIENT_SECRET=${EVE_CLIENT_SECRET}
      - SESSION_SECRET=${SESSION_SECRET}
      - NODE_ENV=${NODE_ENV:-production}
      - WEBSITE_NAME=${WEBSITE_NAME}
      - TZ=UTC
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
      - SERVER_PROTOCOL=${SERVER_PROTOCOL:-http}
      - FULL_DOMAIN=${FULL_DOMAIN:-localhost}
      - BACKEND_PORT=${BACKEND_PORT:-5000}
      - SSL_MODE=${SSL_MODE:-skip}
      - TZ=UTC
    ports:
      - "${FRONTEND_PORT:-80}:80"
      - "443:443"
    networks:
      - eve-network
    volumes:
      - ./client/public:/usr/share/nginx/html/custom-assets
      - ./nginx.conf:/etc/nginx/conf.d/default.conf.template
      - ssl_certs:/etc/nginx/ssl
      - ./certbot/www:/var/www/certbot

  certbot:
    image: certbot/certbot
    container_name: eve-tracker-certbot
    profiles: ["ssl"]
    environment:
      - SSL_MODE=${SSL_MODE:-skip}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-admin@example.com}
      - DOMAIN=${FULL_DOMAIN:-localhost}
    volumes:
      - ssl_certs:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    command: >
      sh -c "if [ \"$${SSL_MODE}\" = \"letsencrypt\" ]; then 
              certbot certonly --webroot -w /var/www/certbot --email $${LETSENCRYPT_EMAIL} --agree-tos --no-eff-email -d $${DOMAIN} || echo \"SSL setup failed or not needed\"; 
            else 
              echo \"SSL not configured for automatic setup\"; 
            fi"
    depends_on:
      - frontend

networks:
  eve-network:
    driver: bridge

volumes:
  mongo_data:
  ssl_certs:
EOF

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p logs backups uploads certbot/www client/public/custom-assets

# Create or update .env file
if [ ! -f ".env" ]; then
  echo "Creating .env file..."
  
  # Generate random passwords
  session_secret=$(head -c 32 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 32 || echo "fallbacksecret123")
  mongo_password=$(head -c 16 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 16 || echo "mongopassword123")
  
  # Create .env file
  cat > .env << EOF
# EVE Online Character Tracker Environment Configuration
# Generated on 2025-05-04 14:50:54

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
EVE_CLIENT_ID=your_client_id
EVE_CLIENT_SECRET=your_client_secret
DEV_EMAIL=your_email@example.com

# Application Settings
WEBSITE_NAME="EVE Character Tracker"
DATA_REFRESH_INTERVAL=30

# SSL Configuration
SSL_MODE=skip
LETSENCRYPT_EMAIL=your_email@example.com

# Worker Settings
BACKUP_RETENTION_DAYS=7
BACKUP_TIME=2:00
TOKEN_REFRESH_INTERVAL=15
DB_MAINTENANCE_TIME=3:00
EOF
  
  echo ".env file created with default values."
  echo "IMPORTANT: Edit your .env file to set up your EVE ESI API credentials."
else
  echo ".env file already exists. Using existing configuration."
fi

# Create Docker network
echo "Setting up Docker network..."
$sudo_cmd docker network create eve-network 2>/dev/null || true

# Start containers
echo "Starting containers..."
$sudo_cmd $compose_cmd up -d

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start containers."
  $sudo_cmd $compose_cmd logs
  exit 1
fi

# Check if containers are running
echo "Checking if containers are running..."
sleep 5
running_containers=$($sudo_cmd docker ps --format '{{.Names}}' | grep -c "eve-tracker" || echo "0")

if [ "$running_containers" -lt 3 ]; then
  echo "Not all containers are running. Showing logs..."
  $sudo_cmd $compose_cmd logs
  exit 1
fi

# Successful completion
echo "===================================================="
echo "EVE Online Character Tracker is now running!"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost:5000/api"
echo "===================================================="
echo "To stop the application: $sudo_cmd $compose_cmd down"
echo "To view logs: $sudo_cmd $compose_cmd logs -f"
echo "To restart: $sudo_cmd $compose_cmd up -d"
echo "===================================================="
