#!/bin/bash

# Fix Turkey Server A to use working keys
echo "Fixing Turkey Server A configuration..."

# Update public key to working key
sed -i 's/"publicKey": "9i6wF6MW6MkdRTxZ49J6NMyfRxosRoEwXLyu4a5Y-Uc"/"publicKey": "wwgbwD3pK6aBzxtMzAyAdzV8430zraDqrCrH7tivDV4"/' /etc/xray/a.json

# Update UUID to working UUID
sed -i 's/"id": "4a009700-c7ff-47cb-bf5b-9cbee3e4674e"/"id": "d2831e7a-c4c2-4b25-92ae-0e13924b6a4d"/' /etc/xray/a.json

# Restart the service
echo "Restarting xray service..."
systemctl restart xray-a

# Check status
echo "Checking service status..."
systemctl status xray-a --no-pager
