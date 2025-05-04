#!/bin/bash

# Script to fix Docker Compose distutils error on Ubuntu
# Created by: ThrainthepainFile
# Last Updated: 2025-05-04 14:54:00

echo "Fixing Docker Compose 'distutils' module error..."

# Install the missing Python package
sudo apt update
sudo apt install -y python3-distutils

# Check which Docker Compose we're using
if command -v docker-compose >/dev/null 2>&1; then
  echo "✅ Using standalone Docker Compose"
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  echo "✅ Using Docker Compose plugin"
  COMPOSE_CMD="docker compose"
else
  echo "❌ Docker Compose not found. Installing Docker Compose plugin..."
  sudo apt install -y docker-compose-plugin
  COMPOSE_CMD="docker compose"
fi

# Verify the fix worked
echo "Testing Docker Compose..."
$COMPOSE_CMD version

if [ $? -eq 0 ]; then
  echo "✅ Docker Compose is now working correctly!"
  echo ""
  echo "To start your containers, run:"
  echo "docker compose up -d"
else
  echo "❌ There was an issue with the fix. Trying alternative solution..."
  
  # Alternative solution - reinstall Docker Compose
  sudo pip3 uninstall -y docker-compose
  sudo pip3 install docker-compose
  
  echo "Testing Docker Compose again..."
  docker-compose version
  
  if [ $? -eq 0 ]; then
    echo "✅ Docker Compose is now working correctly!"
  else
    echo "❌ Could not fix Docker Compose. Please try manually:"
    echo "sudo apt install python3-distutils"
    echo "sudo pip3 install -U docker-compose"
  fi
fi