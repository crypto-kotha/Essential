#!/bin/bash

# Update and Upgrade the System
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Install Essentials
echo "Installing essential packages..."
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    unzip \
    zip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    vim \
    net-tools \
    tree \
    ufw \
    openssh-server \
    tmux \
    gcc \
    g++ \
    make \
    python3 \
    python3-pip

# Install Development Tools
echo "Installing development tools..."
sudo apt install -y \
    nodejs \
    npm \
    python3-venv

# Install Docker
echo "Installing Docker..."
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo apt update
sudo apt install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (optional)
sudo usermod -aG docker $USER

# Install VSCode
echo "Installing Visual Studio Code..."
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install -y code

# Install Node.js and npm (this may be redundant since it's already included above)
# Uncomment if needed
# echo "Installing Node.js and npm..."
# sudo apt install -y nodejs npm

# Install Yarn (Alternative to npm)
echo "Installing Yarn..."
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn

# Install Snap and some Snap apps
echo "Installing Snap and common snap apps..."
sudo apt install snapd -y
sudo snap install discord

# Install Chrome Stable
echo "Installing Google Chrome..."
wget -q --show-progress --no-check-certificate https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y  # Fix any dependency issues
rm google-chrome-stable_current_amd64.deb

# Install Advanced Networking Tools
echo "Installing advanced networking tools..."
sudo apt install -y \
    iftop \
    traceroute \
    dnsutils \
    iputils-ping \
    tcpdump \
    whois

# Install Firewall management
echo "Setting up UFW Firewall..."
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status

# Install Rust
echo "Installing Rust programming language..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Clean up
echo "Cleaning up..."
sudo apt autoremove -y && sudo apt autoclean -y

# Reboot the system for changes to take effect
echo "Installation completed. Rebooting system..."
sudo reboot
