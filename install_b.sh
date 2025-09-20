#!/bin/bash

# VLESS+REALITY Tunnel Installation Script - Server B (Destination Server)
# This script installs and configures Xray and Nginx on Server B

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get user input with defaults
get_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

# Function to validate port
validate_port() {
    local port="$1"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Main installation function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  VLESS+REALITY Server B Install${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    print_info "This script will install and configure Xray and Nginx on Server B (Destination Server)"
    echo
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
    
    # Get configuration from user
    print_info "Please provide the following configuration details:"
    echo
    print_warning "You need the details from Server A installation:"
    echo "  - UUID"
    echo "  - Private Key"
    echo "  - Short ID"
    echo "  - Server Name"
    echo "  - Tunnel Port"
    echo
    
    # UUID from Server A
    UUID=$(get_input "UUID from Server A")
    if [ -z "$UUID" ]; then
        print_error "UUID is required"
        exit 1
    fi
    
    # Private Key from Server A
    PRIVATE_KEY=$(get_input "Private Key from Server A")
    if [ -z "$PRIVATE_KEY" ]; then
        print_error "Private Key is required"
        exit 1
    fi
    
    # Short ID from Server A
    SHORT_ID=$(get_input "Short ID from Server A")
    if [ -z "$SHORT_ID" ]; then
        print_error "Short ID is required"
        exit 1
    fi
    
    # Server Name from Server A
    SERVER_NAME=$(get_input "Server Name from Server A" "www.accounts.accesscontrol.windows.net")
    
    # Tunnel port from Server A
    TUNNEL_PORT=$(get_input "Tunnel Port from Server A" "8081")
    while ! validate_port "$TUNNEL_PORT"; do
        print_error "Invalid port number"
        TUNNEL_PORT=$(get_input "Tunnel Port from Server A" "8081")
    done
    
    # Target port (the port you want to tunnel)
    TARGET_PORT=$(get_input "Target port to tunnel (e.g., 8443 for XMPlus)" "8443")
    while ! validate_port "$TARGET_PORT" || [ "$TARGET_PORT" = "80" ] || [ "$TARGET_PORT" = "443" ]; do
        if [ "$TARGET_PORT" = "80" ] || [ "$TARGET_PORT" = "443" ]; then
            print_error "Target port cannot be 80 or 443 (use nginx for these)"
        else
            print_error "Invalid port number"
        fi
        TARGET_PORT=$(get_input "Target port to tunnel (e.g., 8443 for XMPlus)" "8443")
    done
    
    # Domain for nginx
    DOMAIN=$(get_input "Domain name for nginx" "test.bale.cyou")
    
    echo
    print_info "Configuration summary:"
    echo "  UUID: $UUID"
    echo "  Private Key: $PRIVATE_KEY"
    echo "  Short ID: $SHORT_ID"
    echo "  Server Name: $SERVER_NAME"
    echo "  Tunnel Port: $TUNNEL_PORT"
    echo "  Target Port: $TARGET_PORT"
    echo "  Domain: $DOMAIN"
    echo
    
    # Confirm installation
    read -p "Do you want to proceed with installation? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Install Xray if not present
    if ! command -v xray >/dev/null 2>&1; then
        print_info "Installing Xray..."
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    else
        print_info "Xray is already installed"
    fi
    
    # Install Nginx if not present
    if ! command -v nginx >/dev/null 2>&1; then
        print_info "Installing Nginx..."
        if command -v apt >/dev/null 2>&1; then
            apt update && apt install -y nginx
        elif command -v yum >/dev/null 2>&1; then
            yum install -y nginx
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y nginx
        fi
    else
        print_info "Nginx is already installed"
    fi
    
    # Create Xray directories
    mkdir -p /etc/xray
    mkdir -p /var/log/xray
    
    # Generate Server B configuration
    print_info "Generating Server B configuration..."
    cat > /etc/xray/b.json << EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "tunnel-in",
      "listen": "0.0.0.0",
      "port": $TUNNEL_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "splithttp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "serverNames": ["$SERVER_NAME"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
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
    { "tag": "to-nginx-80",  "protocol": "freedom", "settings": { "redirect": "127.0.0.1:80"  } },
    { "tag": "to-nginx-443", "protocol": "freedom", "settings": { "redirect": "127.0.0.1:443" } },
    { "tag": "to-xmplus",    "protocol": "freedom", "settings": { "redirect": "127.0.0.1:$TARGET_PORT" } }
  ],
  "routing": {
    "rules": [
      { "type": "field", "inboundTag": ["tunnel-in"], "port": "80",   "outboundTag": "to-nginx-80"  },
      { "type": "field", "inboundTag": ["tunnel-in"], "port": "443",  "outboundTag": "to-nginx-443" },
      { "type": "field", "inboundTag": ["tunnel-in"], "port": "8080,$TARGET_PORT,8082,9090", "outboundTag": "to-xmplus" }
    ]
  }
}
EOF
    
    # Set permissions
    chown root:root /etc/xray/b.json
    chmod 644 /etc/xray/b.json
    
    # Generate Nginx configuration
    print_info "Generating Nginx configuration..."
    cat > /etc/nginx/conf.d/stealth-$TUNNEL_PORT.conf << EOF
# Public HTTP -> redirect to HTTPS
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
}

# Public HTTPS decoy site
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name $DOMAIN;

    ssl_certificate     /etc/ssl/certs/decoy.crt;
    ssl_certificate_key /etc/ssl/private/decoy.key;

    # Minimal "normal" site
    root /var/www/html;
    index index.html;

    # Security headers (optional but fine)
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Serve files; no tunnel proxy here
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Block dotfiles & configs
    location ~ /\\.         { deny all; }
    location ~ \\.(log|conf)\$ { deny all; }
}
EOF
    
    # Create decoy SSL certificates if they don't exist
    if [ ! -f "/etc/ssl/certs/decoy.crt" ]; then
        print_info "Creating decoy SSL certificates..."
        mkdir -p /etc/ssl/certs /etc/ssl/private
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/decoy.key \
            -out /etc/ssl/certs/decoy.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    fi
    
    # Create web root and index
    mkdir -p /var/www/html
    cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
</head>
<body>
    <h1>Welcome to our website</h1>
    <p>This is a normal website.</p>
</body>
</html>
HTML
    
    # Create systemd service
    print_info "Creating systemd service..."
    cat > /etc/systemd/system/xray-b.service << 'EOF'
[Unit]
Description=Xray Service (Server B)
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/b.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start services
    systemctl enable xray-b
    systemctl restart xray-b
    systemctl enable nginx
    systemctl restart nginx
    
    print_success "Server B installation completed!"
    echo
    print_info "Service status:"
    systemctl status xray-b --no-pager
    echo
    systemctl status nginx --no-pager
    echo
    print_info "Configuration files:"
    echo "  Xray config: /etc/xray/b.json"
    echo "  Nginx config: /etc/nginx/conf.d/stealth-$TUNNEL_PORT.conf"
    echo "  Logs location: /var/log/xray/"
    echo
    print_success "Tunnel is now active!"
    print_info "Traffic on ports 80,443 will go to nginx"
    print_info "Traffic on ports 8080,$TARGET_PORT,8082,9090 will go to your target service"
}

# Run main function
main "$@"
