#!/bin/bash

# EVE Online Character Tracker - Docker Setup Script
# Created by: Thrainthepain
# Last Updated: 2025-05-04 02:40:29

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display messages with color
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Display a welcome banner
display_welcome_banner() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗"
    echo -e "║                                                               ║"
    echo -e "║           ${GREEN}EVE Online Character Tracker - Docker Setup${BLUE}          ║"
    echo -e "║                                                               ║"
    echo -e "║  ${YELLOW}Created by: Thrainthepain${BLUE}                                   ║"
    echo -e "║  ${YELLOW}Last Updated: 2025-05-04 02:40:29${BLUE}                           ║"
    echo -e "║                                                               ║"
    echo -e "╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Check for Docker and Docker Compose
check_docker() {
    print_message $BLUE "Verifying Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_message $RED "Docker is not installed. Please install Docker first."
        print_message $YELLOW "Visit https://docs.docker.com/get-docker/ for installation instructions."
        exit 1
    fi
    
    # Check if Docker is running
    docker info &> /dev/null
    if [ $? -ne 0 ]; then
        print_message $RED "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    print_message $GREEN "Docker is installed and running."
    
    # Check for docker-compose command or docker compose plugin
    compose_cmd="none"
    if command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
    elif docker compose version &> /dev/null; then
        compose_cmd="docker compose"
    else
        print_message $RED "Docker Compose not found. Please install Docker Compose."
        print_message $YELLOW "Visit https://docs.docker.com/compose/install/ for installation instructions."
        exit 1
    fi
    
    print_message $GREEN "Docker Compose is installed."
    echo $compose_cmd
}

# Create required files and directories
setup_project_structure() {
    print_message $BLUE "Setting up project structure..."
    
    # Create client directory if it doesn't exist
    if [ ! -d "client" ]; then
        mkdir -p client
    fi
    
    # Create Dockerfiles if they don't exist
    if [ ! -f "client/Dockerfile" ]; then
        print_message $YELLOW "Creating client Dockerfile..."
        cat > client/Dockerfile << 'EOF'
# Stage 1: Create a minimal React build artifact
FROM node:18-alpine as build

WORKDIR /app

# Create a basic package.json
RUN echo '{\
  "name": "eve-tracker-frontend",\
  "version": "1.0.0",\
  "private": true,\
  "dependencies": {},\
  "scripts": {\
    "build": "mkdir -p build && echo \"<html><body><h1>EVE Online Character Tracker</h1><p>Frontend placeholder</p></body></html>\" > build/index.html"\
  }\
}' > package.json

# Build the simple HTML output
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy the static HTML file
COPY --from=build /app/build /usr/share/nginx/html

# Create necessary directories
RUN mkdir -p /var/www/certbot /etc/nginx/ssl /usr/share/nginx/html/custom-assets

# Create a startup script
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo 'if [ -f "/etc/nginx/conf.d/default.conf.template" ]; then' >> /docker-entrypoint.sh && \
    echo '  envsubst "\$SERVER_PROTOCOL \$FULL_DOMAIN \$BACKEND_PORT" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
EOF
    fi
    
    if [ ! -f "Dockerfile" ]; then
        print_message $YELLOW "Creating backend Dockerfile..."
        cat > Dockerfile << 'EOF'
# Base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create basic package.json
RUN echo '{\
  "name": "eve-tracker-backend",\
  "version": "1.0.0",\
  "description": "EVE Online Character Tracker Backend",\
  "main": "server/server.js",\
  "scripts": {\
    "start": "node server/server.js"\
  },\
  "dependencies": {\
    "express": "^4.17.1"\
  }\
}' > package.json

# Install dependencies
RUN npm install

# Create server directory and basic server.js file
RUN mkdir -p server public config logs backups uploads
RUN echo 'const express = require("express");\n\
const app = express();\n\
const port = process.env.PORT || 5000;\n\
\n\
app.use(express.json());\n\
\n\
// Health check endpoint\n\
app.get("/api/health", (req, res) => {\n\
  res.json({ status: "UP", message: "Service is healthy" });\n\
});\n\
\n\
// Basic API endpoint\n\
app.get("/api", (req, res) => {\n\
  res.json({ message: "EVE Online Character Tracker API is running" });\n\
});\n\
\n\
app.listen(port, () => {\n\
  console.log(`Server running on port ${port}`);\n\
});' > server/server.js

# Set permissions
RUN chmod -R 755 .

# Command to run the server
CMD ["node", "server/server.js"]
EOF
    fi
    
    # Create docker-compose file if it doesn't exist
    if [ ! -f "docker-compose.yml" ]; then
        print_message $YELLOW "Creating docker-compose.yml..."
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
      context: ./client
      dockerfile: Dockerfile
    container_name: eve-tracker-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      - REACT_APP_API_URL=http://backend:${PORT:-5000}/api
      - SERVER_PROTOCOL=${SERVER_PROTOCOL:-http}
      - FULL_DOMAIN=${FULL_DOMAIN:-localhost}
      - BACKEND_PORT=${BACKEND_PORT:-5000}
      - SSL_MODE=${SSL_MODE:-skip}
      - TZ=UTC
    ports:
      - "${FRONTEND_PORT:-80}:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf.template
      - ssl_certs:/etc/nginx/ssl
      - ./certbot/www:/var/www/certbot
    networks:
      - eve-network

networks:
  eve-network:
    driver: bridge

volumes:
  mongo_data:
  ssl_certs:
EOF
    fi
    
    # Create nginx config if it doesn't exist
    if [ ! -f "nginx.conf" ]; then
        print_message $YELLOW "Creating nginx.conf..."
        cat > nginx.conf << 'EOF'
# Nginx configuration for EVE Online Character Tracker
server {
    listen 80;
    server_name localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to the backend
    location /api/ {
        proxy_pass http://backend:${BACKEND_PORT}/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Required for Let's Encrypt certificate verification
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
    fi
    
    # Create necessary directories
    directories=(
        "logs"
        "backups"
        "uploads"
        "certbot/www"
        "client/public"
        "server"
        "config"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_message $GREEN "Created directory: $dir"
        fi
    done
    
    print_message $GREEN "Project structure setup complete."
}

# Check development prerequisites
check_development_prerequisites() {
    print_message $BLUE "Checking development prerequisites..."
    print_message $YELLOW "Note: These are only needed for local development outside Docker."
    
    # Check Node.js version
    if command -v node &> /dev/null; then
        node_version=$(node -v | tr -d 'v')
        print_message $GREEN "Node.js v${node_version} is installed."
        
        # Check if version is >= 14 without using bc
        node_major_version=$(echo "$node_version" | cut -d. -f1)
        if [ "$node_major_version" -lt 14 ]; then
            print_message $YELLOW "Warning: Node.js 14+ is recommended. Consider upgrading."
        fi
    else
        print_message $YELLOW "Node.js is not installed. This is only needed for local development."
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        npm_version=$(npm -v)
        print_message $GREEN "npm v${npm_version} is installed."
    else
        print_message $YELLOW "npm is not installed. It should be included with Node.js."
    fi
    
    # Check MongoDB version (only if installed locally)
    if command -v mongod &> /dev/null; then
        # Extract MongoDB version without using bc
        mongo_version=$(mongod --version | grep "db version" | sed 's/db version v//')
        mongo_major_version=$(echo "$mongo_version" | cut -d. -f1)
        
        print_message $GREEN "MongoDB ${mongo_version} is installed locally."
        
        if [ "$mongo_major_version" -lt 4 ]; then
            print_message $YELLOW "Warning: MongoDB 4+ is recommended. Consider upgrading."
        fi
    else
        print_message $YELLOW "MongoDB is not installed locally. Docker will use its own MongoDB instance."
    fi
}

# Setup environment file
setup_env_file() {
    print_message $BLUE "Setting up environment configuration..."
    
    if [ -f .env ]; then
        print_message $YELLOW "An existing .env file was found."
        read -p "Do you want to overwrite it? (y/n): " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            print_message $GREEN "Using existing .env file."
            return
        fi
        
        # Back up existing .env file
        backup_file=".env.backup.$(date +%Y%m%d%H%M%S)"
        cp .env "$backup_file"
        print_message $GREEN "Existing .env file backed up to $backup_file"
    fi
    
    print_message $GREEN "========================================="
    print_message $GREEN "EVE Online Character Tracker Configuration"
    print_message $GREEN "========================================="
    
    # Prompt for ESI/API information
    print_message $BLUE "EVE Online ESI Application Details"
    print_message $YELLOW "Create an application at https://developers.eveonline.com if needed."
    read -p "Enter your EVE ESI Client ID (or leave blank for development): " eve_client_id
    read -p "Enter your EVE ESI Client Secret (or leave blank for development): " eve_client_secret
    read -p "Enter your Developer Email (required by EVE): " dev_email
    
    # Set default values if empty
    eve_client_id=${eve_client_id:-"development_client_id"}
    eve_client_secret=${eve_client_secret:-"development_client_secret"}
    dev_email=${dev_email:-"dev@example.com"}
    
    # Generate a random session secret
    session_secret=$(head -c 32 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 32 2>/dev/null || openssl rand -base64 32 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 32 2>/dev/null || echo "secureSessionSecret$(date +%s)")
    
    # Basic configuration with defaults
    read -p "Enter Website Name (default: EVE Character Tracker): " website_name
    website_name=${website_name:-"EVE Character Tracker"}
    
    # Protocol selection (fixed to work without select which might not be available in all shells)
    print_message $BLUE "Select Protocol:"
    print_message $BLUE "1) HTTP"
    print_message $BLUE "2) HTTPS"
    read -p "Enter your choice (1-2, default: 1): " protocol_choice
    
    if [ "$protocol_choice" = "2" ]; then
        protocol="https"
    else
        protocol="http"
    fi
    
    # Docker ports configuration
    read -p "Enter Frontend Port (default: 80): " frontend_port
    frontend_port=${frontend_port:-"80"}
    
    read -p "Enter Backend Port (default: 5000): " backend_port
    backend_port=${backend_port:-"5000"}
    
    # MongoDB password generation with better fallbacks
    mongo_password=$(head -c 16 /dev/urandom 2>/dev/null | base64 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 16 2>/dev/null || openssl rand -base64 16 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 16 2>/dev/null || echo "mongopwd$(date +%s)")
    
    # Set SSL mode based on protocol
    if [ "$protocol" = "https" ]; then
        ssl_mode="letsencrypt"
    else
        ssl_mode="skip"
    fi
    
    # Create the .env file
    cat > .env << EOF
# EVE Online Character Tracker Environment Configuration
# Generated on $(date)

# Server Configuration
PORT=${backend_port}
NODE_ENV=production
SESSION_SECRET=${session_secret}

# Database Configuration
MONGO_URI=mongodb://root:${mongo_password}@mongodb:27017/eve-tracker?authSource=admin
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=${mongo_password}

# URL Configuration
SERVER_PROTOCOL=${protocol}
SERVER_DOMAIN=localhost
FULL_DOMAIN=localhost
CLIENT_URL=${protocol}://localhost:${frontend_port}
SERVER_URL=${protocol}://localhost:${backend_port}

# Docker Configuration
FRONTEND_PORT=${frontend_port}
BACKEND_PORT=${backend_port}

# EVE Online API Configuration
EVE_CLIENT_ID=${eve_client_id}
EVE_CLIENT_SECRET=${eve_client_secret}
DEV_EMAIL=${dev_email}

# Application Settings
WEBSITE_NAME="${website_name}"
DATA_REFRESH_INTERVAL=30

# SSL Configuration
SSL_MODE=${ssl_mode}
LETSENCRYPT_EMAIL=${dev_email}

# Worker Settings
BACKUP_RETENTION_DAYS=7
BACKUP_TIME=2:00
TOKEN_REFRESH_INTERVAL=15
DB_MAINTENANCE_TIME=3:00
EOF
    
    print_message $GREEN "Environment configuration saved to .env file."
}

# Start Docker containers
start_containers() {
    print_message $BLUE "Starting EVE Tracker Docker containers..."
    
    # Get the appropriate compose command
    compose_cmd=$(check_docker)
    
    # Determine if we need sudo (for Linux)
    sudo_cmd=""
    if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
        sudo_cmd="sudo"
    fi
    
    # Create Docker network
    $sudo_cmd docker network inspect eve-network &> /dev/null || $sudo_cmd docker network create eve-network &> /dev/null
    
    # Start containers
    if [ "$1" = "rebuild" ]; then
        print_message $BLUE "Rebuilding containers..."
        $sudo_cmd $compose_cmd up -d --build --force-recreate
    fi
    
    if [ $? -ne 0 ]; then
        print_message $RED "Failed to start containers. Please check docker logs for details."
        exit 1
    fi
    
    # Wait a moment for containers to initialize
    print_message $YELLOW "Waiting for containers to initialize..."
    sleep 5
    
    # Load environment variables
    if [ -f .env ]; then
        # Extract needed variables
        FRONTEND_PORT=$(grep "^FRONTEND_PORT=" .env | cut -d= -f2- || echo "80")
        BACKEND_PORT=$(grep "^BACKEND_PORT=" .env | cut -d= -f2- || echo "5000") 
    else
        FRONTEND_PORT=80
        BACKEND_PORT=5000
    fi
    
    print_message $GREEN "EVE Online Character Tracker is now running!"
    print_message $GREEN "Frontend: http://localhost:${FRONTEND_PORT}"
    print_message $GREEN "Backend API: http://localhost:${BACKEND_PORT}/api"
    
    print_message $YELLOW "\nTo stop the application, run: $sudo_cmd $compose_cmd down"
    print_message $YELLOW "To view logs, run: $sudo_cmd $compose_cmd logs -f"
}

# Main function
main() {
    display_welcome_banner
    
    # Check Docker installation
    check_docker
    
    # Setup project structure (creates missing files and directories)
    setup_project_structure
    
    # Check development prerequisites
    check_development_prerequisites
    
    # Setup environment file
    setup_env_file
    
    # Start containers
    start_containers $1
}

# Parse command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: ./docker-run.sh [OPTIONS]"
    echo "Options:"
    echo "  --rebuild, -r    Rebuild all containers"
    echo "  --help, -h       Show this help message"
    exit 0
fi

# Convert short options to long options
if [ "$1" = "-r" ]; then
    main "rebuild"
else
    main "$1"
fi
