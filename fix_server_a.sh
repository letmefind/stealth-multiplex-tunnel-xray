#!/bin/bash

# Quick fix for Server A configuration
echo "Fixing Server A configuration..."

# Fix the JSON configuration - change shortIds to shortId
sed -i 's/"shortIds": \[[^]]*\]/"shortId": "db78ea236c7e33f5"/' /etc/xray/a.json

echo "Fixed /etc/xray/a.json"
echo "Configuration now uses shortId (singular) for outbound connection"

# Restart the service
echo "Restarting xray service..."
systemctl restart xray-a

# Check status
echo "Checking service status..."
systemctl status xray-a --no-pager
