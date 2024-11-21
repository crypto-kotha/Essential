#!/bin/bash

# Script to create a systemd service for running 'rivalz run' on startup

# Step 1: Find the path of the 'rivalz' executable
RIVALZ_PATH=$(which rivalz)

# Check if 'rivalz' is installed
if [ -z "$RIVALZ_PATH" ]; then
    echo "Error: 'rivalz' is not installed or not in the system's PATH."
    echo "Install it globally with: sudo npm install -g rivalz-node-cli"
    exit 1
fi

echo "Found 'rivalz' at: $RIVALZ_PATH"

# Step 2: Define the systemd service file path
SERVICE_FILE="/etc/systemd/system/rivalz.service"

# Step 3: Create the systemd service file
echo "Creating systemd service file at $SERVICE_FILE..."

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Rivalz Node CLI Service
After=network.target

[Service]
Type=simple
ExecStart=$RIVALZ_PATH run
Restart=always
User=$USER
WorkingDirectory=$HOME
Environment="PATH=/usr/bin:/bin:/usr/local/bin"

[Install]
WantedBy=multi-user.target
EOF

# Step 4: Set permissions for the service file
sudo chmod 644 $SERVICE_FILE

# Step 5: Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Step 6: Enable and start the service
echo "Enabling and starting the Rivalz service..."
sudo systemctl enable rivalz.service
sudo systemctl start rivalz.service

# Step 7: Check the service status
echo "Checking the status of the Rivalz service..."
sudo systemctl status rivalz.service
sudo journalctl -u rivalz.service -f

echo "Setup complete! 'rivalz run' will now start automatically on reboot."
