#!/bin/bash

# Xray Offline Installation Script
# For servers with limited internet connectivity (e.g., China)
# Based on Xray-core v1.8.18 (latest stable)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Print functions
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

print_header() {
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Xray Offline Installation Script${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}For servers with limited internet connectivity${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    echo
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Detect system architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="64" ;;
        aarch64|arm64) ARCH="arm64-v8a" ;;
        armv7l) ARCH="arm32-v7a" ;;
        *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    print_info "Detected architecture: $ARCH"
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    
    if command -v apt >/dev/null 2>&1; then
        apt update
        apt install -y wget curl unzip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y wget curl unzip
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y wget curl unzip
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm wget curl unzip
    else
        print_warning "Package manager not detected. Please install wget, curl, and unzip manually."
    fi
}

# Download Xray binary
download_xray() {
    print_info "Downloading Xray binary..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Xray version (latest stable)
    XRAY_VERSION="v1.8.18"
    
    # Multiple download mirrors for better reliability
    DOWNLOAD_URLS=(
        "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${ARCH}.zip"
        "https://ghproxy.com/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${ARCH}.zip"
        "https://mirror.ghproxy.com/https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${ARCH}.zip"
        "https://download.fastgit.org/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${ARCH}.zip"
    )
    
    for url in "${DOWNLOAD_URLS[@]}"; do
        print_info "Trying to download from: $url"
        if wget -q --timeout=15 "$url" -O xray.zip || curl -L --connect-timeout 15 "$url" -o xray.zip; then
            print_success "Downloaded Xray binary successfully"
            break
        else
            print_warning "Failed to download from: $url"
        fi
    done
    
    if [ ! -f "xray.zip" ]; then
        print_error "Failed to download Xray binary from all mirrors"
        print_info "Manual installation instructions:"
        print_info "1. Go to: https://github.com/XTLS/Xray-core/releases"
        print_info "2. Download Xray-linux-${ARCH}.zip"
        print_info "3. Extract and place xray binary in /usr/local/bin/"
        print_info "4. Run: chmod +x /usr/local/bin/xray"
        cd /
        rm -rf "$TEMP_DIR"
        exit 1
    fi
}

# Install Xray
install_xray() {
    print_info "Installing Xray..."
    
    # Extract archive
    if command -v unzip >/dev/null 2>&1; then
        unzip -q xray.zip
    else
        print_error "unzip command not found. Please install unzip first."
        cd /
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Install binary
    if [ -f "xray" ]; then
        cp xray /usr/local/bin/
        chmod +x /usr/local/bin/xray
        
        # Create systemd service
        cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
        
        # Create directories
        mkdir -p /etc/xray /var/log/xray
        chown nobody:nogroup /var/log/xray
        
        # Enable service
        systemctl daemon-reload
        systemctl enable xray
        
        print_success "Xray installed successfully"
        print_info "Xray version: $(/usr/local/bin/xray version | head -1)"
        
        cd /
        rm -rf "$TEMP_DIR"
    else
        print_error "Xray binary not found in downloaded archive"
        cd /
        rm -rf "$TEMP_DIR"
        exit 1
    fi
}

# Test installation
test_installation() {
    print_info "Testing Xray installation..."
    
    if command -v xray >/dev/null 2>&1; then
        print_success "Xray is installed and accessible"
        print_info "Version: $(xray version | head -1)"
        print_info "Location: $(which xray)"
        
        # Test Reality key generation
        if xray x25519 >/dev/null 2>&1; then
            print_success "Reality key generation works"
        else
            print_warning "Reality key generation test failed"
        fi
    else
        print_error "Xray installation failed"
        exit 1
    fi
}

# Main installation process
main() {
    print_header
    
    print_info "Starting Xray offline installation..."
    
    check_root
    detect_arch
    install_dependencies
    download_xray
    install_xray
    test_installation
    
    print_success "Xray offline installation completed successfully!"
    print_info "You can now run the main tunnel installation script:"
    print_info "sudo bash install"
    
    echo
    print_info "Service management commands:"
    print_info "• Start: systemctl start xray"
    print_info "• Stop: systemctl stop xray"
    print_info "• Status: systemctl status xray"
    print_info "• Logs: journalctl -u xray -f"
}

# Run main function
main "$@"
