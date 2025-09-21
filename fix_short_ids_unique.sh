#!/bin/bash

# Fix short IDs to be unique
echo "Generating 20 unique short IDs..."

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

echo "Generated unique short IDs: $SHORT_IDS"

# Fix Server A configuration
echo "Fixing Server A configuration..."
sed -i "s/\"shortId\": \"[^\"]*\"/\"shortId\": \"$(echo "$SHORT_IDS" | cut -d',' -f1 | tr -d '"' | tr -d ' ')\"/" /etc/xray/a.json

# Fix Server B configuration  
echo "Fixing Server B configuration..."
sed -i "s/\"shortIds\": \[[^]]*\]/\"shortIds\": [$SHORT_IDS]/" /etc/xray/b.json

echo "Fixed both configurations with unique short IDs"

# Restart services
echo "Restarting services..."
systemctl restart xray-a
systemctl restart xray-b

echo "Services restarted. Checking status..."
systemctl status xray-a --no-pager
echo "---"
systemctl status xray-b --no-pager
