#!/bin/bash

# Make this script executable with: chmod +x docker-run.sh

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    
    echo "========================================="
    echo "EVE Online Character Tracker Configuration"
    echo "========================================="
    
    # Prompt for ESI/API information
    read -p "Enter your EVE ESI Client ID: " eve_client_id
    read -p "Enter your EVE ESI Client Secret: " eve_client_secret
    read -p "Enter your Developer Email (required by EVE): " dev_email
    
    # Prompt for website name and server settings
    read -p "Enter Website Name (default: EVE Character Tracker): " website_name
    website_name=${website_name:-"EVE Character Tracker"}
    
    read -p "Enter Server Domain (default: localhost): " server_domain
    server_domain=${server_domain:-"localhost"}
    
    # Update .env file with provided values
    sed -i "s/EVE_CLIENT_ID=your_eve_client_id/EVE_CLIENT_ID=$eve_client_id/" .env
    sed -i "s/EVE_CLIENT_SECRET=your_eve_client_secret/EVE_CLIENT_SECRET=$eve_client_secret/" .env
    
    # Add website name and server domain to .env
    echo "WEBSITE_NAME=\"$website_name\"" >> .env
    echo "SERVER_DOMAIN=$server_domain" >> .env
    echo "DEV_EMAIL=$dev_email" >> .env
    
    echo "Configuration saved to .env file."
fi

# Build and start the containers
echo "Building and starting EVE Tracker containers..."
docker-compose up -d --build

echo "EVE Tracker is now running!"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost:5000/api"