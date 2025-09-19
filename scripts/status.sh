#!/bin/bash

# Stealth Multiplex Tunnel Xray - Status Monitor
# Monitors the health and status of the tunnel system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
XRAY_CONF_DIR="/etc/xray"
NGINX_CONF_DIR="/etc/nginx/conf.d"

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

# Check service status
check_service_status() {
    local service="$1"
    local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
    
    if [[ "$status" == "active" ]]; then
        log_success "$service: Running"
        return 0
    else
        log_error "$service: Not running"
        return 1
    fi
}

# Check listening ports
check_listening_ports() {
    log_info "Checking listening ports..."
    
    # Check Xray-A ports (Server A)
    if [[ -f "$XRAY_CONF_DIR/a.json" ]]; then
        local ports=$(jq -r '.inbounds[] | select(.protocol == "dokodemo-door") | .port' "$XRAY_CONF_DIR/a.json" 2>/dev/null)
        
        if [[ -n "$ports" ]]; then
            echo "$ports" | while read -r port; do
                if [[ -n "$port" ]]; then
                    if ss -tlnp | grep -q ":$port "; then
                        log_success "Port $port: Listening"
                    else
                        log_error "Port $port: Not listening"
                    fi
                fi
            done
        fi
    fi
    
    # Check Xray-B port (Server B)
    if [[ -f "$XRAY_CONF_DIR/b.json" ]]; then
        local xray_port=$(jq -r '.inbounds[] | select(.protocol == "vless" or .protocol == "trojan") | .port' "$XRAY_CONF_DIR/b.json" 2>/dev/null)
        
        if [[ -n "$xray_port" ]]; then
            if ss -tlnp | grep -q "127.0.0.1:$xray_port "; then
                log_success "Xray-B port $xray_port: Listening"
            else
                log_error "Xray-B port $xray_port: Not listening"
            fi
        fi
    fi
    
    # Check Nginx ports
    if [[ -d "$NGINX_CONF_DIR" ]]; then
        local nginx_ports=$(grep -h "listen" "$NGINX_CONF_DIR"/*.conf 2>/dev/null | grep -o '[0-9]\+' | sort -u)
        
        if [[ -n "$nginx_ports" ]]; then
            echo "$nginx_ports" | while read -r port; do
                if [[ -n "$port" ]]; then
                    if ss -tlnp | grep -q ":$port "; then
                        log_success "Nginx port $port: Listening"
                    else
                        log_error "Nginx port $port: Not listening"
                    fi
                fi
            done
        fi
    fi
}

# Check configuration files
check_config_files() {
    log_info "Checking configuration files..."
    
    # Check Xray configurations
    if [[ -f "$XRAY_CONF_DIR/a.json" ]]; then
        if jq empty "$XRAY_CONF_DIR/a.json" 2>/dev/null; then
            log_success "Xray-A config: Valid JSON"
        else
            log_error "Xray-A config: Invalid JSON"
        fi
    else
        log_warning "Xray-A config: Not found"
    fi
    
    if [[ -f "$XRAY_CONF_DIR/b.json" ]]; then
        if jq empty "$XRAY_CONF_DIR/b.json" 2>/dev/null; then
            log_success "Xray-B config: Valid JSON"
        else
            log_error "Xray-B config: Invalid JSON"
        fi
    else
        log_warning "Xray-B config: Not found"
    fi
    
    # Check Nginx configuration
    if command -v nginx &> /dev/null; then
        if nginx -t 2>/dev/null; then
            log_success "Nginx config: Valid"
        else
            log_error "Nginx config: Invalid"
        fi
    else
        log_warning "Nginx: Not installed"
    fi
}

# Check logs
check_logs() {
    log_info "Checking recent logs..."
    
    # Check Xray-A logs
    if systemctl is-active --quiet xray-a; then
        local error_count=$(journalctl -u xray-a --since "1 hour ago" --no-pager | grep -c "error\|Error\|ERROR" || echo "0")
        if [[ "$error_count" -eq 0 ]]; then
            log_success "Xray-A logs: No errors in last hour"
        else
            log_warning "Xray-A logs: $error_count errors in last hour"
        fi
    fi
    
    # Check Xray-B logs
    if systemctl is-active --quiet xray-b; then
        local error_count=$(journalctl -u xray-b --since "1 hour ago" --no-pager | grep -c "error\|Error\|ERROR" || echo "0")
        if [[ "$error_count" -eq 0 ]]; then
            log_success "Xray-B logs: No errors in last hour"
        else
            log_warning "Xray-B logs: $error_count errors in last hour"
        fi
    fi
    
    # Check Nginx logs
    if systemctl is-active --quiet nginx; then
        local error_count=$(journalctl -u nginx --since "1 hour ago" --no-pager | grep -c "error\|Error\|ERROR" || echo "0")
        if [[ "$error_count" -eq 0 ]]; then
            log_success "Nginx logs: No errors in last hour"
        else
            log_warning "Nginx logs: $error_count errors in last hour"
        fi
    fi
}

# Check system resources
check_system_resources() {
    log_info "Checking system resources..."
    
    # Check memory usage
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$memory_usage < 80" | bc -l) )); then
        log_success "Memory usage: ${memory_usage}%"
    else
        log_warning "Memory usage: ${memory_usage}% (high)"
    fi
    
    # Check disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ "$disk_usage" -lt 80 ]]; then
        log_success "Disk usage: ${disk_usage}%"
    else
        log_warning "Disk usage: ${disk_usage}% (high)"
    fi
    
    # Check load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=$(nproc)
    if (( $(echo "$load_avg < $cpu_cores" | bc -l) )); then
        log_success "Load average: $load_avg (cores: $cpu_cores)"
    else
        log_warning "Load average: $load_avg (cores: $cpu_cores) (high)"
    fi
}

# Test connectivity
test_connectivity() {
    log_info "Testing connectivity..."
    
    # Get server configuration
    if [[ -f "$XRAY_CONF_DIR/b.json" ]]; then
        local server_name=$(jq -r '.inbounds[] | select(.protocol == "vless" or .protocol == "trojan") | .streamSettings.splithttpSettings.host' "$XRAY_CONF_DIR/b.json" 2>/dev/null)
        local stealth_path=$(jq -r '.inbounds[] | select(.protocol == "vless" or .protocol == "trojan") | .streamSettings.splithttpSettings.path' "$XRAY_CONF_DIR/b.json" 2>/dev/null)
        local tls_port=$(grep -h "listen" "$NGINX_CONF_DIR"/*.conf 2>/dev/null | grep -o '[0-9]\+' | head -1)
        
        if [[ -n "$server_name" && -n "$tls_port" ]]; then
            # Test decoy site
            if curl -s -I "https://$server_name:$tls_port/" | grep -q "200 OK"; then
                log_success "Decoy site: Accessible"
            else
                log_warning "Decoy site: Not accessible"
            fi
            
            # Test stealth path (should not expose obvious tunnel)
            if curl -s -I "https://$server_name:$tls_port$stealth_path" | grep -q "502\|503\|504"; then
                log_success "Stealth path: Responding (tunnel active)"
            else
                log_warning "Stealth path: Unexpected response"
            fi
        fi
    fi
}

# Show detailed status
show_detailed_status() {
    echo
    log_info "=== DETAILED STATUS REPORT ==="
    echo
    
    # Service status
    log_info "Service Status:"
    check_service_status "xray-a"
    check_service_status "xray-b"
    check_service_status "nginx"
    echo
    
    # Listening ports
    check_listening_ports
    echo
    
    # Configuration files
    check_config_files
    echo
    
    # System resources
    check_system_resources
    echo
    
    # Recent logs
    check_logs
    echo
    
    # Connectivity test
    test_connectivity
    echo
    
    log_info "=== END OF REPORT ==="
}

# Show quick status
show_quick_status() {
    echo
    log_info "=== QUICK STATUS ==="
    echo
    
    # Service status only
    local all_services_ok=true
    
    if ! check_service_status "xray-a"; then
        all_services_ok=false
    fi
    
    if ! check_service_status "xray-b"; then
        all_services_ok=false
    fi
    
    if ! check_service_status "nginx"; then
        all_services_ok=false
    fi
    
    echo
    
    if [[ "$all_services_ok" == true ]]; then
        log_success "All services are running"
    else
        log_error "Some services are not running"
    fi
    
    echo
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  status          Show detailed status report"
    echo "  quick           Show quick status"
    echo "  services        Check service status only"
    echo "  ports           Check listening ports only"
    echo "  configs         Check configuration files only"
    echo "  logs            Check recent logs only"
    echo "  resources       Check system resources only"
    echo "  connectivity    Test connectivity only"
    echo "  help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 quick"
    echo "  $0 services"
    echo
}

# Main function
main() {
    local command="${1:-status}"
    
    case "$command" in
        "status")
            check_root
            show_detailed_status
            ;;
        "quick")
            check_root
            show_quick_status
            ;;
        "services")
            check_root
            check_service_status "xray-a"
            check_service_status "xray-b"
            check_service_status "nginx"
            ;;
        "ports")
            check_root
            check_listening_ports
            ;;
        "configs")
            check_root
            check_config_files
            ;;
        "logs")
            check_root
            check_logs
            ;;
        "resources")
            check_root
            check_system_resources
            ;;
        "connectivity")
            check_root
            test_connectivity
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
