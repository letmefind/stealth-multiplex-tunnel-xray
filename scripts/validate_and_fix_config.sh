#!/bin/bash

# Xray Configuration Validation and Fix Script
# Validates and fixes common configuration issues

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
CONFIG_A="$XRAY_CONF_DIR/a.json"
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

# Check if config file exists and is valid JSON
check_config_file() {
    local config_file="$1"
    local server_name="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log_warning "$server_name config not found: $config_file"
        return 1
    fi
    
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "$server_name config has invalid JSON: $config_file"
        return 1
    fi
    
    return 0
}

# Extract value from JSON config
extract_value() {
    local config_file="$1"
    local json_path="$2"
    jq -r "$json_path" "$config_file" 2>/dev/null || echo ""
}

# Validate A->B connection
validate_a_to_b() {
    log_info "Validating A->B connection..."
    
    local errors=0
    
    # Check if configs exist
    if ! check_config_file "$CONFIG_A" "Server A"; then
        return 1
    fi
    
    if ! check_config_file "$CONFIG_B" "Server B"; then
        return 1
    fi
    
    # Extract A->B connection details
    local a_uuid=$(extract_value "$CONFIG_A" '.outbounds[] | select(.tag == "to-b") | .settings.vnext[0].users[0].id')
    local a_public_key=$(extract_value "$CONFIG_A" '.outbounds[] | select(.tag == "to-b") | .streamSettings.realitySettings.publicKey')
    local a_short_id=$(extract_value "$CONFIG_A" '.outbounds[] | select(.tag == "to-b") | .streamSettings.realitySettings.shortId')
    local a_server_name=$(extract_value "$CONFIG_A" '.outbounds[] | select(.tag == "to-b") | .streamSettings.realitySettings.serverName')
    
    # Extract B inbound details
    local b_uuid=$(extract_value "$CONFIG_B" '.inbounds[] | select(.tag == "tunnel-in") | .settings.clients[0].id')
    local b_private_key=$(extract_value "$CONFIG_B" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.privateKey')
    local b_short_ids=$(extract_value "$CONFIG_B" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.shortIds | join(",")')
    local b_server_name=$(extract_value "$CONFIG_B" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.serverNames[0]')
    
    # Validate UUID
    if [[ "$a_uuid" != "$b_uuid" ]]; then
        log_error "A->B UUID mismatch:"
        log_error "  Server A UUID: $a_uuid"
        log_error "  Server B UUID: $b_uuid"
        errors=$((errors + 1))
    else
        log_success "A->B UUID matches: $a_uuid"
    fi
    
    # Validate Reality keys (public key on A should match private key on B)
    # Note: We can't directly validate key pairs, but we check they're different
    if [[ -z "$a_public_key" ]] || [[ -z "$b_private_key" ]]; then
        log_error "A->B Reality keys missing"
        errors=$((errors + 1))
    else
        log_success "A->B Reality keys present"
    fi
    
    # Validate shortId
    if [[ -n "$a_short_id" ]] && [[ -n "$b_short_ids" ]]; then
        if echo "$b_short_ids" | grep -q "$a_short_id"; then
            log_success "A->B shortId '$a_short_id' found in Server B shortIds"
        else
            log_error "A->B shortId mismatch:"
            log_error "  Server A shortId: $a_short_id"
            log_error "  Server B shortIds: $b_short_ids"
            errors=$((errors + 1))
        fi
    fi
    
    # Validate server name
    if [[ "$a_server_name" != "$b_server_name" ]]; then
        log_warning "A->B server name mismatch (may be intentional):"
        log_warning "  Server A: $a_server_name"
        log_warning "  Server B: $b_server_name"
    else
        log_success "A->B server name matches: $a_server_name"
    fi
    
    return $errors
}

# Validate B->C connection
validate_b_to_c() {
    log_info "Validating B->C connection..."
    
    local errors=0
    
    # Check if configs exist
    if ! check_config_file "$CONFIG_B" "Server B"; then
        return 1
    fi
    
    if ! check_config_file "$CONFIG_C" "Server C"; then
        log_warning "Server C config not found - B->C connection not configured"
        return 0
    fi
    
    # Extract B->C connection details
    local b_c_uuid=$(extract_value "$CONFIG_B" '.outbounds[] | select(.tag == "to-c") | .settings.vnext[0].users[0].id')
    local b_c_public_key=$(extract_value "$CONFIG_B" '.outbounds[] | select(.tag == "to-c") | .streamSettings.realitySettings.publicKey')
    local b_c_short_id=$(extract_value "$CONFIG_B" '.outbounds[] | select(.tag == "to-c") | .streamSettings.realitySettings.shortId')
    local b_c_server_name=$(extract_value "$CONFIG_B" '.outbounds[] | select(.tag == "to-c") | .streamSettings.realitySettings.serverName')
    
    # Extract A->B connection details for comparison
    local b_a_public_key=$(extract_value "$CONFIG_B" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.privateKey')
    
    # Extract C inbound details
    local c_uuid=$(extract_value "$CONFIG_C" '.inbounds[] | select(.tag == "tunnel-in") | .settings.clients[0].id')
    local c_private_key=$(extract_value "$CONFIG_C" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.privateKey')
    local c_short_ids=$(extract_value "$CONFIG_C" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.shortIds | join(",")')
    local c_server_name=$(extract_value "$CONFIG_C" '.inbounds[] | select(.tag == "tunnel-in") | .streamSettings.realitySettings.serverNames[0]')
    
    # Check if B->C connection exists
    if [[ -z "$b_c_uuid" ]]; then
        log_warning "Server B does not have B->C outbound configured"
        return 0
    fi
    
    # Validate UUID
    if [[ "$b_c_uuid" != "$c_uuid" ]]; then
        log_error "B->C UUID mismatch:"
        log_error "  Server B UUID: $b_c_uuid"
        log_error "  Server C UUID: $c_uuid"
        errors=$((errors + 1))
    else
        log_success "B->C UUID matches: $b_c_uuid"
    fi
    
    # Check if B->C uses same keys as A->B (this is wrong!)
    if [[ "$b_c_public_key" == "$b_a_public_key" ]]; then
        log_error "B->C connection uses same public key as A->B (WRONG!)"
        log_error "  B->C public key: $b_c_public_key"
        log_error "  A->B public key: $b_a_public_key"
        log_error "  These should be DIFFERENT key pairs!"
        errors=$((errors + 1))
    else
        log_success "B->C uses different public key than A->B"
    fi
    
    # Validate shortId
    if [[ -n "$b_c_short_id" ]] && [[ -n "$c_short_ids" ]]; then
        if echo "$c_short_ids" | grep -q "$b_c_short_id"; then
            log_success "B->C shortId '$b_c_short_id' found in Server C shortIds"
        else
            log_error "B->C shortId mismatch:"
            log_error "  Server B shortId: $b_c_short_id"
            log_error "  Server C shortIds: $c_short_ids"
            errors=$((errors + 1))
        fi
    fi
    
    # Validate server name
    if [[ "$b_c_server_name" != "$c_server_name" ]]; then
        log_warning "B->C server name mismatch (may be intentional):"
        log_warning "  Server B: $b_c_server_name"
        log_warning "  Server C: $c_server_name"
    else
        log_success "B->C server name matches: $b_c_server_name"
    fi
    
    return $errors
}

# Fix duplicate ports in routing rules
fix_duplicate_ports() {
    log_info "Checking for duplicate ports in routing rules..."
    
    local fixed=0
    
    for config_file in "$CONFIG_A" "$CONFIG_B" "$CONFIG_C"; do
        if [[ ! -f "$config_file" ]]; then
            continue
        fi
        
        local server_name=$(basename "$config_file" .json | tr '[:lower:]' '[:upper:]')
        
        # Get all routing rules with ports
        local rules=$(jq -r '.routing.rules[]? | select(.port != null) | "\(.inboundTag[0] // "unknown")|\(.port)|\(.outboundTag)"' "$config_file" 2>/dev/null)
        
        while IFS='|' read -r inbound_tag port outbound_tag; do
            if [[ -z "$port" ]]; then
                continue
            fi
            
            # Check for duplicate ports
            local port_list=$(echo "$port" | tr ',' '\n' | sort | uniq -d)
            if [[ -n "$port_list" ]]; then
                log_warning "$server_name: Found duplicate ports in routing rule: $port"
                
                # Remove duplicates
                local fixed_ports=$(echo "$port" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
                
                # Create backup
                cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
                
                # Fix the port
                jq --arg inbound "$inbound_tag" --arg port "$port" --arg fixed "$fixed_ports" \
                   '.routing.rules |= map(if .inboundTag[0] == $inbound and .port == $port then .port = $fixed else . end)' \
                   "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
                
                log_success "$server_name: Fixed duplicate ports: $port -> $fixed_ports"
                fixed=$((fixed + 1))
            fi
        done <<< "$rules"
    done
    
    if [[ $fixed -eq 0 ]]; then
        log_success "No duplicate ports found"
    fi
    
    return $fixed
}

# Show configuration summary
show_summary() {
    log_info "Configuration Summary:"
    echo
    
    if [[ -f "$CONFIG_A" ]]; then
        log_info "Server A (a.json):"
        local a_ports=$(extract_value "$CONFIG_A" '.inbounds[] | .port' | tr '\n' ',' | sed 's/,$//')
        local a_target=$(extract_value "$CONFIG_A" '.outbounds[] | select(.tag == "to-b") | .settings.vnext[0].address')
        echo "  Ports: $a_ports"
        echo "  Target: $a_target"
        echo
    fi
    
    if [[ -f "$CONFIG_B" ]]; then
        log_info "Server B (b.json):"
        local b_port=$(extract_value "$CONFIG_B" '.inbounds[] | select(.tag == "tunnel-in") | .port')
        local b_has_c=$(extract_value "$CONFIG_B" '.outbounds[] | select(.tag == "to-c") | .tag')
        echo "  Inbound port: $b_port"
        if [[ -n "$b_has_c" ]]; then
            local b_c_target=$(extract_value "$CONFIG_B" '.outbounds[] | select(.tag == "to-c") | .settings.vnext[0].address')
            echo "  Forwarding to Server C: $b_c_target"
        else
            echo "  Routing to local services"
        fi
        echo
    fi
    
    if [[ -f "$CONFIG_C" ]]; then
        log_info "Server C (c.json):"
        local c_port=$(extract_value "$CONFIG_C" '.inbounds[] | select(.tag == "tunnel-in") | .port')
        local c_target_port=$(extract_value "$CONFIG_C" '.outbounds[] | select(.tag == "to-xmplus") | .settings.redirect' | sed 's/.*://')
        echo "  Inbound port: $c_port"
        echo "  Target port: $c_target_port"
        echo
    fi
}

# Main validation function
main() {
    echo "=========================================="
    echo "  Xray Configuration Validator & Fixer"
    echo "=========================================="
    echo
    
    check_root
    check_jq
    
    local total_errors=0
    local fixed_issues=0
    
    # Show current configuration
    show_summary
    echo
    
    # Validate A->B connection
    if validate_a_to_b; then
        log_success "A->B connection validation passed"
    else
        total_errors=$((total_errors + $?))
    fi
    echo
    
    # Validate B->C connection
    if validate_b_to_c; then
        log_success "B->C connection validation passed"
    else
        total_errors=$((total_errors + $?))
    fi
    echo
    
    # Fix duplicate ports
    if fix_duplicate_ports; then
        fixed_issues=$((fixed_issues + $?))
    fi
    echo
    
    # Final summary
    echo "=========================================="
    if [[ $total_errors -eq 0 ]] && [[ $fixed_issues -eq 0 ]]; then
        log_success "All validations passed! No issues found."
    else
        if [[ $total_errors -gt 0 ]]; then
            log_error "Found $total_errors validation error(s) that need manual fixing"
        fi
        if [[ $fixed_issues -gt 0 ]]; then
            log_success "Automatically fixed $fixed_issues issue(s)"
        fi
    fi
    echo "=========================================="
    
    if [[ $total_errors -gt 0 ]]; then
        echo
        log_info "To fix key mismatches, you need to:"
        log_info "1. Re-run Server B installation and choose to forward to Server C"
        log_info "2. Use the NEW keys generated for B->C connection (not A->B keys)"
        log_info "3. Re-run Server C installation with the correct B->C keys"
        exit 1
    fi
    
    exit 0
}

# Run main function
main "$@"

