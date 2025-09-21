#!/bin/bash

# Fix USA Server B to use working keys
echo "Fixing USA Server B configuration..."

# Update private key to working key
sed -i 's/"privateKey": "ADwqB3COpNcfZFvCScR2KetIJbcXcBGZpz4M-5npq1g"/"privateKey": "kEHlrW7KE0TxG_UhhOwE2YzMbzGlWign5rSrcweFVkY"/' /etc/xray/b.json

# Update UUID to working UUID
sed -i 's/"id": "4a009700-c7ff-47cb-bf5b-9cbee3e4674e"/"id": "d2831e7a-c4c2-4b25-92ae-0e13924b6a4d"/' /etc/xray/b.json

# Restart the service
echo "Restarting xray service..."
systemctl restart xray-b

# Check status
echo "Checking service status..."
systemctl status xray-b --no-pager
