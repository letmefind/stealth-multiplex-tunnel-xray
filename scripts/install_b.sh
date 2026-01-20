#!/bin/bash

# Stealth Multiplex Tunnel Xray - Server B (Receiver) Installer
# Supports VLESS/Trojan protocols with TLS/Reality security

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
XRAY_CONF_DIR="/etc/xray"
XRAY_LOG_DIR="/var/log/xray"
SYSTEMD_DIR="/etc/systemd/system"
NGINX_CONF_DIR="/etc/nginx/conf.d"
WEB_ROOT="/var/www/html"

# Default values
DEFAULT_B_TLS_PORT="8081"
DEFAULT_STEALTH_PATH="/assets"
DEFAULT_PROTOCOL="vless"
DEFAULT_SECURITY="tls"
DEFAULT_CERT_MODE="certbot"

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

# Check system requirements
check_system() {
    log_info "Checking system requirements..."
    
    # Check OS
    if ! command -v apt-get &> /dev/null; then
        log_error "This script requires Ubuntu/Debian with apt package manager"
        exit 1
    fi
    
    # Update package list
    apt-get update
    
    # Install required packages (removed nginx)
    local packages=("curl" "unzip" "jq" "uuid-runtime")
    
    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            log_info "Installing $package..."
            apt-get install -y "$package"
        fi
    done
    
    log_success "System requirements check completed"
}

# Install Xray
install_xray() {
    log_info "Installing Xray..."
    
    if command -v xray &> /dev/null; then
        log_warning "Xray is already installed"
        return
    fi
    
    # Download and install Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # Verify installation
    if ! command -v xray &> /dev/null; then
        log_error "Failed to install Xray"
        exit 1
    fi
    
    log_success "Xray installed successfully"
}

# Removed Certbot installation (not needed without nginx)

# Prompt for configuration
prompt_config() {
    log_info "Please provide the following configuration:"
    
    # Initialize default values
    CERT_MODE="$DEFAULT_CERT_MODE"
    
    # Server name (must match Server A's B_DOMAIN)
    while true; do
        read -p "Server name (must match Server A's domain): " SERVER_NAME
        if [[ -n "$SERVER_NAME" ]]; then
            break
        fi
        log_error "Server name cannot be empty"
    done
    
    # TLS port
    read -p "TLS port [$DEFAULT_B_TLS_PORT]: " B_TLS_PORT
    B_TLS_PORT=${B_TLS_PORT:-$DEFAULT_B_TLS_PORT}
    
    # Stealth path
    read -p "Stealth path [$DEFAULT_STEALTH_PATH]: " STEALTH_PATH
    STEALTH_PATH=${STEALTH_PATH:-$DEFAULT_STEALTH_PATH}
    
    # Protocol selection
    echo "Select protocol:"
    echo "1) VLESS (recommended for stealth)"
    echo "2) Trojan"
    while true; do
        read -p "Protocol choice [1-2]: " PROTOCOL_CHOICE
        case $PROTOCOL_CHOICE in
            1)
                PROTOCOL="vless"
                break
                ;;
            2)
                PROTOCOL="trojan"
                break
                ;;
            "")
                PROTOCOL="vless"
                break
                ;;
            *)
                log_error "Invalid choice. Please select 1 or 2"
                ;;
        esac
    done
    
    # Security selection
    echo "Select security method:"
    echo "1) TLS (requires valid certificate)"
    echo "2) Reality (enhanced stealth, no real cert needed)"
    while true; do
        read -p "Security choice [1-2]: " SECURITY_CHOICE
        case $SECURITY_CHOICE in
            1)
                SECURITY="tls"
                break
                ;;
            2)
                SECURITY="reality"
                break
                ;;
            "")
                SECURITY="tls"
                break
                ;;
            *)
                log_error "Invalid choice. Please select 1 or 2"
                ;;
        esac
    done
    
    # Certificate configuration
    if [[ "$SECURITY" == "tls" ]]; then
        echo "Certificate configuration:"
        echo "1) Use existing certificate"
        echo "2) Use Certbot (automatic)"
        while true; do
            read -p "Certificate choice [1-2]: " CERT_CHOICE
            case $CERT_CHOICE in
                1)
                    CERT_MODE="use-existing"
                    break
                    ;;
                2)
                    CERT_MODE="certbot"
                    break
                    ;;
                "")
                    CERT_MODE="certbot"
                    break
                    ;;
                *)
                    log_error "Invalid choice. Please select 1 or 2"
                    ;;
            esac
        done
        
        if [[ "$CERT_MODE" == "use-existing" ]]; then
            while true; do
                read -p "Full chain certificate path: " FULLCHAIN_PATH
                if [[ -f "$FULLCHAIN_PATH" ]]; then
                    break
                fi
                log_error "Certificate file not found: $FULLCHAIN_PATH"
            done
            
            while true; do
                read -p "Private key path: " PRIVKEY_PATH
                if [[ -f "$PRIVKEY_PATH" ]]; then
                    break
                fi
                log_error "Private key file not found: $PRIVKEY_PATH"
            done
        else
            while true; do
                read -p "Email for certificate registration: " CERTBOT_EMAIL
                if [[ "$CERTBOT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                    break
                fi
                log_error "Invalid email address"
            done
        fi
    else
        # Reality configuration
        read -p "Reality destination (e.g., www.microsoft.com:443) [www.microsoft.com:443]: " REALITY_DEST
        REALITY_DEST=${REALITY_DEST:-"www.microsoft.com:443"}
        
        read -p "Reality server names (comma-separated) [www.accounts.accesscontrol.windows.net]: " SNI_DOMAINS
        SNI_DOMAINS=${SNI_DOMAINS:-"www.accounts.accesscontrol.windows.net"}
        
        read -p "Reality private key (from Server A): " REALITY_PRIVATE_KEY
        read -p "Reality short IDs (comma-separated from Server A): " REALITY_SHORT_IDS
        
        if [[ -z "$REALITY_PRIVATE_KEY" || -z "$REALITY_SHORT_IDS" ]]; then
            log_error "Reality private key and short IDs are required"
            exit 1
        fi
    fi
    
    # TLS configuration
    if [[ "$SECURITY" == "tls" ]]; then
        read -p "TLS fingerprint [chrome]: " TLS_FINGERPRINT
        TLS_FINGERPRINT=${TLS_FINGERPRINT:-"chrome"}
        
        read -p "ALPN protocols (comma-separated) [h2,http/1.1]: " ALPN_PROTOCOLS
        ALPN_PROTOCOLS=${ALPN_PROTOCOLS:-"h2,http/1.1"}
        
        read -p "Allow insecure connections? [y/N]: " ALLOW_INSECURE
        ALLOW_INSECURE=${ALLOW_INSECURE:-"n"}
        
        read -p "Reject unknown SNI? [y/N]: " REJECT_UNKNOWN_SNI
        REJECT_UNKNOWN_SNI=${REJECT_UNKNOWN_SNI:-"n"}
    fi
    
    # UUID
    read -p "UUID (must match Server A): " UUID
    if [[ -z "$UUID" ]]; then
        log_error "UUID is required and must match Server A"
        exit 1
    fi
    
    # Proxy protocol
    read -p "Enable PROXY protocol support? [y/N]: " ENABLE_PROXY_PROTOCOL
    ENABLE_PROXY_PROTOCOL=${ENABLE_PROXY_PROTOCOL:-"n"}
    
    # Ports to forward (port-preserving routing)
    read -p "Ports to forward (comma-separated, e.g., 80,8080,8443) [80,8080,8443]: " ASSIGNED_PORTS
    ASSIGNED_PORTS=${ASSIGNED_PORTS:-"80,8080,8443"}
    echo "Note: Traffic from Server A on port 80 will be forwarded to 127.0.0.1:80"
    echo "      Traffic from Server A on port 8080 will be forwarded to 127.0.0.1:8080"
    echo "      Ports are preserved - same port in = same port out"
    
    # TCP BBR
    read -p "Enable TCP BBR optimization? [y/N]: " ENABLE_BBR
    ENABLE_BBR=${ENABLE_BBR:-"n"}
    
    # Initialize TLS variables if not set (for Reality mode)
    ALLOW_INSECURE=${ALLOW_INSECURE:-"n"}
    REJECT_UNKNOWN_SNI=${REJECT_UNKNOWN_SNI:-"n"}
    TLS_FINGERPRINT=${TLS_FINGERPRINT:-"chrome"}
    ALPN_PROTOCOLS=${ALPN_PROTOCOLS:-"h2,http/1.1"}
    
    # Convert boolean values to lowercase
    if [[ "$ALLOW_INSECURE" == "y" || "$ALLOW_INSECURE" == "Y" ]]; then
        ALLOW_INSECURE_LOWERCASE="true"
    else
        ALLOW_INSECURE_LOWERCASE="false"
    fi
    
    if [[ "$REJECT_UNKNOWN_SNI" == "y" || "$REJECT_UNKNOWN_SNI" == "Y" ]]; then
        REJECT_UNKNOWN_SNI_LOWERCASE="true"
    else
        REJECT_UNKNOWN_SNI_LOWERCASE="false"
    fi
    
    # Display configuration summary
    echo
    log_info "Configuration Summary:"
    echo "  Server Name: $SERVER_NAME"
    echo "  TLS Port: $B_TLS_PORT"
    echo "  Stealth Path: $STEALTH_PATH"
    echo "  Protocol: $PROTOCOL"
    echo "  Security: $SECURITY"
    echo "  UUID: $UUID"
    echo "  Ports to Forward: $ASSIGNED_PORTS"
    echo "  Port Routing: Each port forwards to 127.0.0.1:<same-port>"
    echo "  Proxy Protocol: $ENABLE_PROXY_PROTOCOL"
    echo "  TCP BBR: $ENABLE_BBR"
    if [[ "$SECURITY" == "tls" ]]; then
        echo "  Certificate Mode: $CERT_MODE"
        if [[ "$CERT_MODE" == "use-existing" ]]; then
            echo "  Certificate Path: $FULLCHAIN_PATH"
            echo "  Private Key Path: $PRIVKEY_PATH"
        else
            echo "  Certbot Email: $CERTBOT_EMAIL"
        fi
    else
        echo "  SNI Domains: $SNI_DOMAINS"
        echo "  Reality Private Key: $REALITY_PRIVATE_KEY"
        echo "  Reality Short IDs: $REALITY_SHORT_IDS"
    fi
    echo
    
    read -p "Continue with installation? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-"y"}
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
}

# Validate ports
validate_ports() {
    IFS=',' read -ra PORT_ARRAY <<< "$ASSIGNED_PORTS"
    VALID_PORTS=""
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | xargs) # trim whitespace
        if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 1 ]] && [[ "$port" -le 65535 ]]; then
            if [ -z "$VALID_PORTS" ]; then
                VALID_PORTS="$port"
            else
                VALID_PORTS="$VALID_PORTS,$port"
            fi
        else
            log_warning "Invalid port: $port (skipping)"
        fi
    done
    
    if [ -z "$VALID_PORTS" ]; then
        log_error "No valid ports provided"
        exit 1
    fi
    
    ASSIGNED_PORTS="$VALID_PORTS"
    log_success "Validated ports: $ASSIGNED_PORTS"
}

# Create Xray configuration (no nginx)
create_xray_config_only() {
    log_info "Creating Xray configuration..."
    
    # Validate ports first
    validate_ports
    
    # Create log directory
    mkdir -p "$XRAY_LOG_DIR"
    chown nobody:nogroup "$XRAY_LOG_DIR"
    
    # Create configuration directory
    mkdir -p "$XRAY_CONF_DIR"
    
    # Build configuration JSON
    local config_file="$XRAY_CONF_DIR/b.json"
    local accept_proxy_protocol="false"
    
    if [[ "$ENABLE_PROXY_PROTOCOL" == "y" || "$ENABLE_PROXY_PROTOCOL" == "Y" ]]; then
        accept_proxy_protocol="true"
    fi
    
    # Use temp file to build JSON
    local temp_config=$(mktemp)
    
    # Start with base config
    cat > "$temp_config" << 'BASEEOF'
{
  "log": {
    "access": "LOG_DIR_PLACEHOLDER/access.log",
    "error": "LOG_DIR_PLACEHOLDER/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "tunnel-in",
      "listen": "0.0.0.0",
      "port": TUNNEL_PORT_PLACEHOLDER,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "UUID_PLACEHOLDER" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "splithttp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "serverNames": ["SERVER_NAME_PLACEHOLDER"],
          "privateKey": "PRIVATE_KEY_PLACEHOLDER",
          "shortIds": [SHORT_IDS_PLACEHOLDER]
        },
        "splithttpSettings": {
          "path": "/assets",
          "scMaxEachPostBytes": 1000000,
          "scMaxConcurrentPosts": 6,
          "scMinPostsIntervalMs": 25,
          "noSSEHeader": false,
          "noGRPCHeader": true,
          "xPaddingBytes": 200,
          "keepaliveperiod": 60,
          "mode": "auto"
        }
      }
    }
  ],
  "outbounds": [
BASEEOF
    
    # Create outbounds for each port (port-preserving)
    IFS=',' read -ra PORT_ARRAY <<< "$ASSIGNED_PORTS"
    FIRST_OUTBOUND=true
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | xargs) # trim whitespace
        if [ "$FIRST_OUTBOUND" = true ]; then
            FIRST_OUTBOUND=false
        else
            echo "," >> "$temp_config"
        fi
        cat >> "$temp_config" << OUTBOUNDEOF
    { "tag": "to-port-$port", "protocol": "freedom", "settings": { "redirect": "127.0.0.1:$port" } }
OUTBOUNDEOF
    done
    
    # Add routing rules
    cat >> "$temp_config" << ROUTINGEOF
  ],
  "routing": {
    "rules": [
ROUTINGEOF
    
    # Add routing rules for each port (port-preserving)
    FIRST_RULE=true
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | xargs) # trim whitespace
        if [ "$FIRST_RULE" = true ]; then
            FIRST_RULE=false
        else
            echo "," >> "$temp_config"
        fi
        cat >> "$temp_config" << RULEEOF
      { "type": "field", "inboundTag": ["tunnel-in"], "port": $port, "outboundTag": "to-port-$port" }
RULEEOF
    done
    
    cat >> "$temp_config" << ENDEOF
    ]
  }
}
ENDEOF
    
    # Replace placeholders
    sed -i "s|LOG_DIR_PLACEHOLDER|$XRAY_LOG_DIR|g" "$temp_config"
    sed -i "s/TUNNEL_PORT_PLACEHOLDER/$B_TLS_PORT/g" "$temp_config"
    sed -i "s/UUID_PLACEHOLDER/$UUID/g" "$temp_config"
    sed -i "s/SERVER_NAME_PLACEHOLDER/$SERVER_NAME/g" "$temp_config"
    sed -i "s/PRIVATE_KEY_PLACEHOLDER/$REALITY_PRIVATE_KEY/g" "$temp_config"
    sed -i "s/SHORT_IDS_PLACEHOLDER/$(echo "$REALITY_SHORT_IDS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')/g" "$temp_config"
    
    # Move temp config to final location
    mv "$temp_config" "$config_file"
    chmod 644 "$config_file"
    
    log_success "Xray configuration created: $config_file"
}

# Old create_xray_config function removed - using create_xray_config_only instead

# Install systemd service
install_systemd_service() {
    log_info "Installing systemd service..."
    
    local service_file="$SYSTEMD_DIR/xray-b.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Xray Service (Server B)
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xray run -config $XRAY_CONF_DIR/b.json
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable xray-b
    
    log_success "Systemd service installed and enabled"
}

# Configure TCP BBR
configure_bbr() {
    if [[ "$ENABLE_BBR" == "y" || "$ENABLE_BBR" == "Y" ]]; then
        log_info "Configuring TCP BBR..."
        
        cat > /etc/sysctl.d/99-bbr.conf << EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
        
        sysctl --system
        
        log_success "TCP BBR configured"
    fi
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        # Enable UFW if not already enabled
        ufw --force enable
        
        # Allow SSH port (essential)
        ufw allow 22/tcp
        
        # Allow tunnel port
        ufw allow "$B_TLS_PORT/tcp"
        
        # Allow assigned ports
        IFS=',' read -ra PORT_ARRAY <<< "$ASSIGNED_PORTS"
        for port in "${PORT_ARRAY[@]}"; do
            port=$(echo "$port" | xargs) # trim whitespace
            ufw allow "$port/tcp"
        done
        
        log_success "UFW firewall configured"
    else
        log_warning "UFW not found. Please configure firewall manually:"
        echo "iptables -A INPUT -p tcp --dport 22 -j ACCEPT"
        echo "iptables -A INPUT -p tcp --dport $B_TLS_PORT -j ACCEPT"
        IFS=',' read -ra PORT_ARRAY <<< "$ASSIGNED_PORTS"
        for port in "${PORT_ARRAY[@]}"; do
            port=$(echo "$port" | xargs) # trim whitespace
            echo "iptables -A INPUT -p tcp --dport $port -j ACCEPT"
        done
    fi
}

# Start services
start_services() {
    log_info "Starting services..."
    
    # Start Xray
    systemctl start xray-b
    
    # Wait a moment for service to start
    sleep 2
    
    if systemctl is-active --quiet xray-b; then
        log_success "Xray service started successfully"
    else
        log_error "Failed to start Xray service"
        systemctl status xray-b
        exit 1
    fi
}

# Display summary
display_summary() {
    echo
    log_success "Installation completed successfully!"
    echo
    log_info "Configuration Summary:"
    echo "  Server Name: $SERVER_NAME"
    echo "  TLS Port: $B_TLS_PORT"
    echo "  Stealth Path: $STEALTH_PATH"
    echo "  Protocol: $PROTOCOL"
    echo "  Security: $SECURITY"
    echo "  UUID: $UUID"
    echo "  Ports to Forward: $ASSIGNED_PORTS"
    echo "  Port Routing: Each port forwards to 127.0.0.1:<same-port>"
    echo "  Proxy Protocol: $ENABLE_PROXY_PROTOCOL"
    echo "  Configuration: $XRAY_CONF_DIR/b.json"
    echo "  Service: xray-b"
    echo
    log_info "Testing Commands:"
    echo "  Check listening ports: ss -tlnp | grep -E ':$B_TLS_PORT\\s'"
    echo "  Check service status: systemctl status xray-b"
    echo "  View logs: journalctl -u xray-b -e"
    echo ""
    log_info "Port Routing (port-preserving):"
    IFS=',' read -ra PORT_ARRAY <<< "$ASSIGNED_PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | xargs) # trim whitespace
        echo "  Port $port: Traffic from Server A → 127.0.0.1:$port"
    done
    echo ""
    log_info "Port Routing (port-preserving):"
    IFS=',' read -ra PORT_ARRAY <<< "$ASSIGNED_PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | xargs) # trim whitespace
        echo "  Port $port: Traffic from Server A → 127.0.0.1:$port"
    done
    echo
    log_info "📋 VALUES FOR SERVER A INSTALLATION:"
    echo "=========================================="
    echo "Copy these values when installing Server A:"
    echo
    echo "🔗 Server B Domain: $SERVER_NAME"
    echo "🔌 Server B TLS Port: $B_TLS_PORT"
    echo "🛡️  Stealth Path: $STEALTH_PATH"
    echo "📡 Protocol: $PROTOCOL"
    echo "🔐 Security: $SECURITY"
    echo "🆔 UUID: $UUID"
    echo
    
    if [[ "$SECURITY" == "reality" ]]; then
        echo "🔑 Reality Configuration (copy these exactly):"
        echo "   Reality Private Key: $REALITY_PRIVATE_KEY"
        echo "   Reality Short IDs: $REALITY_SHORT_IDS"
        echo "   Reality Destination: $REALITY_DEST"
        echo "   SNI Domains: $SNI_DOMAINS"
        echo
    elif [[ "$SECURITY" == "tls" ]]; then
        echo "🔒 TLS Configuration:"
        echo "   TLS Fingerprint: $TLS_FINGERPRINT"
        echo "   ALPN Protocols: $ALPN_PROTOCOLS"
        echo "   Allow Insecure: $ALLOW_INSECURE"
        echo "   Reject Unknown SNI: $REJECT_UNKNOWN_SNI"
        echo
    fi
    
    echo "📝 Next Steps:"
    echo "1. Install Server A: sudo bash scripts/install_a.sh"
    echo "2. Use the exact values above when prompted"
    echo "3. Ensure Server A has the same configuration"
    echo
}

# Main installation function
main() {
    log_info "Starting Server B (Receiver) installation..."
    
    check_root
    check_system
    install_xray
    prompt_config
    validate_ports
    create_xray_config_only
    install_systemd_service
    configure_bbr
    configure_firewall
    start_services
    display_summary
}

# Run main function
main "$@"
