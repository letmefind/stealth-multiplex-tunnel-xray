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
    
    # Check Xray-M port (middle relay)
    if [[ -f "$XRAY_CONF_DIR/m.json" ]]; then
        local m_port=$(jq -r '.inbounds[0].port // empty' "$XRAY_CONF_DIR/m.json" 2>/dev/null)
        if [[ -n "$m_port" ]]; then
            if ss -tlnp 2>/dev/null | grep -q ":$m_port " || ss -ulnp 2>/dev/null | grep -q ":$m_port "; then
                log_success "Xray-M port $m_port: Listening"
            else
                log_error "Xray-M port $m_port: Not listening"
            fi
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

    if [[ -f "$XRAY_CONF_DIR/m.json" ]]; then
        if jq empty "$XRAY_CONF_DIR/m.json" 2>/dev/null; then
            log_success "Xray-M config: Valid JSON"
        else
            log_error "Xray-M config: Invalid JSON"
        fi
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
    
    if systemctl is-active --quiet xray-m 2>/dev/null; then
        local error_count=$(journalctl -u xray-m --since "1 hour ago" --no-pager | grep -c "error\|Error\|ERROR" || echo "0")
        if [[ "$error_count" -eq 0 ]]; then
            log_success "Xray-M logs: No errors in last hour"
        else
            log_warning "Xray-M logs: $error_count errors in last hour"
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

# Test connectivity (basic: tunnel port reachability from localhost)
test_connectivity() {
    log_info "Testing connectivity..."
    if [[ -f "$XRAY_CONF_DIR/b.json" ]]; then
        local xray_port=$(jq -r '.inbounds[] | select(.protocol == "vless") | .port' "$XRAY_CONF_DIR/b.json" 2>/dev/null | head -1)
        if [[ -n "$xray_port" && "$xray_port" != "null" ]]; then
            if ss -tlnp 2>/dev/null | grep -q ":$xray_port " || ss -ulnp 2>/dev/null | grep -q ":$xray_port "; then
                log_success "Xray-B inbound port $xray_port is bound"
            else
                log_warning "Xray-B inbound port $xray_port is not listening"
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
    [[ -f "$XRAY_CONF_DIR/a.json" ]] && check_service_status "xray-a"
    [[ -f "$XRAY_CONF_DIR/b.json" ]] && check_service_status "xray-b"
    [[ -f "$XRAY_CONF_DIR/m.json" ]] && check_service_status "xray-m"
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

    if [[ -f "$XRAY_CONF_DIR/a.json" ]] && ! check_service_status "xray-a"; then
        all_services_ok=false
    fi

    if [[ -f "$XRAY_CONF_DIR/b.json" ]] && ! check_service_status "xray-b"; then
        all_services_ok=false
    fi

    if [[ -f "$XRAY_CONF_DIR/m.json" ]] && ! check_service_status "xray-m"; then
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
            [[ -f "$XRAY_CONF_DIR/a.json" ]] && check_service_status "xray-a"
            [[ -f "$XRAY_CONF_DIR/b.json" ]] && check_service_status "xray-b"
            [[ -f "$XRAY_CONF_DIR/m.json" ]] && check_service_status "xray-m"
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
