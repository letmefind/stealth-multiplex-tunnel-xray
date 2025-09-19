#!/bin/bash

# Quick Fix Script for Xray Permission Issues
# This script quickly fixes the most common Xray service issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

echo "=========================================="
echo "    Xray Quick Fix Script"
echo "=========================================="
echo

log_info "Starting quick fix for Xray service issues..."

# Step 1: Stop services
log_info "Stopping Xray services..."
systemctl stop xray-a 2>/dev/null || true
systemctl stop xray-b 2>/dev/null || true
log_success "Services stopped"

# Step 2: Fix file permissions
log_info "Fixing file permissions..."
chmod 644 /etc/xray/a.json 2>/dev/null || true
chmod 644 /etc/xray/b.json 2>/dev/null || true
chown root:root /etc/xray/a.json 2>/dev/null || true
chown root:root /etc/xray/b.json 2>/dev/null || true
log_success "File permissions fixed"

# Step 3: Fix service configuration to run as root
log_info "Fixing service configuration..."
sed -i '/^User=/d' /etc/systemd/system/xray-a.service 2>/dev/null || true
sed -i '/^Group=/d' /etc/systemd/system/xray-a.service 2>/dev/null || true
sed -i '/^User=/d' /etc/systemd/system/xray-b.service 2>/dev/null || true
sed -i '/^Group=/d' /etc/systemd/system/xray-b.service 2>/dev/null || true
log_success "Service configuration fixed"

# Step 4: Kill conflicting processes on common ports
log_info "Checking for port conflicts..."
for port in 80 443 8080 8081 8443; do
    pid=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
        process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
        log_warning "Killing process $pid ($process_name) using port $port"
        kill "$pid" 2>/dev/null || true
        sleep 1
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
done
log_success "Port conflicts resolved"

# Step 5: Create necessary directories
log_info "Creating necessary directories..."
mkdir -p /etc/xray /var/log/xray
chmod 755 /etc/xray /var/log/xray
log_success "Directories created"

# Step 6: Reload systemd and start services
log_info "Reloading systemd..."
systemctl daemon-reload
log_success "Systemd reloaded"

log_info "Starting Xray services..."
systemctl start xray-a 2>/dev/null || true
systemctl start xray-b 2>/dev/null || true

# Step 7: Check status
echo
log_info "Checking service status..."
echo

for service in xray-a xray-b; do
    if systemctl list-unit-files | grep -q "$service.service"; then
        echo "=== $service.service ==="
        if systemctl is-active "$service" >/dev/null 2>&1; then
            log_success "$service is running"
        else
            log_error "$service is not running"
            echo "Status:"
            systemctl status "$service" --no-pager -l
        fi
        echo
    fi
done

log_success "Quick fix completed!"
echo
log_info "If services are still not working, run the full troubleshooting script:"
log_info "  ./scripts/troubleshoot.sh"
echo
log_info "To check logs:"
log_info "  journalctl -u xray-a.service -f"
log_info "  journalctl -u xray-b.service -f"
