#!/bin/bash

# EVE Online Character Tracker - Docker Setup Script
# Created by: Thrainthepainthe
# Last Updated: 2025-05-04 03:54:58

# Reset and clear terminal
clear

# Color codes for better readability - Using plain text fallbacks for compatibility
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN=''
  YELLOW=''
  BLUE=''
  RED=''
  NC=''
fi

# Function to display messages with color - Compatible with all bash versions
print_message() {
  local color="$1"
  local message="$2"
  echo "${color}${message}${NC}"
}

# Check for required commands and install if missing
install_prerequisites() {
  print_message "$BLUE" "Checking for required prerequisites..."
  
  # Array of required commands
  required_cmds=("docker" "curl" "wget" "grep" "awk")
  
  missing_cmds=()
  for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
      missing_cmds+=("$cmd")
    else
      print_message "$GREEN" "$cmd is already installed"
    fi
  done
  
  # If any commands are missing, try to install them (Ubuntu-specific)
  if [ ${#missing_cmds[@]} -gt 0 ]; then
    print_message "$YELLOW" "Some required tools are missing: ${missing_cmds[*]}"
    print_message "$YELLOW" "Attempting to install missing prerequisites..."
    
    # Check if apt is available (Ubuntu)
    if command -v apt-get > /dev/null 2>&1; then
      print_message "$BLUE" "Detected Ubuntu/Debian-based system"
      
      print_message "$YELLOW" "Updating package lists..."
      sudo apt-get update -q
      
      for cmd in "${missing_cmds[@]}"; do
        print_message "$YELLOW" "Installing $cmd..."
        case $cmd in
          docker)
            print_message "$YELLOW" "Docker not found. Installing Docker..."
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update -q
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo usermod -aG docker "$USER"
            print_message "$YELLOW" "Please log out and back in to apply Docker group changes"
            print_message "$YELLOW" "Then run this script again."
            exit 0
            ;;
          *)
            sudo apt-get install -y "$cmd"
            ;;
        esac
      done
    else
      print_message "$RED" "Cannot automatically install missing prerequisites."
      print_message "$RED" "Please install the following manually: ${missing_cmds[*]}"
      exit 1
    fi
  fi
  
  # Check Docker Compose
  compose_installed=0
  if command -v docker-compose > /dev/null 2>&1; then
    compose_installed=1
  elif command -v "docker" > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
    compose_installed=1
  fi
  
  if [ $compose_installed -eq 0 ]; then
    print_message "$YELLOW" "Docker Compose not found. Installing Docker Compose..."
    if command -v apt-get > /dev/null 2>&1; then
      sudo apt-get install -y docker-compose || sudo apt-get install -y docker-compose-plugin
    else
      sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    compose_installed=0
    if command -v docker-compose > /dev/null 2>&1; then
      compose_installed=1
    elif command -v "docker" > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
      compose_installed=1
    fi
    
    if [ $compose_installed -eq 0 ]; then
      print_message "$RED" "Failed to install Docker Compose. Please install it manually."
      exit 1
    fi
  fi
  
  print_message "$GREEN" "Docker Compose is installed"
}

# Check system resources
check_resources() {
  print_message "$BLUE" "Checking system resources..."
  
  # Check disk space - compatible with Ubuntu
  free_space=$(df -P . | awk 'NR==2 {print $4}')
  if [ -z "$free_space" ]; then
    print_message "$YELLOW" "Warning: Could not determine free disk space"
    free_space=0
  fi
  
  if [ "$free_space" -lt 1048576 ]; then  # Less than 1GB free
    print_message "$RED" "Not enough free disk space. Need at least 1GB."
    print_message "$RED" "Free space: $((free_space / 1024)) MB"
    exit 1
  else
    print_message "$GREEN" "Disk space: $((free_space / 1024 / 1024)) GB available"
  fi
  
  # Check memory - Fixed for all Ubuntu versions
  if [ -f /proc/meminfo ]; then
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}' 2>/dev/null || echo "0")
    
    # MemAvailable might not exist in older kernels (pre-3.14)
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}' 2>/dev/null)
    
    # If MemAvailable is not found, calculate from MemFree + Cached + Buffers (older method)
    if [ -z "$mem_available" ]; then
      mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}' 2>/dev/null || echo "0")
      mem_cached=$(grep -i "^Cached:" /proc/meminfo | awk '{print $2}' 2>/dev/null || echo "0")
      mem_buffers=$(grep Buffers /proc/meminfo | awk '{print $2}' 2>/dev/null || echo "0")
      mem_available=$((mem_free + mem_cached + mem_buffers))
    fi
    
    # Ensure mem_available is a number
    if ! [[ "$mem_available" =~ ^[0-9]+$ ]]; then
      mem_available=0
    fi
    
    # Convert to MB with safer arithmetic
    mem_available_mb=$((mem_available / 1024))
    
    if [ "$mem_available_mb" -lt 1024 ]; then
      print_message "$YELLOW" "Warning: Low memory available (${mem_available_mb}MB). Docker may run slowly."
    else
      print_message "$GREEN" "Memory: ${mem_available_mb}MB available"
    fi
  else
    print_message "$YELLOW" "Warning: Could not check memory availability (/proc/meminfo not found)"
  fi
  
  # Check if Docker can access internet (needed for pulling images)
  print_message "$BLUE" "Checking internet connectivity..."
  if ! curl -s --connect-timeout 5 https://registry-1.docker.io > /dev/null; then
    # Try HTTP if HTTPS fails (could be firewall or proxy issue)
    if ! curl -s --connect-timeout 5 http://registry-1.docker.io > /dev/null; then
      print_message "$RED" "Cannot connect to Docker Hub. Check your internet connection or firewall."
      print_message "$YELLOW" "If you're behind a proxy, make sure Docker is configured to use it."
      exit 1
    fi
  fi
  
  print_message "$GREEN" "Internet connectivity verified"
}

# Check if Docker is installed and running
check_docker() {
  print_message "$BLUE" "Verifying Docker installation..."
  
  if ! command -v docker > /dev/null 2>&1; then
    print_message "$RED" "Docker is not installed. Please install Docker first."
    exit 1
  fi
  
  # Check if Docker is running
  if ! docker info > /dev/null 2>&1; then
    print_message "$RED" "Docker is not running. Please start Docker and try again."
    print_message "$YELLOW" "On Ubuntu, run: sudo systemctl start docker"
    
    # Check if Docker service exists before trying to start it
    if command -v systemctl > /dev/null 2>&1 && systemctl list-unit-files | grep -q docker; then
      print_message "$YELLOW" "Attempting to start Docker service..."
      sudo systemctl start docker
      
      # Wait a moment and check again
      sleep 3
      if ! docker info > /dev/null 2>&1; then
        print_message "$RED" "Failed to start Docker service."
        exit 1
      else
        print_message "$GREEN" "Successfully started Docker service."
      fi
    else
      exit 1
    fi
  fi
  
  # Check Docker service is enabled to auto-start - Ubuntu specific
  if command -v systemctl > /dev/null 2>&1; then
    if ! systemctl is-enabled docker > /dev/null 2>&1; then
      print_message "$YELLOW" "Docker service is not enabled to start at boot."
      print_message "$YELLOW" "To enable Docker to start at boot: sudo systemctl enable docker"
    fi
  fi
  
  # Check for docker-compose command or docker compose plugin
  compose_cmd="none"
  if command -v docker-compose > /dev/null 2>&1; then
    compose_cmd="docker-compose"
    print_message "$GREEN" "Docker Compose standalone is installed."
  elif docker compose version > /dev/null 2>&1; then
    compose_cmd="docker compose"
    print_message "$GREEN" "Docker Compose plugin is installed."
  else
    print_message "$RED" "Docker Compose not found. Please install Docker Compose."
    exit 1
  fi
  
  echo "$compose_cmd"
}

# Check if ports are in use
check_ports() {
  print_message "$BLUE" "Checking if required ports are available..."
  
  # Get port values from .env or use defaults
  local frontend_port=80
  local backend_port=5000
  
  if [ -f .env ]; then
    frontend_port=$(grep "^FRONTEND_PORT=" .env | cut -d= -f2- || echo "80")
    backend_port=$(grep "^BACKEND_PORT=" .env | cut -d= -f2- || echo "5000") 
  fi
  
  local ports_in_use=""
  
  # Function to check if a port is in use
  port_in_use() {
    local port=$1
    if command -v lsof > /dev/null 2>&1; then
      lsof -i :"$port" -sTCP:LISTEN > /dev/null 2>&1
      return $?
    elif command -v netstat > /dev/null 2>&1; then
      netstat -tuln | grep -q ":$port "
      return $?
    elif command -v ss > /dev/null 2>&1; then
      ss -tuln | grep -q ":$port "
      return $?
    else
      # If we can't check, assume it's free
      return 1
    fi
  }
  
  # Check frontend port
  if port_in_use "$frontend_port"; then
    ports_in_use="$frontend_port (frontend)"
  fi
  
  # Check backend port
  if port_in_use "$backend_port"; then
    if [ -n "$ports_in_use" ]; then
      ports_in_use="$ports_in_use, $backend_port (backend)"
    else
      ports_in_use="$backend_port (backend)"
    fi
  fi
  
  # If ports are in use, alert the user
  if [ -n "$ports_in_use" ]; then
    print_message "$YELLOW" "Warning: The following ports are already in use: $ports_in_use"
    print_message "$YELLOW" "This will conflict with the Docker containers."
    print_message "$YELLOW" "Options:"
    print_message "$YELLOW" "1. Stop the services using these ports"
    print_message "$YELLOW" "2. Change the ports in the .env file"
    print_message "$YELLOW" "3. Continue anyway (may cause errors)"
    
    read -p "Please choose an option (1-3): " port_option
    
    case $port_option in
      1)
        print_message "$YELLOW" "Please stop the services and run this script again."
        exit 0
        ;;
      2)
        if [ -f .env ]; then
          print_message "$YELLOW" "Please edit your .env file to change the ports."
        else
          print_message "$YELLOW" "You will be prompted to choose different ports during setup."
        fi
        ;;
      *)
        print_message "$YELLOW" "Continuing despite port conflicts. This may cause errors."
        ;;
    esac
  else
    print_message "$GREEN" "All required ports are available."
  fi
}

# Verify required files exist
check_files() {
  print_message "$BLUE" "Checking for required project files..."
  
  missing_files=0
  required_files=(
    "Dockerfile"
    "client/Dockerfile"
    "docker-compose.yml"
    "nginx.conf"
  )
  
  optional_files=(
    ".env.example"
    "package.json"
    "client/package.json"
  )
  
  for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
      print_message "$RED" "Required file missing: $file"
      missing_files=1
    else
      print_message "$GREEN" "Found: $file"
    fi
  done
  
  for file in "${optional_files[@]}"; do
    if [ ! -f "$file" ]; then
      print_message "$YELLOW" "Optional file missing: $file"
    else
      print_message "$GREEN" "Found: $file"
    fi
  done
  
  if [ $missing_files -eq 1 ]; then
    print_message "$RED" "Required files are missing. Please make sure you're in the correct directory."
    print_message "$RED" "Current directory: $(pwd)"
    exit 1
  fi
}

# Function to check for existing .env file
check_env_file() {
  if [ -f .env ]; then
    print_message "$YELLOW" "WARNING: An existing .env file was found."
    print_message "$YELLOW" "This script requires a fresh .env configuration."
    print_message "$YELLOW" "Options:"
    print_message "$YELLOW" "1. Delete the existing .env file manually and run this script again."
    print_message "$YELLOW" "2. Let this script back up and delete the .env file (recommended)."
    print_message "$YELLOW" "3. Exit without making changes."
    
    read -p "Please choose an option (1-3): " env_option
    
    case $env_option in
      1)
        print_message "$YELLOW" "Please delete the .env file manually and run this script again."
        exit 0
        ;;
      2)
        # Back up the existing .env file
        backup_file=".env.backup.$(date +%Y%m%d%H%M%S)"
        print_message "$BLUE" "Backing up existing .env file to $backup_file..."
        cp .env "$backup_file"
        
        # Remove the existing .env file
        print_message "$BLUE" "Removing existing .env file..."
        rm .env
        ;;
      *)
        print_message "$YELLOW" "Exiting without making changes."
        exit 0
        ;;
    esac
  fi
}

# Function to create or update .env file
setup_env_file() {
  print_message "$BLUE" "Creating new .env file..."
  
  # Check if .env.example exists
  if [ ! -f .env.example ]; then
    print_message "$RED" ".env.example file not found. Creating a basic .env file..."
    touch .env
  else
    cp .env.example .env
  fi
  
  print_message "$GREEN" "========================================="
  print_message "$GREEN" "EVE Online Character Tracker Configuration"
  print_message "$GREEN" "========================================="
  
  # Prompt for ESI/API information
  read -p "Enter your EVE ESI Client ID: " eve_client_id
  read -p "Enter your EVE ESI Client Secret: " eve_client_secret
  read -p "Enter your Developer Email (required by EVE): " dev_email
  
  # Generate a random session secret - Ubuntu compatible with better fallback
  session_secret=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -dc 'A-Za-z0-9' | head -c 32 || echo "fallbacksecret$(date +%s)")
  
  # Prompt for website name and server settings
  read -p "Enter Website Name (default: EVE Character Tracker): " website_name
  website_name=${website_name:-"EVE Character Tracker"}
  
  # Protocol selection
  print_message "$BLUE" "Select Protocol:"
  echo "1) HTTP"
  echo "2) HTTPS"
  read -p "Enter choice (1-2, default: 1): " protocol_choice
  
  case $protocol_choice in
    2) protocol="https" ;;
    *) protocol="http" ;;
  esac
  
  # Domain configuration
  read -p "Enter Server Domain (default: localhost): " server_domain
  server_domain=${server_domain:-"localhost"}
  
  # Subdomain configuration
  read -p "Enter Subdomain (leave blank for none): " subdomain
  
  # Construct full domain
  if [ -n "$subdomain" ]; then
    full_domain="${subdomain}.${server_domain}"
  else
    full_domain="${server_domain}"
  fi
  
  # Docker Desktop specific settings
  print_message "$BLUE" "Docker Configuration:"
  
  # Check if ports are in use first
  local default_frontend_port=80
  local default_backend_port=5000
  
  # Check frontend port and suggest alternative if in use
  if nc -z localhost $default_frontend_port 2>/dev/null || lsof -i :$default_frontend_port >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$default_frontend_port "; then
    print_message "$YELLOW" "Warning: Default frontend port $default_frontend_port is already in use."
    print_message "$YELLOW" "Please choose a different port."
    default_frontend_port=8080
  fi
  
  # Check backend port and suggest alternative if in use
  if nc -z localhost $default_backend_port 2>/dev/null || lsof -i :$default_backend_port >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$default_backend_port "; then
    print_message "$YELLOW" "Warning: Default backend port $default_backend_port is already in use."
    print_message "$YELLOW" "Please choose a different port."
    default_backend_port=5050
  fi
  
  read -p "Enter Frontend Port (default: ${default_frontend_port}): " frontend_port
  frontend_port=${frontend_port:-"$default_frontend_port"}
  
  read -p "Enter Backend Port (default: ${default_backend_port}): " backend_port
  backend_port=${backend_port:-"$default_backend_port"}
  
  # Generate MongoDB password - Ubuntu compatible with better fallback
  mongo_password=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 | tr -dc 'A-Za-z0-9' | head -c 16 || echo "mongopwd$(date +%s)")
  
  # Set SSL_MODE properly - FIXED TERNARY OPERATOR
  if [ "$protocol" = "https" ]; then
    ssl_mode="letsencrypt"
  else
    ssl_mode="skip"
  fi
  
  # Write all configuration to .env file - PROPERLY ESCAPED
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
SERVER_DOMAIN=${server_domain}
SERVER_SUBDOMAIN=${subdomain}
FULL_DOMAIN=${full_domain}
CLIENT_URL=${protocol}://${full_domain}:${frontend_port}
SERVER_URL=${protocol}://${full_domain}:${backend_port}

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
  
  print_message "$GREEN" "Configuration saved to .env file."
  
  # If using HTTPS, prompt for SSL certificate setup
  if [ "$protocol" = "https" ]; then
    print_message "$BLUE" "You've selected HTTPS. You'll need SSL certificates for your domain."
    print_message "$BLUE" "Options:"
    print_message "$BLUE" "1. Use Let's Encrypt (automatic)"
    print_message "$BLUE" "2. Provide your own certificates"
    print_message "$BLUE" "3. Skip for now (you'll need to configure SSL manually later)"
    
    read -p "Choose option (1-3): " ssl_option
    
    case $ssl_option in
      1)
        echo "SSL_MODE=letsencrypt" >> .env
        read -p "Enter email for Let's Encrypt registration: " le_email
        echo "LETSENCRYPT_EMAIL=$le_email" >> .env
        ;;
      2)
        echo "SSL_MODE=custom" >> .env
        print_message "$YELLOW" "Custom certificate setup will be required after container startup."
        ;;
      *)
        echo "SSL_MODE=skip" >> .env
        print_message "$YELLOW" "You've chosen to skip SSL setup. HTTPS won't work until certificates are configured."
        ;;
    esac
  fi
}

# Create necessary directories
create_directories() {
  print_message "$BLUE" "Creating necessary directories..."
  
  # List of directories to create
  directories=(
    "logs"
    "backups"
    "uploads"
    "certbot/www"
    "client/public/custom-assets"
  )
  
  for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
      if ! mkdir -p "$dir" 2>/dev/null; then
        print_message "$YELLOW" "Warning: Could not create directory $dir. Trying with sudo..."
        if ! sudo mkdir -p "$dir" 2>/dev/null; then
          print_message "$RED" "Failed to create directory $dir even with sudo."
        else
          print_message "$GREEN" "Created directory with sudo: $dir"
        fi
      else
        print_message "$GREEN" "Created directory: $dir"
      fi
    else
      print_message "$GREEN" "Directory already exists: $dir"
    fi
  done
  
  # Ensure proper permissions - Ubuntu compatible
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ]; then
    # If we're not root, use sudo for permission changes
    sudo_cmd="sudo"
  fi
  
  $sudo_cmd chmod -R 755 logs backups uploads 2>/dev/null || true
  
  # Fix ownership if directories were created with sudo
  if [ -n "$sudo_cmd" ]; then
    $sudo_cmd chown -R "$USER:$USER" logs backups uploads 2>/dev/null || true
  fi
}

# Fix Docker network issues (common for Docker Desktop and Ubuntu)
fix_network_issues() {
  print_message "$BLUE" "Checking for Docker network issues..."
  
  # Check Docker socket permissions first
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    print_message "$YELLOW" "Docker socket is not writable by current user. Using sudo for Docker commands."
    sudo_cmd="sudo"
  fi
  
  # Check if eve-network exists, if yes remove it to prevent conflicts
  if $sudo_cmd docker network inspect eve-network > /dev/null 2>&1; then
    print_message "$YELLOW" "Found existing eve-network, removing to prevent conflicts..."
    $sudo_cmd docker network rm eve-network > /dev/null 2>&1
    
    # Verify the network was actually removed (sometimes doesn't due to running containers)
    if $sudo_cmd docker network inspect eve-network > /dev/null 2>&1; then
      print_message "$RED" "Warning: Could not remove existing eve-network."
      print_message "$YELLOW" "It may be in use by running containers. Consider stopping them first:"
      print_message "$YELLOW" "$sudo_cmd docker container ls --filter network=eve-network -q | xargs $sudo_cmd docker container stop"
      
      read -p "Attempt to stop containers using the network? (y/n): " stop_option
      if [[ "$stop_option" == "y" || "$stop_option" == "Y" ]]; then
        container_ids=$($sudo_cmd docker container ls --filter network=eve-network -q)
        if [ -n "$container_ids" ]; then
          $sudo_cmd docker container stop $container_ids
          $sudo_cmd docker network rm eve-network > /dev/null 2>&1
        fi
      fi
    fi
  fi
  
  # Create fresh network
  print_message "$BLUE" "Creating fresh Docker network..."
  $sudo_cmd docker network create eve-network > /dev/null 2>&1
  
  if [ $? -ne 0 ]; then
    print_message "$RED" "Failed to create Docker network. Check Docker settings."
    return 1
  else
    print_message "$GREEN" "Created Docker network: eve-network"
    return 0
  fi
}

# Function to generate/update docker-compose.yml with proper port configuration
update_compose_file() {
  if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.bak
    print_message "$BLUE" "Backing up docker-compose.yml to docker-compose.yml.bak"
    
    # Fix the port mapping issue
    # For HTTP mode: Only port 80 exposed
    # For HTTPS mode: Both port 80 and 443 exposed
    
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  mongodb:
    image: mongo:4.4
    container_name: eve-tracker-mongodb
    volumes:
      - mongo_data:/data/db
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=\${MONGO_INITDB_ROOT_USERNAME:-root}
      - MONGO_INITDB_ROOT_PASSWORD=\${MONGO_INITDB_ROOT_PASSWORD:-password}
      # Add timezone setting for Ubuntu
      - TZ=UTC
    networks:
      - eve-network
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: eve-tracker-backend
    restart: unless-stopped
    depends_on:
      - mongodb
    environment:
      - PORT=\${PORT:-5000}
      - MONGO_URI=\${MONGO_URI}
      - CLIENT_URL=\${CLIENT_URL:-http://localhost}
      - SERVER_URL=\${SERVER_URL:-http://localhost:5000}
      - EVE_CLIENT_ID=\${EVE_CLIENT_ID}
      - EVE_CLIENT_SECRET=\${EVE_CLIENT_SECRET}
      - SESSION_SECRET=\${SESSION_SECRET}
      - NODE_ENV=\${NODE_ENV:-production}
      - WEBSITE_NAME=\${WEBSITE_NAME}
      # Ubuntu TimeZone Support
      - TZ=UTC
    ports:
      - "\${BACKEND_PORT:-5000}:\${PORT:-5000}"
    volumes:
      - ./logs:/app/logs
      - ./backups:/app/backups
      - ./uploads:/app/uploads
    networks:
      - eve-network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:\${PORT:-5000}/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  frontend:
    build:
      context: .
      dockerfile: client/Dockerfile
    container_name: eve-tracker-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      - SERVER_PROTOCOL=\${SERVER_PROTOCOL:-http}
      - FULL_DOMAIN=\${FULL_DOMAIN:-localhost}
      - BACKEND_PORT=\${BACKEND_PORT:-5000}
      - SSL_MODE=\${SSL_MODE:-skip}
      # Ubuntu TimeZone Support
      - TZ=UTC
    ports:
      - "\${FRONTEND_PORT:-80}:80"
      # Fixed port mapping for port 443
      - "443:443"
    networks:
      - eve-network
    volumes:
      - ./client/public:/usr/share/nginx/html/custom-assets
      - ./nginx.conf:/etc/nginx/conf.d/default.conf.template
      - ssl_certs:/etc/nginx/ssl
      - ./certbot/www:/var/www/certbot
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 5s

  certbot:
    image: certbot/certbot
    container_name: eve-tracker-certbot
    profiles: ["ssl"]
    environment:
      - SSL_MODE=\${SSL_MODE:-skip}
      - LETSENCRYPT_EMAIL=\${LETSENCRYPT_EMAIL:-admin@example.com}
      - DOMAIN=\${FULL_DOMAIN:-localhost}
    volumes:
      - ssl_certs:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    command: >
      sh -c "if [ \"\$\${SSL_MODE}\" = \"letsencrypt\" ]; then 
              certbot certonly --webroot -w /var/www/certbot --email \$\${LETSENCRYPT_EMAIL} --agree-tos --no-eff-email -d \$\${DOMAIN} || echo \"SSL setup failed or not needed\"; 
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
    
    print_message "$GREEN" "Updated docker-compose.yml with fixed port configuration."
  else
    print_message "$RED" "docker-compose.yml not found. Cannot update."
  fi
}

# Function to start Docker containers
start_containers() {
  print_message "$BLUE" "Building and starting EVE Tracker containers..."
  
  # Get the appropriate compose command
  compose_cmd=$(check_docker)
  
  # Check for sudo requirements on Ubuntu
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    print_message "$YELLOW" "Docker socket is not writable by current user. Using sudo for Docker commands."
    sudo_cmd="sudo"
  fi
  
  # Update compose file to fix port issues
  update_compose_file
  
  # Check if we need to force pull images
  if [ "$1" = "rebuild" ]; then
    print_message "$BLUE" "Force pulling latest images..."
    $sudo_cmd $compose_cmd pull
  fi
  
  # Start containers
  print_message "$BLUE" "Starting containers with $compose_cmd..."
  if [ "$1" = "rebuild" ]; then
    $sudo_cmd $compose_cmd up -d --build --force-recreate
  else
    $sudo_cmd $compose_cmd up -d
  fi
  
  # Check if containers started successfully
  if [ $? -ne 0 ]; then
    print_message "$RED" "Failed to start containers. Please check docker logs for details."
    print_message "$YELLOW" "Running diagnostic commands..."
    
    print_message "$BLUE" "Docker Compose Logs:"
    $sudo_cmd $compose_cmd logs
    
    print_message "$BLUE" "Running containers:"
    $sudo_cmd docker ps
    
    exit 1
  fi
  
  # Check if containers are actually running - with retry
  max_retries=3
  retry_count=0
  expected_containers=3 # mongodb, backend, frontend
  running_containers=0
  
  while [ $retry_count -lt $max_retries ]; do
    sleep 5
    running_containers=$($sudo_cmd docker ps --format '{{.Names}}' 2>/dev/null | grep -c "eve-tracker" || echo 0)
    
    if [ $running_containers -ge $expected_containers ]; then
      break
    fi
    
    print_message "$YELLOW" "Not all containers are running yet. Waiting (attempt $((retry_count+1))/$max_retries)..."
    retry_count=$((retry_count+1))
  done
  
  if [ $running_containers -lt $expected_containers ]; then
    print_message "$RED" "Not all containers are running. Expected $expected_containers but found $running_containers."
    print_message "$YELLOW" "Running containers:"
    $sudo_cmd docker ps
    print_message "$YELLOW" "Checking container logs for errors..."
    
    containers=("eve-tracker-mongodb" "eve-tracker-backend" "eve-tracker-frontend")
    for container in "${containers[@]}"; do
      if ! $sudo_cmd docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$container"; then
        print_message "$RED" "$container is not running. Logs:"
        $sudo_cmd docker logs "$container" || true
      fi
    done
    
    exit 1
  fi
  
  print_message "$GREEN" "All containers are running successfully!"
}

# Verify application is working
verify_application() {
  print_message "$BLUE" "Verifying application is working..."
  
  # Ubuntu-compatible way to read env file - FIXED ENV EXTRACTION
  if [ -f .env ]; then
    # Extract needed variables carefully with grep
    SERVER_PROTOCOL=$(grep "^SERVER_PROTOCOL=" .env | cut -d= -f2- | tr -d '\r' || echo "http")
    FULL_DOMAIN=$(grep "^FULL_DOMAIN=" .env | cut -d= -f2- | tr -d '\r' || echo "localhost")
    BACKEND_PORT=$(grep "^BACKEND_PORT=" .env | cut -d= -f2- | tr -d '\r' || echo "5000")
    FRONTEND_PORT=$(grep "^FRONTEND_PORT=" .env | cut -d= -f2- | tr -d '\r' || echo "80")
  else
    # Default values if .env doesn't exist
    SERVER_PROTOCOL="http"
    FULL_DOMAIN="localhost"
    BACKEND_PORT="5000"
    FRONTEND_PORT="80"
  fi
  
  # Wait a bit for services to fully start
  print_message "$YELLOW" "Waiting for services to initialize (10 seconds)..."
  sleep 10
  
  # Check for sudo requirements
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  # Check if backend API is accessible
  backend_url="${SERVER_PROTOCOL}://${FULL_DOMAIN}:${BACKEND_PORT}/api/health"
  print_message "$BLUE" "Checking backend health at: $backend_url"
  
  if curl -s --connect-timeout 5 "$backend_url" | grep -q "status\|healthy\|UP"; then
    print_message "$GREEN" "Backend API is accessible!"
  else
    print_message "$RED" "Backend API is not responding. Checking container logs:"
    $sudo_cmd docker logs eve-tracker-backend
    
    print_message "$YELLOW" "This might be normal if the application is still initializing."
    print_message "$YELLOW" "You can try again manually: curl -v $backend_url"
  fi
  
  # Check if frontend is accessible
  frontend_url="${SERVER_PROTOCOL}://${FULL_DOMAIN}:${FRONTEND_PORT}"
  print_message "$BLUE" "You can access the frontend at: $frontend_url"
  print_message "$YELLOW" "Note: Frontend might take a few more moments to fully initialize."
}

# Display a welcome banner with correct username and timestamp
display_welcome_banner() {
  echo "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo "${BLUE}║                                                               ║${NC}"
  echo "${BLUE}║           ${GREEN}EVE Online Character Tracker - Docker Setup${BLUE}          ║${NC}"
  echo "${BLUE}║                                                               ║${NC}"
  echo "${BLUE}║  ${YELLOW}Created by: Thrainthepainthe${BLUE}                               ║${NC}"
  echo "${BLUE}║  ${YELLOW}Last Updated: 2025-05-04 03:54:58${BLUE}                          ║${NC}"
  echo "${BLUE}║                                                               ║${NC}"
  echo "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Main function
main() {
  display_welcome_banner
  
  # Install prerequisites
  install_prerequisites
  
  # Check system resources
  check_resources
  
  # Check if ports are in use
  check_ports
  
  # Verify required files
  check_files
  
  # Check for existing .env file
  check_env_file
  
  # Setup environment file
  setup_env_file
  
  # Create necessary directories
  create_directories
  
  # Fix Docker network issues
  fix_network_issues
  
  # Start containers
  start_containers "$1"
  
  # Verify application is working
  verify_application
  
  # Final success message with more robust env extraction
  if [ -f .env ]; then
    # Load variables safely for Ubuntu compatibility
    SERVER_PROTOCOL=$(grep "^SERVER_PROTOCOL=" .env | cut -d= -f2- | tr -d '\r' || echo "http")
    FULL_DOMAIN=$(grep "^FULL_DOMAIN=" .env | cut -d= -f2- | tr -d '\r' || echo "localhost")
    BACKEND_PORT=$(grep "^BACKEND_PORT=" .env | cut -d= -f2- | tr -d '\r' || echo "5000")
    FRONTEND_PORT=$(grep "^FRONTEND_PORT=" .env | cut -d= -f2- | tr -d '\r' || echo "80")
    
    print_message "$GREEN" "EVE Online Character Tracker is now running!"
    print_message "$GREEN" "Frontend: ${SERVER_PROTOCOL}://${FULL_DOMAIN}:${FRONTEND_PORT}"
    print_message "$GREEN" "Backend API: ${SERVER_PROTOCOL}://${FULL_DOMAIN}:${BACKEND_PORT}/api"
    print_message "$GREEN" "Admin login is available once you sign in with an EVE character"
    print_message "$GREEN" "and manually set the first user as admin in the database."
  else
    print_message "$GREEN" "EVE Online Character Tracker is now running!"
    print_message "$GREEN" "Frontend: http://localhost"
    print_message "$GREEN" "Backend API: http://localhost:5000/api"
  fi
  
  # Get appropriate compose command for shutdown instructions
  compose_cmd=$(check_docker)
  sudo_cmd=""
  if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
    sudo_cmd="sudo"
  fi
  
  print_message "$YELLOW" "To stop the application, run: $sudo_cmd $compose_cmd down"
  print_message "$YELLOW" "To view logs, run: $sudo_cmd $compose_cmd logs -f"
  print_message "$YELLOW" "To restart after system reboot, run: $sudo_cmd $compose_cmd up -d"
}

# Parse command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: bash docker-run.sh [OPTIONS]"
  echo "Options:"
  echo "  --rebuild, -r    Rebuild all containers"
  echo "  --force, -f      Force overwrite existing .env file"
  echo "  --help, -h       Show this help message"
  exit 0
fi

# Handle force flag
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
  if [ -f .env ]; then
    backup_file=".env.backup.$(date +%Y%m%d%H%M%S)"
    print_message "$BLUE" "Backing up existing .env file to $backup_file..."
    cp .env "$backup_file"
    print_message "$BLUE" "Removing existing .env file..."
    rm .env
  fi
  shift
fi

if [ "$1" = "--rebuild" ] || [ "$1" = "-r" ]; then
  main "rebuild"
else
  main
fi
