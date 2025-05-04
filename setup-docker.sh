#!/bin/bash

# Modern Docker Setup Script for Python 3.12
# Created by: Thrainthepaindocker
# Last Updated: 2025-05-04 14:57:40

echo "Setting up modern Docker environment for Python 3.12..."

# Install required packages
echo "Installing required dependencies..."
sudo apt update
sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  python3-pip \
  python3-setuptools \
  python3-venv \
  python3-wheel

# Add Docker's official GPG key
echo "Setting up Docker repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
echo "Installing Docker Engine and Docker Compose Plugin..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
echo "Added $USER to docker group. You may need to log out and back in for this to take effect."

# Verify installation
echo "Verifying Docker installation..."
docker --version
docker compose version

echo "Docker setup complete. You can now use Docker and Docker Compose v2."
echo "Run 'docker compose up' instead of 'docker-compose up'"