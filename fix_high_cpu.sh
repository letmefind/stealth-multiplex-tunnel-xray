#!/bin/bash

echo "🔧 Fixing Xray High CPU Usage..."

# Kill all Xray processes
echo "1. Killing all Xray processes..."
sudo pkill -f xray
sleep 2

# Stop all Xray services
echo "2. Stopping all Xray services..."
sudo systemctl stop xray 2>/dev/null || true
sudo systemctl stop xray-a 2>/dev/null || true
sudo systemctl stop xray-b 2>/dev/null || true

# Disable services
echo "3. Disabling services..."
sudo systemctl disable xray 2>/dev/null || true
sudo systemctl disable xray-a 2>/dev/null || true
sudo systemctl disable xray-b 2>/dev/null || true

# Clean up old configs
echo "4. Cleaning up old configurations..."
sudo rm -f /etc/xray/a.json
sudo rm -f /etc/xray/b.json
sudo rm -f /etc/xray/config.json

# Remove old service files
echo "5. Removing old service files..."
sudo rm -f /etc/systemd/system/xray.service
sudo rm -f /etc/systemd/system/xray-a.service
sudo rm -f /etc/systemd/system/xray-b.service

# Reload systemd
echo "6. Reloading systemd..."
sudo systemctl daemon-reload

# Check for remaining processes
echo "7. Checking for remaining processes..."
REMAINING=$(ps aux | grep xray | grep -v grep | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    echo "⚠️  Still found $REMAINING Xray processes:"
    ps aux | grep xray | grep -v grep
    echo "Force killing..."
    sudo pkill -9 -f xray
fi

echo "✅ Cleanup complete!"
echo "📊 Current system status:"
echo "CPU usage:"
top -bn1 | grep "Cpu(s)"
echo "Memory usage:"
free -h | grep Mem
echo "Running processes:"
ps aux | grep xray | grep -v grep || echo "No Xray processes running"


