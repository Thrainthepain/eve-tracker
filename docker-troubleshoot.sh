#!/bin/bash

# EVE Online Character Tracker - Docker Troubleshooting Script
# Current Date: 2025-05-03 23:17:25
# Author: ThrainthepainDev

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Troubleshooting Script${NC}"
echo -e "${BLUE}Date: $(date)${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Check if Docker is installed and running
echo -e "\n${YELLOW}[STEP 1] Checking if Docker is installed and running...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed. Please install Docker Desktop first.${NC}"
    exit 1
fi

docker info &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Docker is not running. Please start Docker Desktop and try again.${NC}"
    exit 1
else
    echo -e "${GREEN}SUCCESS: Docker is installed and running.${NC}"
    docker --version
fi

# Step 2: Check Docker Compose
echo -e "\n${YELLOW}[STEP 2] Checking Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}SUCCESS: docker-compose command found.${NC}"
    docker-compose --version
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    echo -e "${GREEN}SUCCESS: docker compose plugin found.${NC}"
    docker compose version
    COMPOSE_CMD="docker compose"
else
    echo -e "${RED}ERROR: Docker Compose not found. Please install Docker Compose or make sure Docker Desktop includes it.${NC}"
    exit 1
fi

# Step 3: Test basic Docker functionality with a simple container
echo -e "\n${YELLOW}[STEP 3] Testing basic Docker functionality...${NC}"
echo -e "${BLUE}Creating a test container...${NC}"
if docker run --rm hello-world; then
    echo -e "${GREEN}SUCCESS: Basic Docker functionality is working.${NC}"
else
    echo -e "${RED}ERROR: Failed to run a basic test container.${NC}"
    echo -e "${RED}Check Docker Desktop settings and permissions.${NC}"
    exit 1
fi

# Step 4: Check for port conflicts
echo -e "\n${YELLOW}[STEP 4] Checking for port conflicts...${NC}"
web_port=80
api_port=5000

if command -v netstat &> /dev/null; then
    check_cmd="netstat -tuln | grep"
elif command -v ss &> /dev/null; then
    check_cmd="ss -tuln | grep"
else
    check_cmd="lsof -i:"
fi

echo -e "${BLUE}Checking if port $web_port (frontend) is already in use...${NC}"
if $check_cmd ":$web_port " &> /dev/null; then
    echo -e "${RED}WARNING: Port $web_port is already in use. This may cause conflicts.${NC}"
else
    echo -e "${GREEN}Port $web_port is available.${NC}"
fi

echo -e "${BLUE}Checking if port $api_port (backend) is already in use...${NC}"
if $check_cmd ":$api_port " &> /dev/null; then
    echo -e "${RED}WARNING: Port $api_port is already in use. This may cause conflicts.${NC}"
else
    echo -e "${GREEN}Port $api_port is available.${NC}"
fi

# Step 5: Check project file permissions and directory structure
echo -e "\n${YELLOW}[STEP 5] Checking project files and directories...${NC}"
required_files=("docker-compose.yml" "Dockerfile" "client/Dockerfile" "nginx.conf")

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}File exists: $file${NC}"
    else
        echo -e "${RED}ERROR: Missing required file: $file${NC}"
    fi
done

# Step 6: Attempt to run Docker Compose with verbose output
echo -e "\n${YELLOW}[STEP 6] Attempting to run Docker Compose with verbose output...${NC}"
echo -e "${BLUE}Running: $COMPOSE_CMD config${NC}"
$COMPOSE_CMD config

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Docker Compose configuration is invalid. See errors above.${NC}"
else
    echo -e "${GREEN}Docker Compose configuration is valid.${NC}"
    
    echo -e "\n${BLUE}Would you like to try starting the containers with verbose output? (y/n)${NC}"
    read -p "This will run '$COMPOSE_CMD up -d --verbose': " answer
    
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo -e "${BLUE}Starting containers with verbose output...${NC}"
        $COMPOSE_CMD up -d --verbose
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR: Failed to start containers. See errors above.${NC}"
        else
            echo -e "${GREEN}Containers started successfully.${NC}"
            echo -e "\n${BLUE}Running containers:${NC}"
            docker ps
        fi
    fi
fi

echo -e "\n${YELLOW}Troubleshooting complete.${NC}"
echo -e "${BLUE}For additional help, check Docker Desktop logs or run:${NC}"
echo -e "${BLUE}docker system info${NC}"
echo -e "${BLUE}$COMPOSE_CMD logs${NC}"