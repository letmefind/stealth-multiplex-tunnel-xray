#!/bin/bash

# VLESS+REALITY Tunnel Installation Script - Server A (Tunnel Server)
# This script installs and configures Xray on Server A

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

# Function to generate UUID
generate_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import uuid; print(uuid.uuid4())"
    else
        # Fallback UUID generation
        cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "12345678-1234-1234-1234-123456789abc"
    fi
}

# Function to generate Reality keys
generate_reality_keys() {
    if command -v xray >/dev/null 2>&1; then
        # Use xray to generate keys
        KEYS=$(xray x25519 2>/dev/null)
        PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | cut -d' ' -f3)
        PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | cut -d' ' -f3)
        SHORT_ID=$(openssl rand -hex 8 2>/dev/null)
        
        print_success "Generated Reality keys:"
        echo "  Public Key: $PUBLIC_KEY"
        echo "  Private Key: $PRIVATE_KEY"
        echo "  Short ID: $SHORT_ID"
    else
        print_warning "Xray not found, using default keys"
        PUBLIC_KEY="wwgbwD3pK6aBzxtMzAyAdzV8430zraDqrCrH7tivDV4"
        PRIVATE_KEY="kEHlrW7KE0TxG_UhhOwE2YzMbzGlWign5rSrcweFVkY"
        SHORT_ID="db78ea236c7e33f5"
        
        print_success "Using default Reality keys:"
        echo "  Public Key: $PUBLIC_KEY"
        echo "  Private Key: $PRIVATE_KEY"
        echo "  Short ID: $SHORT_ID"
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

# Function to validate IP
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    return 1
}

# Main installation function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  VLESS+REALITY Server A Install${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    print_info "This script will install and configure Xray on Server A (Tunnel Server)"
    echo
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
    
    # Get configuration from user
    print_info "Please provide the following configuration details:"
    echo
    
    # Server B IP
    SERVER_B_IP=$(get_input "Server B IP address" "91.98.86.167")
    while ! validate_ip "$SERVER_B_IP"; do
        print_error "Invalid IP address format"
        SERVER_B_IP=$(get_input "Server B IP address" "91.98.86.167")
    done
    
    # Tunnel port
    TUNNEL_PORT=$(get_input "Tunnel port (VLESS connection port)" "8081")
    while ! validate_port "$TUNNEL_PORT"; do
        print_error "Invalid port number"
        TUNNEL_PORT=$(get_input "Tunnel port (VLESS connection port)" "8081")
    done
    
    # Server name for Reality
    SERVER_NAME=$(get_input "Reality server name (SNI)" "www.accounts.accesscontrol.windows.net")
    
    # Generate keys
    generate_reality_keys
    
    # Generate UUID
    UUID=$(generate_uuid)
    print_success "Generated UUID: $UUID"
    
    echo
    print_info "Configuration summary:"
    echo "  Server B IP: $SERVER_B_IP"
    echo "  Tunnel Port: $TUNNEL_PORT"
    echo "  Server Name: $SERVER_NAME"
    echo "  UUID: $UUID"
    echo "  Public Key: $PUBLIC_KEY"
    echo "  Private Key: $PRIVATE_KEY"
    echo "  Short ID: $SHORT_ID"
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
    
    # Create Xray directories
    mkdir -p /etc/xray
    mkdir -p /var/log/xray
    
    # Generate Server A configuration
    print_info "Generating Server A configuration..."
    cat > /etc/xray/a.json << EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "entry-80",
      "listen": "0.0.0.0",
      "port": 80,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1", "port": 80, "network": "tcp" }
    },
    {
      "tag": "entry-443",
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1", "port": 443, "network": "tcp" }
    },
    {
      "tag": "entry-8080",
      "listen": "0.0.0.0",
      "port": 8080,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1", "port": 8080, "network": "tcp" }
    },
    {
      "tag": "entry-8443",
      "listen": "0.0.0.0",
      "port": 8443,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1", "port": 8443, "network": "tcp" }
    }
  ],
  "outbounds": [
    {
      "tag": "to-b",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_B_IP",
            "port": $TUNNEL_PORT,
            "users": [
              { "id": "$UUID", "encryption": "none" }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "splithttp",
        "security": "reality",
        "realitySettings": {
          "serverName": "$SERVER_NAME",
          "publicKey": "$PUBLIC_KEY",
          "shortId": "$SHORT_ID",
          "fingerprint": "chrome",
          "spiderX": "/"
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
    },
    { "protocol": "freedom", "tag": "direct" }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      { "type": "field", "inboundTag": ["entry-80"],   "outboundTag": "to-b" },
      { "type": "field", "inboundTag": ["entry-443"],  "outboundTag": "to-b" },
      { "type": "field", "inboundTag": ["entry-8080"], "outboundTag": "to-b" },
      { "type": "field", "inboundTag": ["entry-8443"], "outboundTag": "to-b" }
    ]
  }
}
EOF
    
    # Set permissions
    chown root:root /etc/xray/a.json
    chmod 644 /etc/xray/a.json
    
    # Create systemd service
    print_info "Creating systemd service..."
    cat > /etc/systemd/system/xray-a.service << 'EOF'
[Unit]
Description=Xray Service (Server A)
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/a.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start service
    systemctl enable xray-a
    systemctl restart xray-a
    
    print_success "Server A installation completed!"
    echo
    print_info "Service status:"
    systemctl status xray-a --no-pager
    echo
    print_info "Configuration saved to: /etc/xray/a.json"
    print_info "Logs location: /var/log/xray/"
    echo
    print_warning "IMPORTANT: Save these details for Server B installation:"
    echo "  UUID: $UUID"
    echo "  Private Key: $PRIVATE_KEY"
    echo "  Short ID: $SHORT_ID"
    echo "  Server Name: $SERVER_NAME"
    echo "  Tunnel Port: $TUNNEL_PORT"
}

# Run main function
main "$@"
