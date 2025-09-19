#!/bin/bash

# Xray Conflict Resolution Script
# Helps resolve conflicts between existing Xray service and new installation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check existing Xray services
check_existing_services() {
    log_info "Checking existing Xray services..."
    
    # Check for existing xray service
    if systemctl is-active --quiet xray; then
        log_warning "Existing xray.service is running"
        systemctl status xray --no-pager -l
        echo
    fi
    
    # Check for our new service
    if systemctl is-active --quiet xray-a; then
        log_warning "xray-a.service is running"
        systemctl status xray-a --no-pager -l
        echo
    fi
    
    # Check listening ports
    log_info "Checking listening ports..."
    ss -tlnp | grep -E ':(80|443|8080|8443|8081)\s' || log_info "No conflicting ports found"
    echo
}

# Check configuration files
check_config_files() {
    log_info "Checking configuration files..."
    
    # Check existing config
    if [[ -f "/usr/local/etc/xray/config.json" ]]; then
        log_warning "Existing Xray config found: /usr/local/etc/xray/config.json"
        echo "Ports used by existing config:"
        jq -r '.inbounds[]? | select(.port) | "Port \(.port): \(.protocol // "unknown")"' /usr/local/etc/xray/config.json 2>/dev/null || log_info "Could not parse existing config"
        echo
    fi
    
    # Check our new config
    if [[ -f "/etc/xray/a.json" ]]; then
        log_info "New Xray config found: /etc/xray/a.json"
        echo "Ports used by new config:"
        jq -r '.inbounds[]? | select(.port) | "Port \(.port): \(.protocol // "unknown")"' /etc/xray/a.json 2>/dev/null || log_info "Could not parse new config"
        echo
    fi
}

# Show resolution options
show_resolution_options() {
    echo
    log_info "Resolution Options:"
    echo
    echo "1) Stop existing Xray service and use our new installation"
    echo "2) Use different ports for our new installation"
    echo "3) Remove our installation and keep existing Xray"
    echo "4) Show detailed port analysis"
    echo "5) Exit"
    echo
}

# Stop existing Xray service
stop_existing_service() {
    log_info "Stopping existing Xray service..."
    
    systemctl stop xray
    systemctl disable xray
    
    log_success "Existing Xray service stopped and disabled"
    
    # Try to start our service
    log_info "Starting our Xray service..."
    systemctl start xray-a
    
    if systemctl is-active --quiet xray-a; then
        log_success "Our Xray service started successfully!"
    else
        log_error "Failed to start our Xray service"
        systemctl status xray-a --no-pager -l
    fi
}

# Change ports for our installation
change_ports() {
    log_info "Changing ports for our installation..."
    
    # Stop our service first
    systemctl stop xray-a 2>/dev/null || true
    
    # Read current config
    if [[ -f "/etc/xray/a.json" ]]; then
        # Create backup
        cp /etc/xray/a.json /etc/xray/a.json.backup
        
        # Change ports (add 1000 to each port)
        jq '.inbounds[] |= if .port then .port + 1000 else . end' /etc/xray/a.json > /etc/xray/a.json.tmp
        mv /etc/xray/a.json.tmp /etc/xray/a.json
        
        log_success "Ports changed (added 1000 to each port)"
        echo "New ports:"
        jq -r '.inbounds[]? | select(.port) | "Port \(.port): \(.protocol // "unknown")"' /etc/xray/a.json
        
        # Update firewall rules
        log_info "Updating firewall rules..."
        if command -v ufw &> /dev/null; then
            # Remove old rules
            ufw delete allow 80/tcp 2>/dev/null || true
            ufw delete allow 443/tcp 2>/dev/null || true
            ufw delete allow 8080/tcp 2>/dev/null || true
            ufw delete allow 8443/tcp 2>/dev/null || true
            
            # Add new rules
            ufw allow 1080/tcp
            ufw allow 1443/tcp
            ufw allow 9080/tcp
            ufw allow 9443/tcp
            
            log_success "Firewall rules updated"
        fi
        
        # Try to start our service
        log_info "Starting our Xray service with new ports..."
        systemctl start xray-a
        
        if systemctl is-active --quiet xray-a; then
            log_success "Our Xray service started successfully with new ports!"
        else
            log_error "Failed to start our Xray service"
            systemctl status xray-a --no-pager -l
        fi
    else
        log_error "Configuration file not found: /etc/xray/a.json"
    fi
}

# Remove our installation
remove_our_installation() {
    log_info "Removing our Xray installation..."
    
    # Stop our service
    systemctl stop xray-a 2>/dev/null || true
    systemctl disable xray-a 2>/dev/null || true
    
    # Remove service file
    rm -f /etc/systemd/system/xray-a.service
    systemctl daemon-reload
    
    # Remove configuration
    rm -f /etc/xray/a.json
    
    # Remove firewall rules
    if command -v ufw &> /dev/null; then
        ufw delete allow 80/tcp 2>/dev/null || true
        ufw delete allow 443/tcp 2>/dev/null || true
        ufw delete allow 8080/tcp 2>/dev/null || true
        ufw delete allow 8443/tcp 2>/dev/null || true
    fi
    
    log_success "Our Xray installation removed"
    log_info "Existing Xray service is still running"
}

# Show detailed port analysis
show_port_analysis() {
    log_info "Detailed Port Analysis:"
    echo
    
    echo "=== Listening Ports ==="
    ss -tlnp | grep -E ':(80|443|8080|8443|8081|1080|1443|9080|9443)\s' || log_info "No relevant ports found"
    echo
    
    echo "=== Process Information ==="
    ps aux | grep xray | grep -v grep || log_info "No Xray processes found"
    echo
    
    echo "=== Service Status ==="
    systemctl status xray --no-pager -l 2>/dev/null || log_info "xray.service not found"
    echo
    systemctl status xray-a --no-pager -l 2>/dev/null || log_info "xray-a.service not found"
    echo
}

# Main menu
main_menu() {
    while true; do
        show_resolution_options
        read -p "Select an option [1-5]: " choice
        
        case $choice in
            1)
                stop_existing_service
                break
                ;;
            2)
                change_ports
                break
                ;;
            3)
                remove_our_installation
                break
                ;;
            4)
                show_port_analysis
                ;;
            5)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please select 1-5."
                ;;
        esac
    done
}

# Main function
main() {
    check_root
    check_existing_services
    check_config_files
    main_menu
}

# Run main function
main "$@"
