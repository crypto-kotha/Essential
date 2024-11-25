#!/bin/bash

# Error handling and logging
set -e
LOG_FILE="$HOME/chromium-setup.log"

function log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

function handle_error() {
    log "ERROR: $1"
    exit 1
}

# Configuration variables
CUSTOM_USER="Admin"
PASSWORD="Admin"
TIMEZONE="Asia/Dhaka"
CHROMIUM_DIR="$HOME/chromium"

# Function to find next available port
function find_next_available_port() {
    local port=$1
    while nc -z localhost $port 2>/dev/null; do
        log "Port $port is in use, trying next port..."
        port=$((port + 1))
    done
    echo $port
}

# Setup Chromium with Docker Compose
function setup_chromium() {
    log "Setting up Chromium environment..."
    mkdir -p "$CHROMIUM_DIR"

    # Find available ports
    NGINX_PORT=$(find_next_available_port 8081)
    log "Using port $NGINX_PORT for Nginx"

    # Create docker-compose.yml for both Chromium and Nginx
    cat > "$CHROMIUM_DIR/docker-compose.yml" <<EOF
version: "3.8"
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - VNC_USER=${CUSTOM_USER}
      - VNC_PW=${PASSWORD}
      - PUID=$(id -u)
      - PGID=$(id -g)
      - TZ=${TIMEZONE}
      - CHROME_CLI=--no-sandbox
    volumes:
      - ${CHROMIUM_DIR}/config:/config
    ports:
      - "3000:3000"
      - "127.0.0.1:6901:6901"
    restart: unless-stopped
    shm_size: "2gb"
    networks:
      - chromium_network

  nginx:
    image: nginx:latest
    container_name: chromium_nginx_new
    volumes:
      - ${CHROMIUM_DIR}/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ${CHROMIUM_DIR}/.htpasswd:/etc/nginx/.htpasswd:ro
    ports:
      - "${NGINX_PORT}:80"
    depends_on:
      - chromium
    restart: unless-stopped
    networks:
      - chromium_network

networks:
  chromium_network:
    name: chromium_network
EOF

    # Create Nginx configuration
    cat > "$CHROMIUM_DIR/nginx.conf" <<EOF
server {
    listen 80;
    server_name _;

    location / {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://chromium:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
}
EOF

    # Create .htpasswd file
    echo "${CUSTOM_USER}:$(openssl passwd -apr1 ${PASSWORD})" > "$CHROMIUM_DIR/.htpasswd"

    # Stop existing containers with the same name
    docker stop chromium_nginx_new 2>/dev/null || true
    docker rm chromium_nginx_new 2>/dev/null || true

    # Start new containers
    cd "$CHROMIUM_DIR"
    docker-compose up -d || handle_error "Failed to start containers"
}

# Main execution
log "Starting Chromium setup with Nginx authentication..."

# Check if docker and docker-compose are installed
if ! command -v docker &>/dev/null; then
    handle_error "Docker is not installed. Please install Docker first."
fi

if ! command -v docker-compose &>/dev/null; then
    handle_error "Docker Compose is not installed. Please install Docker Compose first."
fi

# Install netcat for port checking
if ! command -v nc &>/dev/null; then
    log "Installing netcat for port checking..."
    sudo apt-get update && sudo apt-get install -y netcat
fi

setup_chromium

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)
log "Setup complete! Access your Chromium instance at: http://${PUBLIC_IP}:${NGINX_PORT}/"
log "Username: ${CUSTOM_USER}"
log "Password: ${PASSWORD}"
