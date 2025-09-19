#!/bin/bash

# Stealth Multiplex Tunnel Xray - Unified Installer
# Asks user which server they're installing and runs the appropriate installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Display welcome message
show_welcome() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    Stealth Multiplex Tunnel Xray                            ║"
    echo "║                        Unified Installer                                     ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo "║  This installer will help you set up a stealth tunnel solution with:       ║"
    echo "║  • VLESS/Trojan protocols                                                  ║"
    echo "║  • TLS/Reality security                                                     ║"
    echo "║  • Multi-port support                                                       ║"
    echo "║  • Interactive configuration                                               ║"
    echo "║  • Production-ready setup                                                  ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo
}

# Display server selection menu
show_server_menu() {
    echo
    log_info "Please select which server you are installing:"
    echo
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│  SERVER A (Entry) - Where clients connect                                    │"
    echo "│  • Listens on multiple ports (80, 443, 8080, 8443, etc.)                   │"
    echo "│  • Forwards traffic through stealth tunnel to Server B                      │"
    echo "│  • Can be any server with public IP                                         │"
    echo "│  • Preserves original port numbers                                          │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│  SERVER B (Receiver) - Where traffic is delivered                           │"
    echo "│  • Receives tunneled traffic behind Nginx with TLS                         │"
    echo "│  • Serves decoy website                                                     │"
    echo "│  • Delivers traffic to localhost on same port as client                     │"
    echo "│  • Requires domain name and valid certificate                              │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo
}

# Get server selection from user
get_server_selection() {
    while true; do
        echo "Select server type:"
        echo "1) Server A (Entry) - Client connection point"
        echo "2) Server B (Receiver) - Traffic destination"
        echo "3) Show detailed information"
        echo "4) Exit"
        echo
        read -p "Enter your choice [1-4]: " SERVER_CHOICE
        
        case $SERVER_CHOICE in
            1)
                SERVER_TYPE="A"
                SERVER_NAME="Entry"
                break
                ;;
            2)
                SERVER_TYPE="B"
                SERVER_NAME="Receiver"
                break
                ;;
            3)
                show_detailed_info
                ;;
            4)
                log_info "Installation cancelled"
                exit 0
                ;;
            "")
                log_error "Please select a valid option"
                ;;
            *)
                log_error "Invalid choice. Please select 1, 2, 3, or 4"
                ;;
        esac
    done
}

# Show detailed information
show_detailed_info() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                            DETAILED INFORMATION                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo
    echo "🔹 SERVER A (Entry) - Client Connection Point"
    echo "   • Purpose: Accepts client connections and forwards them through tunnel"
    echo "   • Ports: Listens on multiple ports (80, 443, 8080, 8443, etc.)"
    echo "   • Protocol: VLESS or Trojan with TLS/Reality security"
    echo "   • Transport: SplitHTTP (VLESS) or TCP (Trojan)"
    echo "   • Requirements: Public IP, no domain needed"
    echo "   • Installation: Run this script and select Server A"
    echo
    echo "🔹 SERVER B (Receiver) - Traffic Destination"
    echo "   • Purpose: Receives tunneled traffic and delivers to local services"
    echo "   • Setup: Nginx + Xray behind TLS termination"
    echo "   • Features: Decoy website, stealth tunnel path"
    echo "   • Requirements: Domain name, valid SSL certificate"
    echo "   • Installation: Run this script and select Server B"
    echo
    echo "🔹 INSTALLATION ORDER"
    echo "   1. Install Server B first (generates UUID and Reality keys)"
    echo "   2. Install Server A second (uses same configuration)"
    echo
    echo "🔹 CONFIGURATION MATCHING"
    echo "   • Both servers must use identical configuration"
    echo "   • UUID must match exactly"
    echo "   • Protocol and security must match"
    echo "   • Reality keys must match (if using Reality)"
    echo
    echo "🔹 TESTING"
    echo "   • Test decoy site: curl -I https://your-domain.com:8081/"
    echo "   • Test tunnel: curl -I https://your-domain.com:8081/assets"
    echo "   • End-to-end: nc server-a-ip 8080 → should appear on Server B"
    echo
    read -p "Press Enter to continue..."
    echo
}

# Confirm server selection
confirm_selection() {
    echo
    log_info "You have selected: Server $SERVER_TYPE ($SERVER_NAME)"
    echo
    echo "This will install:"
    if [[ "$SERVER_TYPE" == "A" ]]; then
        echo "  • Xray with multiple inbound ports"
        echo "  • Dokodemo-door inbounds for each port"
        echo "  • VLESS/Trojan outbound to Server B"
        echo "  • TLS/Reality security configuration"
        echo "  • Systemd service (xray-a)"
        echo "  • Firewall configuration"
        echo "  • TCP BBR optimization (optional)"
    else
        echo "  • Xray with VLESS/Trojan inbound"
        echo "  • Nginx with TLS termination"
        echo "  • Decoy website"
        echo "  • Stealth tunnel configuration"
        echo "  • Systemd service (xray-b)"
        echo "  • Firewall configuration"
        echo "  • Certificate management (Certbot or existing)"
        echo "  • TCP BBR optimization (optional)"
    fi
    echo
    
    read -p "Continue with Server $SERVER_TYPE installation? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-"y"}
    
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
}

# Check if installer script exists
check_installer_script() {
    local installer_script="$SCRIPT_DIR/scripts/install_${SERVER_TYPE,,}.sh"
    
    if [[ ! -f "$installer_script" ]]; then
        log_error "Installer script not found: $installer_script"
        log_error "Please ensure all installation scripts are present"
        exit 1
    fi
    
    if [[ ! -x "$installer_script" ]]; then
        log_warning "Making installer script executable..."
        chmod +x "$installer_script"
    fi
}

# Run the appropriate installer
run_installer() {
    local installer_script="$SCRIPT_DIR/scripts/install_${SERVER_TYPE,,}.sh"
    
    log_info "Starting Server $SERVER_TYPE installation..."
    echo
    
    # Run the installer script
    bash "$installer_script"
    
    if [[ $? -eq 0 ]]; then
        echo
        log_success "Server $SERVER_TYPE installation completed successfully!"
        echo
        show_post_installation_info
    else
        log_error "Server $SERVER_TYPE installation failed"
        exit 1
    fi
}

# Show post-installation information
show_post_installation_info() {
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                        POST-INSTALLATION INFORMATION                       ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo
    
    if [[ "$SERVER_TYPE" == "A" ]]; then
        echo "🔹 SERVER A (Entry) - Next Steps:"
        echo "   1. Install Server B using: sudo bash scripts/install_b.sh"
        echo "   2. Use the same UUID and configuration values"
        echo "   3. Test connectivity from clients"
        echo
        echo "🔹 Management Commands:"
        echo "   • Check status: sudo bash scripts/status.sh quick"
        echo "   • Add ports: sudo bash scripts/manage_ports.sh add 8443"
        echo "   • Remove ports: sudo bash scripts/manage_ports.sh remove 8080"
        echo "   • List ports: sudo bash scripts/manage_ports.sh list"
        echo
        echo "🔹 Testing:"
        echo "   • Check listening ports: ss -tlnp | grep -E ':(80|443|8080|8443)\\s'"
        echo "   • Check service: systemctl status xray-a"
        echo "   • View logs: journalctl -u xray-a -e"
    else
        echo "🔹 SERVER B (Receiver) - Next Steps:"
        echo "   1. Install Server A using: sudo bash scripts/install_a.sh"
        echo "   2. Use the same UUID and configuration values"
        echo "   3. Test decoy site and tunnel"
        echo
        echo "🔹 Management Commands:"
        echo "   • Check status: sudo bash scripts/status.sh quick"
        echo "   • Test decoy: curl -I https://your-domain.com:8081/"
        echo "   • Test tunnel: curl -I https://your-domain.com:8081/assets"
        echo "   • Check service: systemctl status xray-b"
        echo "   • View logs: journalctl -u xray-b -e"
        echo
        echo "🔹 Certificate Management:"
        echo "   • Renew certificates: certbot renew"
        echo "   • Check certificate: openssl x509 -in /etc/letsencrypt/live/your-domain.com/cert.pem -text -noout"
    fi
    
    echo
    echo "🔹 Additional Tools:"
    echo "   • Backup config: sudo bash scripts/backup_config.sh create"
    echo "   • Restore config: sudo bash scripts/backup_config.sh restore backup_name"
    echo "   • Full status: sudo bash scripts/status.sh status"
    echo "   • Help: sudo bash scripts/status.sh help"
    echo
    echo "🔹 Documentation:"
    echo "   • README.md - Complete installation guide"
    echo "   • CONFIGURATION_EXAMPLES.md - Configuration examples"
    echo "   • PROJECT_SUMMARY.md - Project overview"
    echo
}

# Show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --server-a    Install Server A (Entry) directly"
    echo "  --server-b    Install Server B (Receiver) directly"
    echo "  --help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Interactive server selection"
    echo "  $0 --server-a         # Install Server A directly"
    echo "  $0 --server-b         # Install Server B directly"
    echo
}

# Main function
main() {
    # Parse command line arguments
    case "${1:-}" in
        "--server-a")
            SERVER_TYPE="A"
            SERVER_NAME="Entry"
            ;;
        "--server-b")
            SERVER_TYPE="B"
            SERVER_NAME="Receiver"
            ;;
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        "")
            # Interactive mode
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # Check root privileges
    check_root
    
    # Show welcome message
    show_welcome
    
    # If no server type specified, ask user
    if [[ -z "${SERVER_TYPE:-}" ]]; then
        show_server_menu
        get_server_selection
        confirm_selection
    fi
    
    # Check installer script exists
    check_installer_script
    
    # Run the appropriate installer
    run_installer
}

# Run main function
main "$@"
