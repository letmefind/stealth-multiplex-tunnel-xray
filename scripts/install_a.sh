#!/bin/bash

# Stealth Multiplex Tunnel Xray - Server A (Entry) Installer
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

# Default values
DEFAULT_B_TLS_PORT="8081"
DEFAULT_STEALTH_PATH="/assets"
DEFAULT_PORT_LIST="80,443,8080,8443"
DEFAULT_PROTOCOL="vless"
DEFAULT_SECURITY="tls"

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
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_info "Installing jq..."
        apt-get update
        apt-get install -y jq
    fi
    
    # Check if uuidgen is available
    if ! command -v uuidgen &> /dev/null; then
        log_info "Installing uuid-runtime..."
        apt-get install -y uuid-runtime
    fi
    
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

# Prompt for configuration
prompt_config() {
    log_info "Please provide the following configuration:"
    
    # Server B domain
    while true; do
        read -p "Server B domain (e.g., cdn.example.com): " B_DOMAIN
        if [[ -n "$B_DOMAIN" ]]; then
            break
        fi
        log_error "Domain cannot be empty"
    done
    
    # Server B TLS port
    read -p "Server B TLS port [$DEFAULT_B_TLS_PORT]: " B_TLS_PORT
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
    
    # Reality-specific configuration
    if [[ "$SECURITY" == "reality" ]]; then
        read -p "Reality destination (e.g., www.microsoft.com:443) [www.microsoft.com:443]: " REALITY_DEST
        REALITY_DEST=${REALITY_DEST:-"www.microsoft.com:443"}
        
        read -p "Reality server names (comma-separated) [www.accounts.accesscontrol.windows.net]: " SNI_DOMAINS
        SNI_DOMAINS=${SNI_DOMAINS:-"www.accounts.accesscontrol.windows.net"}
        
        # Generate Reality keys (using proper curve25519 format)
        # Use Go program to generate proper Reality keys
        if command -v go >/dev/null 2>&1; then
            # Compile and run the Go program
            cd "$SCRIPT_DIR"
            go mod init reality-keys 2>/dev/null || true
            go get golang.org/x/crypto/curve25519 2>/dev/null || true
            go run generate_reality_keys.go > /tmp/reality_keys.txt
            REALITY_PRIVATE_KEY=$(grep "Private key:" /tmp/reality_keys.txt | cut -d' ' -f3)
            REALITY_PUBLIC_KEY=$(grep "Public key:" /tmp/reality_keys.txt | cut -d' ' -f3)
            rm -f /tmp/reality_keys.txt
        else
            # Fallback: use openssl with proper format
            log_warning "Go not found, using fallback key generation"
            temp_priv=$(mktemp)
            openssl genpkey -algorithm X25519 -out "$temp_priv" 2>/dev/null
            REALITY_PRIVATE_KEY=$(openssl pkey -in "$temp_priv" -outform DER 2>/dev/null | tail -c +17 | head -c 32 | base64 | tr -d '=' | tr '+/' '-_')
            REALITY_PUBLIC_KEY=$(openssl pkey -in "$temp_priv" -pubout -outform DER 2>/dev/null | tail -c +13 | base64 | tr -d '=' | tr '+/' '-_')
            rm -f "$temp_priv"
        fi
        
        REALITY_SHORT_ID=$(openssl rand -hex 8)
        
        # Generate multiple short IDs
        REALITY_SHORT_IDS=""
        for i in {1..10}; do
            if [[ $i -eq 1 ]]; then
                REALITY_SHORT_IDS="$(openssl rand -hex 8)"
            else
                REALITY_SHORT_IDS="$REALITY_SHORT_IDS,$(openssl rand -hex 8)"
            fi
        done
        
        log_info "Generated Reality keys:"
        log_info "Private Key: $REALITY_PRIVATE_KEY"
        log_info "Public Key: $REALITY_PUBLIC_KEY"
        log_info "Short IDs: $REALITY_SHORT_IDS"
    fi
    
    # TLS-specific configuration
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
    
    # Port list
    read -p "Client ports (comma-separated) [$DEFAULT_PORT_LIST]: " PORT_LIST
    PORT_LIST=${PORT_LIST:-$DEFAULT_PORT_LIST}
    
    # UUID
    read -p "UUID (press Enter to auto-generate): " UUID
    if [[ -z "$UUID" ]]; then
        UUID=$(uuidgen)
        log_info "Generated UUID: $UUID"
    fi
    
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
    echo "  Server B Domain: $B_DOMAIN"
    echo "  Server B TLS Port: $B_TLS_PORT"
    echo "  Stealth Path: $STEALTH_PATH"
    echo "  Protocol: $PROTOCOL"
    echo "  Security: $SECURITY"
    echo "  Client Ports: $PORT_LIST"
    echo "  UUID: $UUID"
    echo "  TCP BBR: $ENABLE_BBR"
    if [[ "$SECURITY" == "reality" ]]; then
        echo "  SNI Domains: $SNI_DOMAINS"
        echo "  Reality Public Key: $REALITY_PUBLIC_KEY"
        echo "  Reality Short ID: $REALITY_SHORT_ID"
    fi
    echo
    
    read -p "Continue with installation? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-"y"}
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
}

# Create Xray configuration
create_xray_config() {
    log_info "Creating Xray configuration..."
    
    # Create log directory
    mkdir -p "$XRAY_LOG_DIR"
    chown nobody:nogroup "$XRAY_LOG_DIR"
    
    # Create configuration directory
    mkdir -p "$XRAY_CONF_DIR"
    
    # Build configuration JSON
    local config_file="$XRAY_CONF_DIR/a.json"
    
    # Start building the configuration
    local config='{
        "log": {
            "access": "'$XRAY_LOG_DIR'/access.log",
            "error": "'$XRAY_LOG_DIR'/error.log",
            "loglevel": "warning"
        },
        "inbounds": [],
        "outbounds": [],
        "routing": {
            "domainStrategy": "AsIs",
            "rules": []
        }
    }'
    
    # Add inbounds for each port
    IFS=',' read -ra PORTS <<< "$PORT_LIST"
    for port in "${PORTS[@]}"; do
        port=$(echo "$port" | xargs) # trim whitespace
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
        
        config=$(echo "$config" | jq '.inbounds += ['"$inbound"']')
        config=$(echo "$config" | jq '.routing.rules += [{"type": "field", "inboundTag": ["entry-'$port'"], "outboundTag": "to-b"}]')
    done
    
    # Add outbound based on protocol and security
    local outbound
    if [[ "$PROTOCOL" == "vless" ]]; then
        if [[ "$SECURITY" == "tls" ]]; then
            outbound='{
                "tag": "to-b",
                "protocol": "vless",
                "settings": {
                    "vnext": [{
                        "address": "'$B_DOMAIN'",
                        "port": '$B_TLS_PORT',
                        "users": [{
                            "id": "'$UUID'",
                            "encryption": "none"
                        }]
                    }]
                },
                "streamSettings": {
                    "network": "splithttp",
                    "security": "tls",
                    "tlsSettings": {
                        "serverName": "'$B_DOMAIN'",
                        "rejectUnknownSni": '$REJECT_UNKNOWN_SNI_LOWERCASE',
                        "allowInsecure": '$ALLOW_INSECURE_LOWERCASE',
                        "fingerprint": "'$TLS_FINGERPRINT'",
                        "sni": "'$B_DOMAIN'",
                        "curvepreferences": "X25519",
                        "alpn": ['$(echo "$ALPN_PROTOCOLS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')']
                    },
                    "splithttpSettings": {
                        "transport": "splithttp",
                        "acceptProxyProtocol": false,
                        "host": "'$B_DOMAIN'",
                        "custom_host": "'$B_DOMAIN'",
                        "path": "'$STEALTH_PATH'",
                        "noSSEHeader": false,
                        "noGRPCHeader": true,
                        "mode": "auto",
                        "socketSettings": {
                            "useSocket": false,
                            "dialerProxy": "",
                            "DomainStrategy": "asis",
                            "tcpKeepAliveInterval": 0,
                            "tcpUserTimeout": 0,
                            "tcpMaxSeg": 0,
                            "tcpWindowClamp": 0,
                            "tcpKeepAliveIdle": 0,
                            "tcpMptcp": false
                        },
                        "scMaxEachPostBytes": 1000000,
                        "scMaxConcurrentPosts": 6,
                        "scMinPostsIntervalMs": 25,
                        "xPaddingBytes": 200,
                        "keepaliveperiod": 60
                    }
                }
            }'
        else # reality
            outbound='{
                "tag": "to-b",
                "protocol": "vless",
                "settings": {
                    "vnext": [{
                        "address": "'$B_DOMAIN'",
                        "port": '$B_TLS_PORT',
                        "users": [{
                            "id": "'$UUID'",
                            "encryption": "none"
                        }]
                    }]
                },
                "streamSettings": {
                    "network": "splithttp",
                    "security": "reality",
                    "realitySettings": {
                        "show": false,
                        "dest": "'$REALITY_DEST'",
                        "privatekey": "'$REALITY_PRIVATE_KEY'",
                        "minclientver": "",
                        "maxclientver": "",
                        "maxtimediff": 0,
                        "proxyprotocol": 0,
                        "shortids": ['$(echo "$REALITY_SHORT_IDS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')'],
                        "serverNames": ['$(echo "$SNI_DOMAINS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')'],
                        "fingerprint": "safari",
                        "spiderx": "",
                        "publickey": "'$REALITY_PUBLIC_KEY'"
                    },
                    "splithttpSettings": {
                        "transport": "splithttp",
                        "acceptProxyProtocol": false,
                        "host": "'$B_DOMAIN'",
                        "custom_host": "'$B_DOMAIN'",
                        "path": "'$STEALTH_PATH'",
                        "noSSEHeader": false,
                        "noGRPCHeader": true,
                        "mode": "auto",
                        "socketSettings": {
                            "useSocket": false,
                            "dialerProxy": "",
                            "DomainStrategy": "asis",
                            "tcpKeepAliveInterval": 0,
                            "tcpUserTimeout": 0,
                            "tcpMaxSeg": 0,
                            "tcpWindowClamp": 0,
                            "tcpKeepAliveIdle": 0,
                            "tcpMptcp": false
                        },
                        "scMaxEachPostBytes": 1000000,
                        "scMaxConcurrentPosts": 6,
                        "scMinPostsIntervalMs": 25,
                        "xPaddingBytes": 200,
                        "keepaliveperiod": 60
                    }
                }
            }'
        fi
    else # trojan
        if [[ "$SECURITY" == "tls" ]]; then
            outbound='{
                "tag": "to-b",
                "protocol": "trojan",
                "settings": {
                    "servers": [{
                        "address": "'$B_DOMAIN'",
                        "port": '$B_TLS_PORT',
                        "password": "'$UUID'"
                    }]
                },
                "streamSettings": {
                    "network": "tcp",
                    "security": "tls",
                    "tlsSettings": {
                        "serverName": "'$B_DOMAIN'",
                        "rejectUnknownSni": '$REJECT_UNKNOWN_SNI_LOWERCASE',
                        "allowInsecure": '$ALLOW_INSECURE_LOWERCASE',
                        "fingerprint": "'$TLS_FINGERPRINT'",
                        "sni": "'$B_DOMAIN'",
                        "curvepreferences": "X25519",
                        "alpn": ['$(echo "$ALPN_PROTOCOLS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')']
                    }
                }
            }'
        else # reality
            outbound='{
                "tag": "to-b",
                "protocol": "trojan",
                "settings": {
                    "servers": [{
                        "address": "'$B_DOMAIN'",
                        "port": '$B_TLS_PORT',
                        "password": "'$UUID'"
                    }]
                },
                "streamSettings": {
                    "network": "tcp",
                    "security": "reality",
                    "realitySettings": {
                        "show": false,
                        "dest": "'$REALITY_DEST'",
                        "privatekey": "'$REALITY_PRIVATE_KEY'",
                        "minclientver": "",
                        "maxclientver": "",
                        "maxtimediff": 0,
                        "proxyprotocol": 0,
                        "shortids": ['$(echo "$REALITY_SHORT_IDS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')'],
                        "serverNames": ['$(echo "$SNI_DOMAINS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')'],
                        "fingerprint": "safari",
                        "spiderx": "",
                        "publickey": "'$REALITY_PUBLIC_KEY'"
                    }
                }
            }'
        fi
    fi
    
    # Add direct outbound
    local direct_outbound='{
        "protocol": "freedom",
        "tag": "direct"
    }'
    
    config=$(echo "$config" | jq '.outbounds += ['"$outbound"', '"$direct_outbound"']')
    
    # Write configuration file
    echo "$config" | jq '.' > "$config_file"
    chmod 600 "$config_file"
    
    log_success "Xray configuration created: $config_file"
}

# Install systemd service
install_systemd_service() {
    log_info "Installing systemd service..."
    
    local service_file="$SYSTEMD_DIR/xray-a.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Xray Service (Server A)
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/xray run -config $XRAY_CONF_DIR/a.json
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable xray-a
    
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
        
        # Allow required ports
        IFS=',' read -ra PORTS <<< "$PORT_LIST"
        for port in "${PORTS[@]}"; do
            port=$(echo "$port" | xargs) # trim whitespace
            ufw allow "$port/tcp"
        done
        
        log_success "UFW firewall configured"
    else
        log_warning "UFW not found. Please configure firewall manually:"
        IFS=',' read -ra PORTS <<< "$PORT_LIST"
        for port in "${PORTS[@]}"; do
            port=$(echo "$port" | xargs) # trim whitespace
            echo "iptables -A INPUT -p tcp --dport $port -j ACCEPT"
        done
    fi
}

# Start services
start_services() {
    log_info "Starting Xray service..."
    
    systemctl start xray-a
    
    # Wait a moment for service to start
    sleep 2
    
    if systemctl is-active --quiet xray-a; then
        log_success "Xray service started successfully"
    else
        log_error "Failed to start Xray service"
        systemctl status xray-a
        exit 1
    fi
}

# Display summary
display_summary() {
    echo
    log_success "Installation completed successfully!"
    echo
    log_info "Configuration Summary:"
    echo "  Server B Domain: $B_DOMAIN"
    echo "  Server B TLS Port: $B_TLS_PORT"
    echo "  Stealth Path: $STEALTH_PATH"
    echo "  Protocol: $PROTOCOL"
    echo "  Security: $SECURITY"
    echo "  Client Ports: $PORT_LIST"
    echo "  UUID: $UUID"
    echo "  Configuration: $XRAY_CONF_DIR/a.json"
    echo "  Service: xray-a"
    echo
    log_info "Next Steps:"
    echo "1. Install Server B using: sudo bash scripts/install_b.sh"
    echo "2. Use the same UUID and configuration values on Server B"
    if [[ "$SECURITY" == "reality" ]]; then
        echo "3. Share these Reality keys with Server B:"
        echo "   Public Key: $REALITY_PUBLIC_KEY"
        echo "   Short ID: $REALITY_SHORT_ID"
    fi
    echo
    log_info "Testing Commands:"
    echo "  Check listening ports: ss -tlnp | grep -E ':(80|443|8080|8443)\\s'"
    echo "  Check service status: systemctl status xray-a"
    echo "  View logs: journalctl -u xray-a -e"
    echo "  Manage ports: sudo bash scripts/manage_ports.sh"
    echo
}

# Main installation function
main() {
    log_info "Starting Server A (Entry) installation..."
    
    check_root
    check_system
    install_xray
    prompt_config
    create_xray_config
    install_systemd_service
    configure_bbr
    configure_firewall
    start_services
    display_summary
}

# Run main function
main "$@"
