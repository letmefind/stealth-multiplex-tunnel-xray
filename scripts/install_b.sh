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
    
    # Install required packages
    local packages=("curl" "unzip" "jq" "nginx" "uuid-runtime")
    
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

# Install Certbot
install_certbot() {
    log_info "Installing Certbot..."
    
    if command -v certbot &> /dev/null; then
        log_warning "Certbot is already installed"
        return
    fi
    
    apt-get install -y certbot python3-certbot-nginx
    
    log_success "Certbot installed successfully"
}

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
        
        read -p "Reality public key (from Server A): " REALITY_PUBLIC_KEY
        read -p "Reality short IDs (comma-separated from Server A): " REALITY_SHORT_IDS
        
        if [[ -z "$REALITY_PUBLIC_KEY" || -z "$REALITY_SHORT_IDS" ]]; then
            log_error "Reality public key and short IDs are required"
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
    
    # TCP BBR
    read -p "Enable TCP BBR optimization? [y/N]: " ENABLE_BBR
    ENABLE_BBR=${ENABLE_BBR:-"n"}
    
    # Create decoy site
    read -p "Create decoy site? [Y/n]: " CREATE_DECOY
    CREATE_DECOY=${CREATE_DECOY:-"y"}
    
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
    echo "  Proxy Protocol: $ENABLE_PROXY_PROTOCOL"
    echo "  TCP BBR: $ENABLE_BBR"
    echo "  Create Decoy: $CREATE_DECOY"
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
        echo "  Reality Public Key: $REALITY_PUBLIC_KEY"
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

# Configure certificates
configure_certificates() {
    if [[ "$SECURITY" == "tls" ]]; then
        if [[ "$CERT_MODE" == "certbot" ]]; then
            log_info "Obtaining certificate with Certbot..."
            
            # Stop nginx temporarily
            systemctl stop nginx || true
            
            # Obtain certificate
            certbot certonly --standalone --email "$CERTBOT_EMAIL" --agree-tos --no-eff-email -d "$SERVER_NAME"
            
            # Set certificate paths
            FULLCHAIN_PATH="/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem"
            PRIVKEY_PATH="/etc/letsencrypt/live/$SERVER_NAME/privkey.pem"
            
            if [[ ! -f "$FULLCHAIN_PATH" || ! -f "$PRIVKEY_PATH" ]]; then
                log_error "Failed to obtain certificate"
                exit 1
            fi
            
            log_success "Certificate obtained successfully"
        fi
    else
        # For Reality, we don't need real certificates, but Nginx still needs them for the decoy
        # Generate self-signed certificates for the decoy website
        log_info "Generating self-signed certificate for decoy website..."
        
        mkdir -p "/etc/ssl/private"
        mkdir -p "/etc/ssl/certs"
        
        FULLCHAIN_PATH="/etc/ssl/certs/decoy.crt"
        PRIVKEY_PATH="/etc/ssl/private/decoy.key"
        
        # Generate self-signed certificate
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$PRIVKEY_PATH" \
            -out "$FULLCHAIN_PATH" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$SERVER_NAME" 2>/dev/null
        
        chmod 600 "$PRIVKEY_PATH"
        chmod 644 "$FULLCHAIN_PATH"
        
        log_success "Self-signed certificate generated for decoy"
    fi
}

# Create Nginx configuration
create_nginx_config() {
    log_info "Creating Nginx configuration..."
    
    # Create web root if it doesn't exist
    mkdir -p "$WEB_ROOT"
    
    # Create decoy site
    if [[ "$CREATE_DECOY" == "y" || "$CREATE_DECOY" == "Y" ]]; then
        cat > "$WEB_ROOT/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to $SERVER_NAME</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        p { color: #666; line-height: 1.6; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 4px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to $SERVER_NAME</h1>
        <div class="status">
            <strong>Status:</strong> Service is running normally
        </div>
        <p>This is a placeholder page for the $SERVER_NAME service.</p>
        <p>If you are seeing this page, the web server is functioning correctly.</p>
        <p>For technical support, please contact your system administrator.</p>
    </div>
</body>
</html>
EOF
        log_success "Decoy site created"
    fi
    
    # Create Nginx configuration
    local nginx_conf="$NGINX_CONF_DIR/stealth-$B_TLS_PORT.conf"
    local proxy_protocol_suffix=""
    
    if [[ "$ENABLE_PROXY_PROTOCOL" == "y" || "$ENABLE_PROXY_PROTOCOL" == "Y" ]]; then
        proxy_protocol_suffix=" proxy_protocol"
    fi
    
    cat > "$nginx_conf" << EOF
server {
    listen $B_TLS_PORT ssl http2$proxy_protocol_suffix;
    server_name $SERVER_NAME;

    ssl_certificate     $FULLCHAIN_PATH;
    ssl_certificate_key $PRIVKEY_PATH;

    root $WEB_ROOT;
    index index.html;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Decoy site on /
    location = / {
        try_files /index.html =404;
    }

    # Hide the tunnel behind a static-like path
    location $STEALTH_PATH {
        proxy_http_version 1.1;
        proxy_set_header Host $SERVER_NAME;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Connection keep-alive;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
        proxy_pass http://127.0.0.1:18081;
    }

    # Block access to sensitive files
    location ~ /\. {
        deny all;
    }
    
    location ~ \.(log|conf)$ {
        deny all;
    }
}
EOF
    
    # Test Nginx configuration
    nginx -t
    if [[ $? -ne 0 ]]; then
        log_error "Nginx configuration test failed"
        exit 1
    fi
    
    log_success "Nginx configuration created: $nginx_conf"
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
    local config_file="$XRAY_CONF_DIR/b.json"
    local accept_proxy_protocol="false"
    
    if [[ "$ENABLE_PROXY_PROTOCOL" == "y" || "$ENABLE_PROXY_PROTOCOL" == "Y" ]]; then
        accept_proxy_protocol="true"
    fi
    
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
    
    # Add inbound based on protocol and security
    local inbound
    if [[ "$PROTOCOL" == "vless" ]]; then
        if [[ "$SECURITY" == "tls" ]]; then
            inbound='{
                "tag": "vless-in",
                "listen": "127.0.0.1",
                "port": 18081,
                "protocol": "vless",
                "settings": {
                    "clients": [{
                        "id": "'$UUID'",
                        "flow": ""
                    }],
                    "decryption": "none"
                },
                "streamSettings": {
                    "network": "splithttp",
                    "security": "none",
                    "splithttpSettings": {
                        "transport": "splithttp",
                        "acceptProxyProtocol": '$accept_proxy_protocol',
                        "host": "'$SERVER_NAME'",
                        "custom_host": "'$SERVER_NAME'",
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
            inbound='{
                "tag": "vless-in",
                "listen": "127.0.0.1",
                "port": 18081,
                "protocol": "vless",
                "settings": {
                    "clients": [{
                        "id": "'$UUID'",
                        "flow": ""
                    }],
                    "decryption": "none"
                },
                "streamSettings": {
                    "network": "splithttp",
                    "security": "reality",
                    "realitySettings": {
                        "show": false,
                        "dest": "'$REALITY_DEST'",
                        "privatekey": "'$REALITY_PUBLIC_KEY'",
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
                        "acceptProxyProtocol": '$accept_proxy_protocol',
                        "host": "'$SERVER_NAME'",
                        "custom_host": "'$SERVER_NAME'",
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
            inbound='{
                "tag": "trojan-in",
                "listen": "127.0.0.1",
                "port": 18081,
                "protocol": "trojan",
                "settings": {
                    "clients": [{
                        "password": "'$UUID'"
                    }]
                },
                "streamSettings": {
                    "network": "tcp",
                    "security": "none"
                }
            }'
        else # reality
            inbound='{
                "tag": "trojan-in",
                "listen": "127.0.0.1",
                "port": 18081,
                "protocol": "trojan",
                "settings": {
                    "clients": [{
                        "password": "'$UUID'"
                    }]
                },
                "streamSettings": {
                    "network": "tcp",
                    "security": "reality",
                    "realitySettings": {
                        "show": false,
                        "dest": "'$SERVER_NAME':443",
                        "xver": 0,
                        "serverNames": ['$(echo "$SNI_DOMAINS" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')'],
                        "privateKey": "'$REALITY_PUBLIC_KEY'",
                        "shortIds": ["'$REALITY_SHORT_IDS'"]
                    }
                }
            }'
        fi
    fi
    
    # Add outbound
    local outbound='{
        "tag": "portal-out",
        "protocol": "freedom",
        "settings": {}
    }'
    
    # Add routing rule
    local routing_rule='{
        "type": "field",
        "inboundTag": ["'$(echo "$PROTOCOL" | sed 's/vless/vless-in/;s/trojan/trojan-in/')'"],
        "outboundTag": "portal-out"
    }'
    
    config=$(echo "$config" | jq '.inbounds += ['"$inbound"']')
    config=$(echo "$config" | jq '.outbounds += ['"$outbound"']')
    config=$(echo "$config" | jq '.routing.rules += ['"$routing_rule"']')
    
    # Write configuration file
    echo "$config" | jq '.' > "$config_file"
    chmod 644 "$config_file"
    
    log_success "Xray configuration created: $config_file"
}

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
User=nobody
Group=nogroup
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
        
        # Allow certificate renewal port if using Certbot
        if [[ "$CERT_MODE" == "certbot" ]]; then
            ufw allow 80/tcp
        fi
        
        log_success "UFW firewall configured"
    else
        log_warning "UFW not found. Please configure firewall manually:"
        echo "iptables -A INPUT -p tcp --dport 22 -j ACCEPT"
        echo "iptables -A INPUT -p tcp --dport $B_TLS_PORT -j ACCEPT"
        if [[ "$CERT_MODE" == "certbot" ]]; then
            echo "iptables -A INPUT -p tcp --dport 80 -j ACCEPT"
        fi
    fi
}

# Start services
start_services() {
    log_info "Starting services..."
    
    # Start Nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Start Xray
    systemctl start xray-b
    
    # Wait a moment for services to start
    sleep 2
    
    if systemctl is-active --quiet nginx; then
        log_success "Nginx service started successfully"
    else
        log_error "Failed to start Nginx service"
        systemctl status nginx
        exit 1
    fi
    
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
    echo "  Proxy Protocol: $ENABLE_PROXY_PROTOCOL"
    echo "  Configuration: $XRAY_CONF_DIR/b.json"
    echo "  Service: xray-b"
    echo "  Nginx Config: $NGINX_CONF_DIR/stealth-$B_TLS_PORT.conf"
    echo
    log_info "Testing Commands:"
    echo "  Check decoy site: curl -I https://$SERVER_NAME:$B_TLS_PORT/"
    echo "  Check tunnel path: curl -I https://$SERVER_NAME:$B_TLS_PORT$STEALTH_PATH"
    echo "  Check service status: systemctl status xray-b"
    echo "  View logs: journalctl -u xray-b -e"
    echo "  View Nginx logs: tail -f /var/log/nginx/access.log"
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
        echo "   Reality Public Key: $REALITY_PUBLIC_KEY"
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
    if [[ "$SECURITY" == "tls" && "$CERT_MODE" == "certbot" ]]; then
        install_certbot
    fi
    configure_certificates
    create_nginx_config
    create_xray_config
    install_systemd_service
    configure_bbr
    configure_firewall
    start_services
    display_summary
}

# Run main function
main "$@"
