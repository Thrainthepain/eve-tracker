#!/bin/bash

# EVE Online Character Tracker - Docker Setup Script
# Created by: Thrainthepain
# Last Updated: 2025-05-04 04:08:02

# Basic script to show it works
echo "Starting Docker setup script..."

# Check if Docker is installed
if command -v docker >/dev/null 2>&1; then
  echo "Docker is installed."
else
  echo "ERROR: Docker is not installed. Please install Docker first."
  exit 1
fi

# Check if Docker Compose is installed
if command -v docker-compose >/dev/null 2>&1; then
  echo "Docker Compose standalone is installed."
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin is installed."
  COMPOSE_CMD="docker compose"
else
  echo "ERROR: Docker Compose not found. Please install Docker Compose."
  exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running. Please start Docker and try again."
  exit 1
fi

# Create basic directories
echo "Creating necessary directories..."
mkdir -p logs backups uploads certbot/www client/public/custom-assets

# Simple docker-compose.yml file
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
      - MONGO_INITDB_ROOT_USERNAME=root
      - MONGO_INITDB_ROOT_PASSWORD=password
      - TZ=UTC
    networks:
      - eve-network

  backend:
    image: nginx:alpine
    container_name: eve-tracker-backend
    restart: unless-stopped
    depends_on:
      - mongodb
    environment:
      - TZ=UTC
    ports:
      - "5000:80"
    volumes:
      - ./logs:/var/log/nginx
    networks:
      - eve-network

  frontend:
    image: nginx:alpine
    container_name: eve-tracker-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      - TZ=UTC
    ports:
      - "80:80"
    volumes:
      - ./logs:/var/log/nginx
    networks:
      - eve-network

networks:
  eve-network:
    driver: bridge

volumes:
  mongo_data:
EOF

# Try to start Docker containers
echo "Starting Docker containers..."
sudo_cmd=""
if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
  echo "Docker socket not writable. Using sudo."
  sudo_cmd="sudo"
fi

# Create network if it doesn't exist
$sudo_cmd docker network create eve-network 2>/dev/null || true

# Start containers
$sudo_cmd $COMPOSE_CMD up -d

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start containers."
  exit 1
fi

echo "Success! Containers are running."
echo "Frontend available at: http://localhost"
echo "Backend available at: http://localhost:5000"
echo ""
echo "To stop the application: $sudo_cmd $COMPOSE_CMD down"
