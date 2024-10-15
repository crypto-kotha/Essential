#!/bin/bash

# Function to install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt update -y && sudo apt upgrade -y
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
    done

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y && sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# Function to install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

# Get the server timezone, default to Asia/Jakarta if not found
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$TIMEZONE" ]; then
    TIMEZONE="Asia/Jakarta"
fi
echo "Server timezone detected: $TIMEZONE"

# Generate random username and password
CUSTOM_USER=$(openssl rand -hex 4)  
PASSWORD=$(openssl rand -hex 12)    
echo "Generated username: $CUSTOM_USER"
echo "Generated password: $PASSWORD"

# Setting up Chromium with Docker Compose and KasmVNC for browser-based access
echo "Setting up Chromium with Docker Compose..."
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
---
version: "3.8"
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - /root/chromium/config:/config
    shm_size: "1gb"
    ports:
      - 6901:6901  # VNC/NoVNC access port
      - 3000:3000  # HTTP port for chromium service (if applicable)
    restart: unless-stopped
EOF

if [ ! -f "docker-compose.yaml" ]; then
    echo "Failed to create docker-compose.yaml. Exiting..."
    exit 1
fi

echo "Running Chromium container..."
docker-compose up -d || { echo "Failed to start Docker Compose"; exit 1; }

# Get the public IP of the server
IPVPS=$(curl -s ifconfig.me)

# Display access information
echo "Access Chromium through your browser via VNC at: http://$IPVPS:6901/"
echo "Username: $CUSTOM_USER"
echo "Password: $PASSWORD"
echo "You can now browse the web remotely using Chromium!"

# Clean up Docker system
docker system prune -f
echo "Docker system pruned. Setup complete!"
