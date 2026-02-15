#!/bin/bash

# Find Optimal MTU Script
# This script finds the optimal MTU for tunnel connections
# Can be used standalone or sourced from other scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to find optimal MTU for tunnel
find_optimal_mtu() {
    local target_host="${1:-8.8.8.8}"
    local start_mtu="${2:-1500}"
    local min_mtu="${3:-1280}"
    local optimal_mtu=1350  # Default for tunnel
    
    log_info "Finding optimal MTU (testing against $target_host)..."
    log_info "This may take a moment..."
    
    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
        log_warning "ping command not found, using default MTU: $optimal_mtu"
        echo "$optimal_mtu"
        return 0
    fi
    
    # Test MTU values from start_mtu down to min_mtu
    local test_mtu=$start_mtu
    local found_optimal=false
    
    # For tunnel, we typically want MTU around 1350-1400
    # So we'll test common tunnel MTU values first
    local tunnel_mtus=(1500 1450 1400 1350 1300 1280)
    
    for mtu in "${tunnel_mtus[@]}"; do
        # Calculate packet size (MTU - IP header - ICMP header = MTU - 28)
        local packet_size=$((mtu - 28))
        
        if [ $packet_size -lt 0 ]; then
            continue
        fi
        
        # Test with ping (don't fragment flag)
        if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
            optimal_mtu=$mtu
            found_optimal=true
            log_success "Found working MTU: $optimal_mtu"
            break
        fi
    done
    
    # If no optimal found in tunnel range, try binary search
    if [ "$found_optimal" = false ]; then
        log_info "Testing MTU range..."
        local low=$min_mtu
        local high=$start_mtu
        local best_mtu=$min_mtu
        
        while [ $low -le $high ]; do
            local mid=$(( (low + high) / 2 ))
            local packet_size=$((mid - 28))
            
            if [ $packet_size -lt 0 ]; then
                low=$((mid + 1))
                continue
            fi
            
            if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
                best_mtu=$mid
                optimal_mtu=$mid
                low=$((mid + 1))
            else
                high=$((mid - 1))
            fi
        done
        
        if [ $best_mtu -gt $min_mtu ]; then
            optimal_mtu=$best_mtu
            log_success "Found optimal MTU: $optimal_mtu"
        else
            log_warning "Could not determine optimal MTU, using default: $optimal_mtu"
        fi
    fi
    
    echo "$optimal_mtu"
}

# Main execution (if run directly, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    OPTIMAL_MTU=$(find_optimal_mtu "$@")
    echo "$OPTIMAL_MTU"
fi
