#!/bin/bash

# Quick fix for short IDs configuration
echo "Fixing short IDs in /etc/xray/a.json..."

# Generate 20 unique short IDs
SHORT_IDS=""
for i in {1..20}; do
    SHORT_ID=$(openssl rand -hex 8 2>/dev/null)
    if [ $i -eq 1 ]; then
        SHORT_IDS="\"$SHORT_ID\""
    else
        SHORT_IDS="$SHORT_IDS, \"$SHORT_ID\""
    fi
done

echo "Generated short IDs: $SHORT_IDS"

# Fix the JSON configuration
sed -i "s/\"shortIds\": \"[^\"]*\"/\"shortIds\": [$SHORT_IDS]/" /etc/xray/a.json

echo "Fixed /etc/xray/a.json"
echo "Restarting xray service..."

systemctl restart xray-a
systemctl status xray-a
