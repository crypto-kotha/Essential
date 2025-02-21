#!/bin/bash

# Define color codes
RESET="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
MAGENTA="\e[35m"

# Start of the script
echo -e "${CYAN}Starting System Upgrade...${RESET}"

# Update and upgrade system
echo -e "${YELLOW}Updating and upgrading the system...${RESET}"
sudo apt-get update && sudo apt-get -y upgrade && sudo apt -y autoremove

# Install Node.js
echo -e "${YELLOW}Installing Node.js_v20...${RESET}"
sudo curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${RESET}"
sudo apt install -y build-essential curl wget git unzip zip software-properties-common python3 python3-pip nodejs docker-ce docker-ce-cli containerd.io gnupg2 lsb-release apache2-utils ufw ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4

# Add Docker GPG key
echo -e "${CYAN}Adding Docker GPG key...${RESET}"
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
echo -e "${YELLOW}Setting up Docker repository...${RESET}"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Add Docker group and user
echo -e "${CYAN}Adding Docker group and user...${RESET}"
sudo groupadd docker
sudo usermod -aG docker $USER

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${RESET}"
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Enable and start Docker
echo -e "${CYAN}Starting Docker...${RESET}"
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl stop docker
sudo systemctl start docker

# Install Miniconda
echo -e "${YELLOW}Installing Miniconda...${RESET}"
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
source ~/miniconda3/bin/activate
sudo rm ~/miniconda3/miniconda.sh
conda init --all

# Display versions
echo -e "${BLUE}Docker version: ${RESET} $(docker --version)"
echo -e "${BLUE}Docker Compose version: ${RESET} $(docker-compose --version)"
echo -e "${BLUE}Node.js version: ${RESET} $(node -v)"
echo -e "${BLUE}Conda version: ${RESET} $(conda --version)"

# End of the script
echo -e "${CYAN}System Upgrade Complete.${RESET}"
