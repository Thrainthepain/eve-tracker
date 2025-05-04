#!/bin/bash

# EVE Online Character Tracker - Modern Docker Setup Script
# Created by: Thrainthepaindocker
# Last Updated: 2025-05-04 14:57:40

# Function for styled output
echo_style() {
  echo "$1"
}

# Check Docker and Docker Compose
check_docker() {
  echo_style "Checking for Docker and Docker Compose..."
  
  # Check Docker installation
  if ! command -v docker &> /dev/null; then
    echo_style "Docker is not installed. Installing Docker..."
    bash setup-docker.sh
    if [ $? -ne 0 ]; then
      echo_style "Failed to install Docker. Please install manually."
      exit 1
    fi
  fi
  
  # Check Docker Compose v2
  if ! docker compose version &> /dev/null; then
    echo_style "Docker Compose V2 plugin not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    if ! docker compose version &> /dev/null; then
      echo_style "Failed to install Docker Compose plugin. Please install manually."
      exit 1
    fi
  fi
  
  echo_style "Docker and Docker Compose are installed."
}

# Create necessary directories
create_directories() {
  echo_style "Creating necessary directories..."
  dirs=("logs" "backups" "uploads" "certbot/www" "client/public/custom-assets")
  
  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir" && echo_style "Created directory: $dir" || {
        echo_style "Error creating directory $dir. Trying with sudo..."
        sudo mkdir -p "$dir" || echo_style "Failed to create directory: $dir"
      }
    fi
  done
  
  # Set permissions
  chmod -R 755 logs backups uploads || sudo chmod -R 755 logs backups uploads
}

# Create .env file if it doesn't exist
setup_env() {
  if [ ! -f .env ]; then
    echo_style "Creating .env file..."
    
    # Generate secure random strings
    session_secret=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
    mongo_password=$(head -c 16 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)
    
    # Get user input for required fields
    read -p "Enter EVE ESI Client ID: " eve_client_id
    read -p "Enter EVE ESI Client Secret: " eve_client_secret
    read -p "Enter Developer Email: " dev_email
    
    # Create .env file
    cat > .env << EOF
# EVE Online Character Tracker Environment Configuration
# Generated on $(date)

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
    echo_style ".env file created."
  else
    echo_style "Using existing .env file."
  fi
}

# Create or update Docker network
setup_network() {
  echo_style "Setting up Docker network..."
  sudo_cmd=""
  
  if [ "$(id -u)" -ne 0 ] && [ -e "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  # Remove network if it exists
  if $sudo_cmd docker network inspect eve-network &> /dev/null; then
    echo_style "Removing existing network..."
    $sudo_cmd docker network rm eve-network &> /dev/null || echo_style "Network in use, keeping existing network."
  fi
  
  # Create network
  $sudo_cmd docker network create eve-network &> /dev/null || echo_style "Network already exists or creation failed."
}

# Start containers
start_containers() {
  echo_style "Starting Docker containers..."
  sudo_cmd=""
  
  if [ "$(id -u)" -ne 0 ] && [ -e "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  rebuild=""
  if [ "$1" = "rebuild" ]; then
    rebuild="--build --force-recreate"
    echo_style "Performing clean rebuild of all containers..."
  fi
  
  # Start containers with modern Docker Compose
  $sudo_cmd docker compose up -d $rebuild
  
  # Check if startup was successful
  if [ $? -ne 0 ]; then
    echo_style "Failed to start containers. See logs above for details."
    exit 1
  fi
  
  # Wait for containers to start
  echo_style "Waiting for containers to initialize..."
  sleep 10
  
  # Check container status
  running_count=$($sudo_cmd docker ps --filter name=eve-tracker --format '{{.Names}}' | wc -l)
  if [ "$running_count" -lt 3 ]; then
    echo_style "Not all containers are running. Check logs with 'docker compose logs'."
    exit 1
  fi
  
  echo_style "All containers are running successfully!"
}

# Show connection information
show_connection_info() {
  # Get info from .env
  if [ -f .env ]; then
    server_protocol=$(grep "^SERVER_PROTOCOL=" .env | cut -d= -f2-)
    full_domain=$(grep "^FULL_DOMAIN=" .env | cut -d= -f2-)
    frontend_port=$(grep "^FRONTEND_PORT=" .env | cut -d= -f2-)
    backend_port=$(grep "^BACKEND_PORT=" .env | cut -d= -f2-)
  else
    server_protocol="http"
    full_domain="localhost"
    frontend_port="80"
    backend_port="5000"
  fi
  
  echo_style "========================================"
  echo_style "EVE Online Character Tracker is running!"
  echo_style "========================================"
  echo_style "Frontend: ${server_protocol}://${full_domain}:${frontend_port}"
  echo_style "Backend API: ${server_protocol}://${full_domain}:${backend_port}/api"
  echo_style ""
  echo_style "Management commands:"
  echo_style "  docker compose down               - Stop all containers"
  echo_style "  docker compose logs -f            - View logs"
  echo_style "  docker compose restart            - Restart all containers"
  echo_style "========================================"
}

# Main function
main() {
  echo_style "EVE Online Character Tracker Setup"
  echo_style "Created by: Thrainthepaindocker"
  echo_style "Last Updated: 2025-05-04 14:57:40"
  echo_style "========================================"
  
  # Check docker installation
  check_docker
  
  # Create directories
  create_directories
  
  # Setup environment
  setup_env
  
  # Setup network
  setup_network
  
  # Start containers
  start_containers "$1"
  
  # Show connection info
  show_connection_info
}

# Parse command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: bash docker-run.sh [OPTIONS]"
  echo "Options:"
  echo "  --rebuild, -r    Rebuild all containers"
  echo "  --help, -h       Show this help message"
  exit 0
fi

if [ "$1" = "--rebuild" ] || [ "$1" = "-r" ]; then
  main "rebuild"
else
  main
fi