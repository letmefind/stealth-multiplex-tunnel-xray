#!/bin/bash

# Fix Server B configuration to match Server A
echo "Fixing Server B configuration..."

# Update UUID to match Server A
sed -i 's/"id": "4a009700-c7ff-47cb-bf5b-9cbee3e4674e"/"id": "74291e5c-9b5c-4183-83e1-e790d1a3e4b8"/' /etc/xray/b.json

# Update private key to match Server A's public key
# You need to get the correct private key from Server A
echo "Please update the private key manually to match Server A's public key"
echo "Server A's public key: wwgbwD3pK6aBzxtMzAyAdzV8430zraDqrCrH7tivDV4"

# Restart the service
echo "Restarting xray service..."
systemctl restart xray-b

# Check status
echo "Checking service status..."
systemctl status xray-b --no-pager
