#!/bin/bash

# EVE Online Character Tracker - Docker Setup Script
# Created by: Thrainthepain
# Last Updated: 2025-05-04 01:22:11

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
    echo -e "║  ${YELLOW}Last Updated: 2025-05-04 01:22:11${BLUE}                           ║"
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

# Check for required files
check_files() {
    print_message $BLUE "Checking for required project files..."
    
    required_files=(
        "Dockerfile"
        "client/Dockerfile"
        "docker-compose.yml"
        "nginx.conf"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_message $RED "Required file missing: $file"
            print_message $RED "Please make sure you're in the correct directory."
            exit 1
        fi
    done
    
    print_message $GREEN "All required files found."
}

# Check development prerequisites
check_development_prerequisites() {
    print_message $BLUE "Checking development prerequisites..."
    print_message $YELLOW "Note: These are only needed for local development outside Docker."
    
    # Check Node.js version
    if command -v node &> /dev/null; then
        node_version=$(node -v | tr -d 'v')
        print_message $GREEN "Node.js v${node_version} is installed."
        
        # Check if version is >= 14 using version comparison
        if [ $(echo "$node_version < 14" | bc -l) -eq 1 ]; then
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
        mongo_version=$(mongod --version | grep "db version" | sed 's/db version v//')
        print_message $GREEN "MongoDB ${mongo_version} is installed locally."
        
        # Check if version is >= 4 using version comparison
        if [ $(echo "$mongo_version < 4" | bc -l) -eq 1 ]; then
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
    print_message $BLUE "EVE Online ESI Application Details (required)"
    print_message $YELLOW "Create an application at https://developers.eveonline.com if needed."
    read -p "Enter your EVE ESI Client ID: " eve_client_id
    read -p "Enter your EVE ESI Client Secret: " eve_client_secret
    read -p "Enter your Developer Email (required by EVE): " dev_email
    
    # Generate a random session secret
    session_secret=$(openssl rand -base64 32 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 32)
    
    # Basic configuration with defaults
    read -p "Enter Website Name (default: EVE Character Tracker): " website_name
    website_name=${website_name:-"EVE Character Tracker"}
    
    # Protocol selection
    print_message $BLUE "Select Protocol:"
    select protocol in "HTTP" "HTTPS"; do
        case $protocol in
            HTTP ) protocol="http"; break;;
            HTTPS ) protocol="https"; break;;
        esac
    done
    protocol=${protocol:-"http"}
    
    # Docker ports configuration
    read -p "Enter Frontend Port (default: 80): " frontend_port
    frontend_port=${frontend_port:-"80"}
    
    read -p "Enter Backend Port (default: 5000): " backend_port
    backend_port=${backend_port:-"5000"}
    
    # MongoDB password generation
    mongo_password=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
    
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

# Create necessary directories
create_directories() {
    print_message $BLUE "Creating necessary directories..."
    
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
            mkdir -p "$dir"
        fi
    done
    
    # Set appropriate permissions
    chmod -R 755 logs backups uploads 2>/dev/null || true
    
    print_message $GREEN "Directories created."
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
    else
        $sudo_cmd $compose_cmd up -d
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
    
    # Check for required files
    check_files
    
    # Check development prerequisites
    check_development_prerequisites
    
    # Setup environment file
    setup_env_file
    
    # Create necessary directories
    create_directories
    
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