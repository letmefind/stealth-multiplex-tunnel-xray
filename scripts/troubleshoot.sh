#!/bin/bash

# Xray Service Troubleshooting Script
# This script helps diagnose and fix common Xray service issues

set -e

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

# Stop Xray service
stop_xray_service() {
    log_info "Stopping Xray service..."
    systemctl stop xray-a 2>/dev/null || true
    systemctl stop xray-b 2>/dev/null || true
    log_success "Xray services stopped"
}

# Check file permissions
check_permissions() {
    log_info "Checking file permissions..."
    
    local config_files=("/etc/xray/a.json" "/etc/xray/b.json")
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            log_info "Checking $config_file"
            ls -la "$config_file"
            
            # Check if file is readable
            if [[ -r "$config_file" ]]; then
                log_success "$config_file is readable"
            else
                log_error "$config_file is not readable"
                log_info "Fixing permissions for $config_file..."
                chmod 644 "$config_file"
                chown root:root "$config_file"
                log_success "Permissions fixed for $config_file"
            fi
        else
            log_warning "$config_file does not exist"
        fi
    done
}

# Check port conflicts
check_port_conflicts() {
    log_info "Checking for port conflicts..."
    
    local ports=("80" "443" "8080" "8081" "8443")
    
    for port in "${ports[@]}"; do
        local process=$(netstat -tlnp 2>/dev/null | grep ":$port " | head -1)
        if [[ -n "$process" ]]; then
            log_warning "Port $port is in use: $process"
            
            # Extract PID
            local pid=$(echo "$process" | awk '{print $7}' | cut -d'/' -f1)
            if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]]; then
                local process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                log_info "Process using port $port: PID $pid ($process_name)"
                
                # Ask if user wants to kill the process
                read -p "Do you want to kill process $pid ($process_name) using port $port? [y/N]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Killing process $pid..."
                    kill "$pid" 2>/dev/null || true
                    sleep 2
                    if kill -0 "$pid" 2>/dev/null; then
                        log_warning "Process still running, force killing..."
                        kill -9 "$pid" 2>/dev/null || true
                    fi
                    log_success "Process $pid killed"
                fi
            fi
        else
            log_success "Port $port is free"
        fi
    done
}

# Check systemd service configuration
check_service_config() {
    log_info "Checking systemd service configuration..."
    
    local services=("xray-a" "xray-b")
    
    for service in "${services[@]}"; do
        if [[ -f "/etc/systemd/system/$service.service" ]]; then
            log_info "Checking $service.service configuration..."
            
            # Check if service runs as non-root user
            if grep -q "User=" "/etc/systemd/system/$service.service"; then
                local user=$(grep "User=" "/etc/systemd/system/$service.service" | cut -d'=' -f2)
                log_warning "$service runs as user: $user"
                
                read -p "Do you want to change $service to run as root? [y/N]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Modifying $service.service to run as root..."
                    sed -i '/^User=/d' "/etc/systemd/system/$service.service"
                    sed -i '/^Group=/d' "/etc/systemd/system/$service.service"
                    log_success "$service.service modified to run as root"
                fi
            else
                log_success "$service runs as root"
            fi
        else
            log_warning "/etc/systemd/system/$service.service does not exist"
        fi
    done
}

# Validate Xray configuration
validate_config() {
    log_info "Validating Xray configuration..."
    
    local config_files=("/etc/xray/a.json" "/etc/xray/b.json")
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            log_info "Validating $config_file..."
            
            # Check JSON syntax
            if command -v jq >/dev/null 2>&1; then
                if jq . "$config_file" >/dev/null 2>&1; then
                    log_success "$config_file has valid JSON syntax"
                else
                    log_error "$config_file has invalid JSON syntax"
                    log_info "JSON validation output:"
                    jq . "$config_file" 2>&1 || true
                fi
            else
                log_warning "jq not found, skipping JSON validation"
            fi
            
            # Test with Xray
            if command -v xray >/dev/null 2>&1; then
                log_info "Testing $config_file with Xray..."
                if xray run -test -config "$config_file" 2>&1 | grep -q "Configuration OK"; then
                    log_success "$config_file passed Xray validation"
                else
                    log_error "$config_file failed Xray validation"
                    log_info "Xray validation output:"
                    xray run -test -config "$config_file" 2>&1 || true
                fi
            else
                log_warning "Xray not found, skipping configuration test"
            fi
        fi
    done
}

# Check Xray installation
check_xray_installation() {
    log_info "Checking Xray installation..."
    
    if command -v xray >/dev/null 2>&1; then
        local xray_version=$(xray version 2>/dev/null | head -1 || echo "unknown")
        log_success "Xray is installed: $xray_version"
        
        # Check if Xray binary is executable
        if [[ -x "$(which xray)" ]]; then
            log_success "Xray binary is executable"
        else
            log_error "Xray binary is not executable"
            log_info "Fixing Xray binary permissions..."
            chmod +x "$(which xray)"
            log_success "Xray binary permissions fixed"
        fi
    else
        log_error "Xray is not installed or not in PATH"
        log_info "Please install Xray first"
        exit 1
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    local dirs=("/etc/xray" "/var/log/xray" "/usr/local/bin")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_info "Creating directory: $dir"
            mkdir -p "$dir"
            chmod 755 "$dir"
            log_success "Directory $dir created"
        else
            log_success "Directory $dir exists"
        fi
    done
}

# Reload systemd and start services
reload_and_start() {
    log_info "Reloading systemd and starting services..."
    
    # Reload systemd
    systemctl daemon-reload
    log_success "Systemd reloaded"
    
    # Start services
    local services=("xray-a" "xray-b")
    
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            log_info "Starting $service..."
            if systemctl start "$service"; then
                sleep 2
                if systemctl is-active "$service" >/dev/null 2>&1; then
                    log_success "$service started successfully"
                else
                    log_error "$service failed to start"
                    log_info "Service status:"
                    systemctl status "$service" --no-pager -l
                fi
            else
                log_error "Failed to start $service"
            fi
        else
            log_warning "$service is not enabled"
        fi
    done
}

# Show service status
show_status() {
    log_info "Current service status:"
    echo
    
    local services=("xray-a" "xray-b")
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            echo "=== $service.service ==="
            systemctl status "$service" --no-pager -l
            echo
        fi
    done
}

# Main function
main() {
    echo "=========================================="
    echo "    Xray Service Troubleshooting Script"
    echo "=========================================="
    echo
    
    check_root
    
    log_info "Starting Xray service troubleshooting..."
    echo
    
    # Run all checks and fixes
    stop_xray_service
    echo
    
    check_xray_installation
    echo
    
    create_directories
    echo
    
    check_permissions
    echo
    
    check_port_conflicts
    echo
    
    check_service_config
    echo
    
    validate_config
    echo
    
    reload_and_start
    echo
    
    show_status
    
    log_success "Troubleshooting completed!"
    echo
    log_info "If services are still not working, check the logs with:"
    log_info "  journalctl -u xray-a.service -f"
    log_info "  journalctl -u xray-b.service -f"
}

# Run main function
main "$@"
