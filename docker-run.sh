#!/bin/bash

# EVE Online Character Tracker - Docker Setup Script
# Created by: Thrainthepain
# Last Updated: 2025-05-03 23:48:55

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

# Check for required commands and install if missing
install_prerequisites() {
    print_message $BLUE "Checking for required prerequisites..."
    
    # Array of required commands
    declare -a required_cmds=("docker" "curl" "wget" "git")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_message $RED "$cmd is not installed. Please install it manually."
            print_message $YELLOW "Required prerequisites: docker, docker-compose, curl, wget, git"
            exit 1
        else
            print_message $GREEN "$cmd is already installed"
        fi
    done
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_message $RED "Docker Compose not found. Please install Docker Compose."
        exit 1
    else
        print_message $GREEN "Docker Compose is installed"
    fi
}

# Check system resources
check_resources() {
    print_message $BLUE "Checking system resources..."
    
    # Check disk space
    if command -v df &> /dev/null; then
        free_space=$(df -P . | awk 'NR==2 {print $4}')
        if [ $free_space -lt 1048576 ]; then  # Less than 1GB free
            print_message $RED "Not enough free disk space. Need at least 1GB."
            print_message $RED "Free space: $(($free_space / 1024)) MB"
            exit 1
        else
            print_message $GREEN "Disk space: $(($free_space / 1024 / 1024)) GB available"
        fi
    fi
    
    # Check if Docker can access internet (needed for pulling images)
    print_message $BLUE "Checking internet connectivity..."
    if ! curl -s --connect-timeout 5 https://registry-1.docker.io > /dev/null; then
        print_message $RED "Cannot connect to Docker Hub. Check your internet connection or firewall."
        print_message $YELLOW "If you're behind a proxy, make sure Docker is configured to use it."
        exit 1
    fi
    print_message $GREEN "Internet connectivity verified"
}

# Check if Docker is installed and running
check_docker() {
    print_message $BLUE "Verifying Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_message $RED "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker is running
    docker info &> /dev/null
    if [ $? -ne 0 ]; then
        print_message $RED "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check Docker version
    docker_version=$(docker version --format '{{.Server.Version}}')
    print_message $GREEN "Docker Engine version $docker_version is running."
    
    # Check for docker-compose command or docker compose plugin
    compose_cmd="none"
    if command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
        compose_version=$(docker-compose version --short)
        print_message $GREEN "Docker Compose standalone version $compose_version found."
    elif docker compose version &> /dev/null; then
        compose_cmd="docker compose"
        compose_version=$(docker compose version --short)
        print_message $GREEN "Docker Compose plugin version $compose_version found."
    else
        print_message $RED "Docker Compose not found. Please install Docker Compose."
        exit 1
    fi
    
    echo $compose_cmd
}

# Verify required files exist
check_files() {
    print_message $BLUE "Checking for required project files..."
    
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
            print_message $RED "Required file missing: $file"
            missing_files=1
        else
            print_message $GREEN "Found: $file"
        fi
    done
    
    for file in "${optional_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_message $YELLOW "Optional file missing: $file"
        else
            print_message $GREEN "Found: $file"
        fi
    done
    
    if [ $missing_files -eq 1 ]; then
        print_message $RED "Required files are missing. Please make sure you're in the correct directory."
        print_message $RED "Current directory: $(pwd)"
        exit 1
    fi
}

# Function to check for existing .env file
check_env_file() {
    if [ -f .env ]; then
        print_message $YELLOW "WARNING: An existing .env file was found."
        print_message $YELLOW "This script requires a fresh .env configuration."
        print_message $YELLOW "Options:"
        print_message $YELLOW "1. Delete the existing .env file manually and run this script again."
        print_message $YELLOW "2. Let this script back up and delete the .env file (recommended)."
        print_message $YELLOW "3. Exit without making changes."
        
        read -p "Please choose an option (1-3): " env_option
        
        case $env_option in
            1)
                print_message $YELLOW "Please delete the .env file manually and run this script again."
                exit 0
                ;;
            2)
                # Back up the existing .env file
                backup_file=".env.backup.$(date +%Y%m%d%H%M%S)"
                print_message $BLUE "Backing up existing .env file to $backup_file..."
                cp .env "$backup_file"
                
                # Remove the existing .env file
                print_message $BLUE "Removing existing .env file..."
                rm .env
                ;;
            *)
                print_message $YELLOW "Exiting without making changes."
                exit 0
                ;;
        esac
    fi
}

# Function to create or update .env file
setup_env_file() {
    print_message $BLUE "Creating new .env file..."
    
    # Check if .env.example exists
    if [ ! -f .env.example ]; then
        print_message $RED ".env.example file not found. Creating a basic .env file..."
        touch .env
    else
        cp .env.example .env
    fi
    
    print_message $GREEN "========================================="
    print_message $GREEN "EVE Online Character Tracker Configuration"
    print_message $GREEN "========================================="
    
    # Prompt for ESI/API information
    read -p "Enter your EVE ESI Client ID: " eve_client_id
    read -p "Enter your EVE ESI Client Secret: " eve_client_secret
    read -p "Enter your Developer Email (required by EVE): " dev_email
    
    # Generate a random session secret
    session_secret=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
    
    # Prompt for website name and server settings
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
    print_message $BLUE "Docker Desktop Configuration:"
    read -p "Enter Frontend Port (default: 80): " frontend_port
    frontend_port=${frontend_port:-"80"}
    
    read -p "Enter Backend Port (default: 5000): " backend_port
    backend_port=${backend_port:-"5000"}
    
    # Generate MongoDB password
    mongo_password=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
    
    # Write all configuration to .env file
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
SSL_MODE=${protocol == "https" ? "letsencrypt" : "skip"}
LETSENCRYPT_EMAIL=${dev_email}

# Worker Settings
BACKUP_RETENTION_DAYS=7
BACKUP_TIME=2:00
TOKEN_REFRESH_INTERVAL=15
DB_MAINTENANCE_TIME=3:00
EOF
    
    print_message $GREEN "Configuration saved to .env file."
    
    # If using HTTPS, prompt for SSL certificate setup
    if [ "$protocol" = "https" ]; then
        print_message $BLUE "\nYou've selected HTTPS. You'll need SSL certificates for your domain."
        print_message $BLUE "Options:"
        print_message $BLUE "1. Use Let's Encrypt (automatic)"
        print_message $BLUE "2. Provide your own certificates"
        print_message $BLUE "3. Skip for now (you'll need to configure SSL manually later)"
        
        read -p "Choose option (1-3): " ssl_option
        
        case $ssl_option in
            1)
                echo "SSL_MODE=letsencrypt" >> .env
                read -p "Enter email for Let's Encrypt registration: " le_email
                echo "LETSENCRYPT_EMAIL=$le_email" >> .env
                ;;
            2)
                echo "SSL_MODE=custom" >> .env
                print_message $YELLOW "Custom certificate setup will be required after container startup."
                ;;
            *)
                echo "SSL_MODE=skip" >> .env
                print_message $YELLOW "You've chosen to skip SSL setup. HTTPS won't work until certificates are configured."
                ;;
        esac
    fi
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
            print_message $GREEN "Created directory: $dir"
        else
            print_message $GREEN "Directory already exists: $dir"
        fi
    done
    
    # Ensure proper permissions
    chmod -R 755 logs backups uploads 2>/dev/null || true
}

# Fix Docker network issues (common for Docker Desktop)
fix_network_issues() {
    print_message $BLUE "Checking for Docker network issues..."
    
    # Check if eve-network exists, if yes remove it to prevent conflicts
    if docker network inspect eve-network &> /dev/null; then
        print_message $YELLOW "Found existing eve-network, removing to prevent conflicts..."
        docker network rm eve-network &> /dev/null
    fi
    
    # Create fresh network
    print_message $BLUE "Creating fresh Docker network..."
    docker network create eve-network &> /dev/null
    
    if [ $? -ne 0 ]; then
        print_message $RED "Failed to create Docker network. Check Docker settings."
        return 1
    else
        print_message $GREEN "Created Docker network: eve-network"
        return 0
    fi
}

# Function to start Docker containers
start_containers() {
    print_message $BLUE "Building and starting EVE Tracker containers..."
    
    # Get the appropriate compose command
    compose_cmd=$(check_docker)
    
    # Check if we need to force pull images
    if [ "$1" = "rebuild" ]; then
        print_message $BLUE "Force pulling latest images..."
        $compose_cmd pull
    fi
    
    # Start containers
    print_message $BLUE "Starting containers with $compose_cmd..."
    if [ "$1" = "rebuild" ]; then
        $compose_cmd up -d --build --force-recreate
    else
        $compose_cmd up -d
    fi
    
    # Check if containers started successfully
    if [ $? -ne 0 ]; then
        print_message $RED "Failed to start containers. Please check docker logs for details."
        print_message $YELLOW "Running diagnostic commands..."
        
        print_message $BLUE "\nDocker Compose Logs:"
        $compose_cmd logs
        
        print_message $BLUE "\nRunning containers:"
        docker ps
        
        exit 1
    fi
    
    # Check if containers are actually running
    sleep 5
    running_containers=$(docker ps --format '{{.Names}}' | grep -c "eve-tracker")
    expected_containers=3 # mongodb, backend, frontend
    
    if [ $running_containers -lt $expected_containers ]; then
        print_message $RED "Not all containers are running. Expected $expected_containers but found $running_containers."
        print_message $YELLOW "Running containers:"
        docker ps
        print_message $YELLOW "Checking container logs for errors..."
        
        containers=("eve-tracker-mongodb" "eve-tracker-backend" "eve-tracker-frontend")
        for container in "${containers[@]}"; do
            if ! docker ps --format '{{.Names}}' | grep -q "$container"; then
                print_message $RED "$container is not running. Logs:"
                docker logs $container
            fi
        done
        
        exit 1
    fi
    
    print_message $GREEN "All containers are running successfully!"
}

# Verify application is working
verify_application() {
    print_message $BLUE "Verifying application is working..."
    
    source .env
    
    # Wait a bit for services to fully start
    print_message $YELLOW "Waiting for services to initialize (10 seconds)..."
    sleep 10
    
    # Check if backend API is accessible
    backend_url="${SERVER_PROTOCOL}://${FULL_DOMAIN}:${BACKEND_PORT}/api/health"
    print_message $BLUE "Checking backend health at: $backend_url"
    
    if curl -s --connect-timeout 5 "$backend_url" | grep -q "status.*ok\|healthy\|UP"; then
        print_message $GREEN "Backend API is accessible!"
    else
        print_message $RED "Backend API is not responding. Check backend container logs:"
        docker logs eve-tracker-backend
        print_message $YELLOW "This might be normal if the application is still initializing."
    fi
    
    # Check if frontend is accessible
    frontend_url="${SERVER_PROTOCOL}://${FULL_DOMAIN}:${FRONTEND_PORT}"
    print_message $BLUE "You can access the frontend at: $frontend_url"
    print_message $YELLOW "Note: Frontend might take a few more moments to fully initialize."
}

# Display a welcome banner
display_welcome_banner() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗"
    echo -e "║                                                               ║"
    echo -e "║           ${GREEN}EVE Online Character Tracker - Docker Setup${BLUE}          ║"
    echo -e "║                                                               ║"
    echo -e "║  ${YELLOW}Created by: Thrainthepain${BLUE}                                   ║"
    echo -e "║  ${YELLOW}Last Updated: 2025-05-03 23:48:55${BLUE}                           ║"
    echo -e "║                                                               ║"
    echo -e "╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Main function
main() {
    display_welcome_banner
    
    # Install prerequisites
    install_prerequisites
    
    # Check system resources
    check_resources
    
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
    start_containers $1
    
    # Verify application is working
    verify_application
    
    # Final success message
    if [ -f .env ]; then
        source .env
        print_message $GREEN "\nEVE Online Character Tracker is now running!"
        print_message $GREEN "Frontend: ${SERVER_PROTOCOL}://${FULL_DOMAIN}:${FRONTEND_PORT}"
        print_message $GREEN "Backend API: ${SERVER_PROTOCOL}://${FULL_DOMAIN}:${BACKEND_PORT}/api"
        print_message $GREEN "Admin login is available once you sign in with an EVE character"
        print_message $GREEN "and manually set the first user as admin in the database."
    else
        print_message $GREEN "\nEVE Online Character Tracker is now running!"
        print_message $GREEN "Frontend: http://localhost"
        print_message $GREEN "Backend API: http://localhost:5000/api"
    fi
    
    get_compose_cmd=$(check_docker)
    print_message $YELLOW "\nTo stop the application, run: $get_compose_cmd down"
    print_message $YELLOW "To view logs, run: $get_compose_cmd logs -f"
}

# Parse command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: ./docker-run.sh [OPTIONS]"
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
        print_message $BLUE "Backing up existing .env file to $backup_file..."
        cp .env "$backup_file"
        print_message $BLUE "Removing existing .env file..."
        rm .env
    fi
    shift
fi

if [ "$1" = "--rebuild" ] || [ "$1" = "-r" ]; then
    main "rebuild"
else
    main
fi