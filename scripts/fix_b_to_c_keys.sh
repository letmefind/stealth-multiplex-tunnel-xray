#!/bin/bash

# Fix B->C Connection Keys Script
# Regenerates and updates B->C connection keys if they're using the wrong keys

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration files
XRAY_CONF_DIR="/etc/xray"
CONFIG_B="$XRAY_CONF_DIR/b.json"
CONFIG_C="$XRAY_CONF_DIR/c.json"

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

# Generate Reality keys
generate_reality_keys() {
    if command -v xray >/dev/null 2>&1; then
        KEYS=$(xray x25519 2>/dev/null)
        PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | cut -d' ' -f3)
        PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | cut -d' ' -f3)
        
        # Generate 20 different short IDs
        SHORT_IDS=""
        for i in {1..20}; do
            SHORT_ID=$(openssl rand -hex 8 2>/dev/null)
            if [ $i -eq 1 ]; then
                SHORT_IDS="\"$SHORT_ID\""
            else
                SHORT_IDS="$SHORT_IDS, \"$SHORT_ID\""
            fi
        done
        
        if [ -z "$PUBLIC_KEY" ] || [ -z "$PRIVATE_KEY" ]; then
            log_error "Failed to generate Reality keys"
            return 1
        fi
        
        log_success "Generated new Reality keys for B->C connection"
        return 0
    else
        log_error "Xray not found. Please install Xray first."
        return 1
    fi
}

# Generate UUID
generate_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import uuid; print(uuid.uuid4())"
    else
        cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "12345678-1234-1234-1234-123456789abc"
    fi
}

# Main function
main() {
    echo "=========================================="
    echo "  Fix B->C Connection Keys"
    echo "=========================================="
    echo
    
    check_root
    check_jq
    
    # Check if configs exist
    if [[ ! -f "$CONFIG_B" ]]; then
        log_error "Server B config not found: $CONFIG_B"
        exit 1
    fi
    
    if [[ ! -f "$CONFIG_C" ]]; then
        log_error "Server C config not found: $CONFIG_C"
        exit 1
    fi
    
    # Check if B->C connection exists
    local has_b_to_c=$(jq -r '.outbounds[]? | select(.tag == "to-c") | .tag' "$CONFIG_B" 2>/dev/null)
    if [[ -z "$has_b_to_c" ]]; then
        log_error "Server B does not have B->C outbound configured"
        log_info "Please configure Server B to forward to Server C first"
        exit 1
    fi
    
    # Get current A->B keys for comparison
    local a_b_public_key=$(jq -r '.inbounds[]? | select(.tag == "tunnel-in") | .streamSettings.realitySettings.privateKey' "$CONFIG_B" 2>/dev/null)
    local current_b_c_public_key=$(jq -r '.outbounds[]? | select(.tag == "to-c") | .streamSettings.realitySettings.publicKey' "$CONFIG_B" 2>/dev/null)
    
    # Check if B->C is using same keys as A->B
    if [[ "$current_b_c_public_key" != "$a_b_public_key" ]]; then
        log_warning "B->C connection already uses different keys than A->B"
        log_info "Current B->C public key: $current_b_c_public_key"
        read -p "Do you want to regenerate keys anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 0
        fi
    else
        log_warning "B->C connection is using the same keys as A->B (WRONG!)"
        log_info "This will regenerate new keys for B->C connection"
    fi
    
    # Generate new keys
    log_info "Generating new Reality keys for B->C connection..."
    if ! generate_reality_keys; then
        log_error "Failed to generate keys"
        exit 1
    fi
    
    # Generate new UUID
    local new_uuid=$(generate_uuid)
    
    # Get first short ID
    local first_short_id=$(echo "$SHORT_IDS" | cut -d',' -f1 | tr -d '"' | tr -d ' ')
    
    # Get server name from current config
    local server_name=$(jq -r '.outbounds[]? | select(.tag == "to-c") | .streamSettings.realitySettings.serverName' "$CONFIG_B" 2>/dev/null)
    if [[ -z "$server_name" ]]; then
        server_name="www.accounts.accesscontrol.windows.net"
    fi
    
    # Get Server C IP and port
    local server_c_ip=$(jq -r '.outbounds[]? | select(.tag == "to-c") | .settings.vnext[0].address' "$CONFIG_B" 2>/dev/null)
    local server_c_port=$(jq -r '.outbounds[]? | select(.tag == "to-c") | .settings.vnext[0].port' "$CONFIG_B" 2>/dev/null)
    
    log_info "New B->C connection details:"
    echo "  UUID: $new_uuid"
    echo "  Public Key: $PUBLIC_KEY"
    echo "  Private Key: $PRIVATE_KEY"
    echo "  Short IDs: $SHORT_IDS"
    echo "  First Short ID: $first_short_id"
    echo "  Server Name: $server_name"
    echo
    
    # Create backups
    log_info "Creating backups..."
    cp "$CONFIG_B" "$CONFIG_B.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_C" "$CONFIG_C.backup.$(date +%Y%m%d_%H%M%S)"
    log_success "Backups created"
    
    # Update Server B config
    log_info "Updating Server B config..."
    jq --arg uuid "$new_uuid" \
       --arg public_key "$PUBLIC_KEY" \
       --arg short_id "$first_short_id" \
       '.outbounds[] |= if .tag == "to-c" then 
            .settings.vnext[0].users[0].id = $uuid |
            .streamSettings.realitySettings.publicKey = $public_key |
            .streamSettings.realitySettings.shortId = $short_id
        else . end' \
       "$CONFIG_B" > "$CONFIG_B.tmp" && mv "$CONFIG_B.tmp" "$CONFIG_B"
    
    log_success "Server B config updated"
    
    # Update Server C config
    log_info "Updating Server C config..."
    jq --arg uuid "$new_uuid" \
       --arg private_key "$PRIVATE_KEY" \
       --argjson short_ids "[$SHORT_IDS]" \
       '.inbounds[] |= if .tag == "tunnel-in" then 
            .settings.clients[0].id = $uuid |
            .streamSettings.realitySettings.privateKey = $private_key |
            .streamSettings.realitySettings.shortIds = $short_ids
        else . end' \
       "$CONFIG_C" > "$CONFIG_C.tmp" && mv "$CONFIG_C.tmp" "$CONFIG_C"
    
    log_success "Server C config updated"
    
    # Validate JSON
    if ! jq empty "$CONFIG_B" 2>/dev/null; then
        log_error "Server B config has invalid JSON after update"
        exit 1
    fi
    
    if ! jq empty "$CONFIG_C" 2>/dev/null; then
        log_error "Server C config has invalid JSON after update"
        exit 1
    fi
    
    log_success "Configurations updated successfully!"
    echo
    log_info "Next steps:"
    log_info "1. Restart Server B: systemctl restart xray-b"
    log_info "2. Restart Server C: systemctl restart xray-c"
    log_info "3. Verify connection: systemctl status xray-b xray-c"
    echo
    log_warning "IMPORTANT: Save these new B->C connection details:"
    echo "  UUID: $new_uuid"
    echo "  Private Key: $PRIVATE_KEY"
    echo "  Short IDs: $SHORT_IDS"
}

# Run main function
main "$@"

