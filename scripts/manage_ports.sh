#!/bin/bash

# Stealth Multiplex Tunnel Xray - Port Management Script
# Add, remove, or list ports on Server A

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
XRAY_CONF_DIR="/etc/xray"
CONFIG_FILE="$XRAY_CONF_DIR/a.json"

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

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install it first:"
        echo "apt-get update && apt-get install -y jq"
        exit 1
    fi
}

# Check if configuration file exists
check_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Xray configuration file not found: $CONFIG_FILE"
        log_error "Please run the Server A installer first: sudo bash scripts/install_a.sh"
        exit 1
    fi
}

# Validate port number
validate_port() {
    local port="$1"
    
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        log_error "Port must be a number"
        return 1
    fi
    
    if [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
        log_error "Port must be between 1 and 65535"
        return 1
    fi
    
    return 0
}

# Check if port is already configured
is_port_configured() {
    local port="$1"
    local config_file="$2"
    
    jq -e --arg port "$port" '.inbounds[] | select(.port == ($port | tonumber))' "$config_file" > /dev/null 2>&1
}

# Add a port
add_port() {
    local port="$1"
    
    log_info "Adding port $port..."
    
    # Validate port
    if ! validate_port "$port"; then
        exit 1
    fi
    
    # Check if port is already configured
    if is_port_configured "$port" "$CONFIG_FILE"; then
        log_warning "Port $port is already configured"
        return 0
    fi
    
    # Create backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add inbound
    local inbound='{
        "tag": "entry-'$port'",
        "listen": "0.0.0.0",
        "port": '$port',
        "protocol": "dokodemo-door",
        "settings": {
            "address": "127.0.0.1",
            "port": '$port',
            "network": "tcp"
        }
    }'
    
    # Add inbound to configuration
    local temp_config=$(mktemp)
    jq --argjson inbound "$inbound" '.inbounds += [$inbound]' "$CONFIG_FILE" > "$temp_config"
    
    # Add routing rule
    local routing_rule='{
        "type": "field",
        "inboundTag": ["entry-'$port'"],
        "outboundTag": "to-b"
    }'
    
    jq --argjson rule "$routing_rule" '.routing.rules += [$rule]' "$temp_config" > "$CONFIG_FILE"
    rm "$temp_config"
    
    # Validate JSON
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        log_error "Invalid JSON configuration. Restoring backup..."
        cp "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)" "$CONFIG_FILE"
        exit 1
    fi
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        ufw allow "$port/tcp"
        log_info "Firewall rule added for port $port"
    else
        log_warning "UFW not found. Please add firewall rule manually:"
        echo "iptables -A INPUT -p tcp --dport $port -j ACCEPT"
    fi
    
    # Reload Xray service
    systemctl reload xray-a
    
    if systemctl is-active --quiet xray-a; then
        log_success "Port $port added successfully"
    else
        log_error "Failed to reload Xray service"
        systemctl status xray-a
        exit 1
    fi
}

# Remove a port
remove_port() {
    local port="$1"
    
    log_info "Removing port $port..."
    
    # Validate port
    if ! validate_port "$port"; then
        exit 1
    fi
    
    # Check if port is configured
    if ! is_port_configured "$port" "$CONFIG_FILE"; then
        log_warning "Port $port is not configured"
        return 0
    fi
    
    # Create backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove inbound
    local temp_config=$(mktemp)
    jq --arg port "$port" 'del(.inbounds[] | select(.port == ($port | tonumber)))' "$CONFIG_FILE" > "$temp_config"
    
    # Remove routing rule
    jq --arg port "$port" 'del(.routing.rules[] | select(.inboundTag[] == "entry-" + $port))' "$temp_config" > "$CONFIG_FILE"
    rm "$temp_config"
    
    # Validate JSON
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        log_error "Invalid JSON configuration. Restoring backup..."
        cp "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)" "$CONFIG_FILE"
        exit 1
    fi
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        ufw delete allow "$port/tcp" 2>/dev/null || true
        log_info "Firewall rule removed for port $port"
    else
        log_warning "UFW not found. Please remove firewall rule manually:"
        echo "iptables -D INPUT -p tcp --dport $port -j ACCEPT"
    fi
    
    # Reload Xray service
    systemctl reload xray-a
    
    if systemctl is-active --quiet xray-a; then
        log_success "Port $port removed successfully"
    else
        log_error "Failed to reload Xray service"
        systemctl status xray-a
        exit 1
    fi
}

# List configured ports
list_ports() {
    log_info "Configured ports:"
    
    local ports=$(jq -r '.inbounds[] | select(.protocol == "dokodemo-door") | .port' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$ports" ]]; then
        log_warning "No ports configured"
        return 0
    fi
    
    echo "$ports" | sort -n | while read -r port; do
        if [[ -n "$port" ]]; then
            echo "  Port $port"
        fi
    done
    
    echo
    log_info "Total ports: $(echo "$ports" | wc -l)"
}

# Show usage
show_usage() {
    echo "Usage: $0 <command> [port]"
    echo
    echo "Commands:"
    echo "  add <port>    Add a new port"
    echo "  remove <port> Remove a port"
    echo "  list          List all configured ports"
    echo "  help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 add 8443"
    echo "  $0 remove 8080"
    echo "  $0 list"
    echo
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "add")
            if [[ $# -ne 2 ]]; then
                log_error "Port number required for add command"
                show_usage
                exit 1
            fi
            
            check_root
            check_jq
            check_config
            add_port "$2"
            ;;
        "remove")
            if [[ $# -ne 2 ]]; then
                log_error "Port number required for remove command"
                show_usage
                exit 1
            fi
            
            check_root
            check_jq
            check_config
            remove_port "$2"
            ;;
        "list")
            check_root
            check_jq
            check_config
            list_ports
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
