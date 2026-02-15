#!/bin/bash

# BBR and TCP Buffer Optimization Script
# این اسکریپت تنظیمات BBR و TCP Buffering را اعمال می‌کند

# Don't exit on error - we'll handle missing sysctl parameters gracefully
set +e

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

log_info "Configuring BBR and TCP buffer optimizations..."

# Check if BBR module is available
if ! lsmod | grep -q tcp_bbr; then
    log_info "Loading BBR kernel module..."
    modprobe tcp_bbr 2>/dev/null || log_warning "Could not load tcp_bbr module. BBR may not be available."
fi

# Check current congestion control
if [ -f /proc/sys/net/ipv4/tcp_congestion_control ]; then
    CURRENT_CC=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
    log_info "Current congestion control: $CURRENT_CC"
fi

# Function to check if sysctl parameter exists
check_sysctl_exists() {
    local param="$1"
    [ -f "/proc/sys/${param//\./\/}" ] 2>/dev/null
}

# Create sysctl configuration file
log_info "Creating sysctl configuration file..."

# Start building the config file
cat > /etc/sysctl.d/99-xray-optimization.conf << 'EOF'
# BBR Congestion Control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP Buffer Optimizations for High Bandwidth
# Max receive buffer: 128MB
net.core.rmem_max=134217728
# Max send buffer: 128MB
net.core.wmem_max=134217728
# TCP receive buffer: min 4KB, default 85KB, max 64MB
net.ipv4.tcp_rmem=4096 87380 67108864
# TCP send buffer: min 4KB, default 64KB, max 64MB
net.ipv4.tcp_wmem=4096 65536 67108864
# TCP memory: min 256KB, pressure 512KB, max 1GB
net.ipv4.tcp_mem=262144 524288 1048576

# TCP Window Scaling (enables high bandwidth on long-distance connections)
net.ipv4.tcp_window_scaling=1
# TCP Timestamps (helps with RTT measurement)
net.ipv4.tcp_timestamps=1
# TCP Selective Acknowledgment (improves performance on lossy networks)
net.ipv4.tcp_sack=1

# TCP Fast Open (reduces connection latency)
net.ipv4.tcp_fastopen=3

# Socket Options
# Maximum number of pending connections
net.core.somaxconn=65535
# Maximum number of packets queued on input side
net.core.netdev_max_backlog=5000

# TCP Keepalive Settings
# Time before sending keepalive probes: 10 minutes
net.ipv4.tcp_keepalive_time=600
# Number of keepalive probes
net.ipv4.tcp_keepalive_probes=3
# Interval between keepalive probes: 15 seconds
net.ipv4.tcp_keepalive_intvl=15

# TCP SYN Cookies (DDoS protection)
net.ipv4.tcp_syncookies=1

# TCP Fin Timeout (time to wait for FIN before closing connection)
net.ipv4.tcp_fin_timeout=30

# TCP Time Wait Reuse (allows reusing TIME_WAIT sockets)
net.ipv4.tcp_tw_reuse=1

# MTU Settings for Packet Tunnel
# Default MTU for packet tunnel: 1350 (optimal for VPN/tunnel connections)
# This prevents packet fragmentation and improves performance
# Note: Actual MTU should be set on the tunnel interface itself
# For TUN interfaces, configure MTU in Xray TUN settings: "MTU": 1350
net.ipv4.ip_no_pmtu_disc=0
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_base_mss=1024

# IP Forwarding (uncomment if needed for routing)
# net.ipv4.ip_forward=1
EOF

# Add optional connection tracking settings if available
if check_sysctl_exists "net.netfilter.nf_conntrack_max"; then
    log_info "Adding nf_conntrack settings (connection tracking available)"
    cat >> /etc/sysctl.d/99-xray-optimization.conf << 'EOF'

# Connection Tracking (for high connection counts)
# Only added if nf_conntrack module is loaded
net.netfilter.nf_conntrack_max=1000000
EOF
    # Check for legacy ip_conntrack (older kernels)
    if check_sysctl_exists "net.ipv4.netfilter.ip_conntrack_max"; then
        echo "net.ipv4.netfilter.ip_conntrack_max=1000000" >> /etc/sysctl.d/99-xray-optimization.conf
    fi
else
    log_warning "nf_conntrack module not loaded - skipping connection tracking settings"
    log_info "To enable connection tracking, run: modprobe nf_conntrack"
fi

log_success "Configuration file created: /etc/sysctl.d/99-xray-optimization.conf"

# Apply sysctl settings (ignore errors for missing parameters)
log_info "Applying sysctl settings..."
log_info "Note: Some parameters may not exist on your system - this is normal"
sysctl --system 2>&1 | grep -v "cannot stat" || true

# Verify BBR is enabled
if [ -f /proc/sys/net/ipv4/tcp_congestion_control ]; then
    CURRENT_CC=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
    if [ "$CURRENT_CC" = "bbr" ]; then
        log_success "BBR enabled successfully: $CURRENT_CC"
    else
        log_warning "BBR not enabled. Current: $CURRENT_CC"
        log_info "To enable BBR manually, run: modprobe tcp_bbr && sysctl -w net.ipv4.tcp_congestion_control=bbr"
    fi
fi

# Display current settings
log_info "Current TCP settings:"
echo "  Congestion Control: $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo 'N/A')"
echo "  Default Qdisc: $(cat /proc/sys/net/core/default_qdisc 2>/dev/null || echo 'N/A')"
echo "  Max Receive Buffer: $(cat /proc/sys/net/core/rmem_max 2>/dev/null || echo 'N/A')"
echo "  Max Send Buffer: $(cat /proc/sys/net/core/wmem_max 2>/dev/null || echo 'N/A')"
echo "  TCP Window Scaling: $(cat /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null || echo 'N/A')"
echo "  TCP Fast Open: $(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || echo 'N/A')"

log_success "TCP buffer optimizations configured successfully!"
log_info "Settings will persist across reboots."
echo ""
log_info "To verify BBR is working, run:"
echo "  sysctl net.ipv4.tcp_congestion_control"
echo "  ss -i | grep bbr"
