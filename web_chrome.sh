#!/bin/bash

LOGFILE="$HOME/chromium_setup.log"

function log {
    echo "$(date '+%a %b %d %H:%M:%S %Z %Y') : $1" | tee -a "$LOGFILE"
}

# Function to handle errors
function handle_error {
    log "Error: $1"
    exit 1
}

# Function to check and fix Docker daemon
function fix_docker_daemon {
    log "Checking Docker daemon configuration..."
    
    # Stop Docker service and socket
    sudo systemctl stop docker.service docker.socket
    
    # Create or update daemon.json
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "debug": true,
    "hosts": ["unix:///var/run/docker.sock"]
}
EOF
    
    # Update Docker service configuration
    sudo mkdir -p /etc/systemd/system/docker.service.d
    sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
EOF
    
    # Reload systemd and restart Docker
    sudo systemctl daemon-reload
    sudo systemctl start docker.socket
    sudo systemctl start docker.service
    sudo systemctl enable docker.socket
    sudo systemctl enable docker.service
    
    # Wait for Docker to be ready
    sleep 5
    
    # Verify Docker is running
    if ! sudo docker info >/dev/null 2>&1; then
        handle_error "Docker daemon still not running properly after configuration"
    fi
    
    log "Docker daemon configured successfully"
}

# Clear any existing Chromium Docker container
log "Stopping and removing existing Chromium container..."
sudo docker kill chromium &>/dev/null || true
sudo docker rm chromium &>/dev/null || true

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    log "Docker not found. Installing Docker..."
    sudo apt update -y && sudo apt upgrade -y || handle_error "Failed to update system packages."

    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg &>/dev/null || true
    done

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common || handle_error "Failed to install dependencies."

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || handle_error "Failed to add Docker GPG key."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io || handle_error "Failed to install Docker."
    fix_docker_daemon
    log "Docker installed successfully."
else
    log "Docker is already installed."
    fix_docker_daemon
fi

# Ensure current user has Docker permissions
if ! groups | grep -q docker; then
    log "Adding current user to Docker group..."
    sudo usermod -aG docker $USER
    # Fix socket permissions
    sudo chmod 666 /var/run/docker.sock
    log "User added to Docker group. Please log out and log back in for changes to take effect."
fi

# Install Docker Compose
log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Get server timezone, default to Etc/UTC if not found
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
TIMEZONE=${TIMEZONE:-"Etc/UTC"}
log "Server timezone set to: $TIMEZONE"

# Set up Chromium with Docker Compose and KasmVNC
log "Setting up Chromium Docker environment..."

mkdir -p "$HOME/chromium" && cd "$HOME/chromium" || handle_error "Failed to create Chromium directory."

# Customizable environment variables
CUSTOM_USER="${CUSTOM_USER:-admin}"
PASSWORD="${PASSWORD:-12345678}"

# Generate docker-compose.yaml file for Chromium and Nginx services
cat <<EOF > docker-compose.yaml
version: "3.8"
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - VNC_USER=$CUSTOM_USER
      - VNC_PW=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - $HOME/chromium/config:/config
    shm_size: "2gb"
    ports:
      - 6901:6901
    restart: unless-stopped

  nginx:
    image: nginx:latest
    container_name: chromium_nginx
    ports:
      - "8080:8080"
    volumes:
      - "$HOME/chromium/nginx.conf:/etc/nginx/nginx.conf:ro"
      - "$HOME/chromium/.htpasswd:/etc/nginx/.htpasswd:ro"
    restart: unless-stopped
EOF

# Create Nginx configuration with WebSocket support
cat <<EOF > nginx.conf
events {}
http {
    server {
        listen 8080;

        location / {
            auth_basic "Protected Chromium Access";
            auth_basic_user_file /etc/nginx/.htpasswd;

            proxy_pass http://chromium:6901;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# Create .htpasswd file for Nginx basic authentication
sudo apt install -y apache2-utils || handle_error "Failed to install apache2-utils."
echo "$PASSWORD" | htpasswd -c -i "$HOME/chromium/.htpasswd" "$CUSTOM_USER" || handle_error "Failed to create htpasswd file."

# Launch the Chromium and Nginx containers
log "Starting Docker Compose services..."
docker-compose up -d || handle_error "Failed to start Docker Compose services."

# Get the public IP of the server
IPVPS=$(curl -s ifconfig.me)
log "Access Chromium at http://$IPVPS:8080 with Username: $CUSTOM_USER and Password: $PASSWORD"

# Clean up Docker system
log "Pruning Docker system..."
docker system prune -f

log "Chromium setup complete!"
