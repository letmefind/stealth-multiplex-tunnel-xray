#!/bin/bash

# Fix Server A configuration to match Server B
echo "Fixing Server A configuration..."

# Update public key to match Server B
sed -i 's/"publicKey": "wwgbwD3pK6aBzxtMzAyAdzV8430zraDqrCrH7tivDV4"/"publicKey": "9i6wF6MW6MkdRTxZ49J6NMyfRxosRoEwXLyu4a5Y-Uc"/' /etc/xray/a.json

# Update UUID to match Server B
sed -i 's/"id": "74291e5c-9b5c-4183-83e1-e790d1a3e4b8"/"id": "4a009700-c7ff-47cb-bf5b-9cbee3e4674e"/' /etc/xray/a.json

# Restart the service
echo "Restarting xray service..."
systemctl restart xray-a

# Check status
echo "Checking service status..."
systemctl status xray-a --no-pager
