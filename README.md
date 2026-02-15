# 🚀 Stealth Multiplex Tunnel Xray

<div align="center">

[![English](https://img.shields.io/badge/Language-English-blue.svg)](README.md)
[![Persian](https://img.shields.io/badge/زبان-فارسی-green.svg)](README_FA.md)
[![Xray Version](https://img.shields.io/badge/Xray-v26.2.2-success.svg)](https://github.com/XTLS/Xray-core/releases/tag/v26.2.2)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/letmefind/Easy-paqet?style=social)](https://github.com/letmefind/Easy-paqet)

**A production-ready, high-performance stealth tunnel solution with multiple transport protocols and advanced optimizations**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Support](#-support)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Transport Protocols](#-transport-protocols)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Performance Optimizations](#-performance-optimizations)
- [Management Tools](#-management-tools)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**Stealth Multiplex Tunnel Xray** is a comprehensive, production-ready tunneling solution that provides:

- 🔒 **Maximum Stealth** - Advanced DPI bypass with Reality protocol
- ⚡ **High Performance** - Optimized for speed and efficiency
- 🌐 **Multiple Transports** - XHTTP, TCP, WebSocket, and GRPC support
- 🛡️ **Enterprise Security** - TLS fingerprinting and certificate management
- 📊 **Production Ready** - Comprehensive monitoring and management tools

Built on **Xray-core v26.2.2** with cutting-edge optimizations for high user counts and maximum throughput.

---

## ✨ Features

### 🚀 Transport Protocols

| Protocol | Speed | Stealth | CDN Support | TLS | Best For |
|----------|-------|---------|-------------|-----|----------|
| **XHTTP + Reality** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | ✅ | Maximum stealth & DPI bypass |
| **TCP Raw** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ❌ | ❌ | Fastest performance |
| **WebSocket** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ❌ | CDN & web proxies |
| **GRPC** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ❌ | High performance & CDN |

### 🔒 Security & Stealth

- ✅ **Reality Protocol** - No real certificates needed, perfect forward secrecy
- ✅ **TLS Fingerprinting** - Chrome browser mimicry
- ✅ **Multiple Short IDs** - 20 unique identifiers for client distinction
- ✅ **Decoy Sites** - Legitimate-looking websites for camouflage
- ✅ **UUID Security** - Strong, unique identifiers per installation

### ⚡ Performance Optimizations

- ✅ **BBR Congestion Control** - Enabled by default for optimal throughput
- ✅ **TCP Buffer Optimization** - Tuned for high bandwidth (128MB buffers)
- ✅ **SplitHTTP Optimization** - CPU/RAM efficient settings for high user counts
- ✅ **Memory Optimization** - Reduced startup memory usage (v26.2.2)
- ✅ **Connection Tracking** - Optimized for 1M+ concurrent connections

### 🎯 Advanced Features

- ✅ **Multi-Port Support** - Dynamic port management
- ✅ **Port-Preserving Routing** - Maintains port numbers through tunnel
- ✅ **Multi-Hop Support** - Optional Server C for extended routing (A→B→C)
- ✅ **Interactive Installation** - User-friendly setup wizard
- ✅ **Comprehensive Tools** - Backup, monitoring, troubleshooting utilities

---

## 🚀 Quick Start

### Prerequisites

- Linux server (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- Root or sudo access
- At least 512MB RAM
- Network connectivity

### Installation

```bash
# Clone the repository
git clone https://github.com/letmefind/Easy-paqet.git
cd Easy-paqet
```

#### Option 1: Servers with Good Internet Connectivity (Recommended)

If your server has direct access to GitHub and good internet speed:

```bash
# Run the main installer (it will download Xray automatically)
sudo bash install
```

**What happens:**
- The installer automatically downloads Xray from GitHub
- Installs Xray and all dependencies
- Configures the tunnel based on your choices

#### Option 2: Servers with Limited Internet (China/Slow Networks)

If your server has limited internet access or cannot access GitHub directly:

```bash
# Step 1: Install Xray offline first
sudo bash install_xray_offline.sh

# Step 2: Then run the main installer
sudo bash install
```

**What happens:**
- `install_xray_offline.sh` downloads Xray using multiple mirrors (GitHub, ghproxy, fastgit)
- If all mirrors fail, it provides manual installation instructions
- `install` then uses the already-installed Xray to configure the tunnel

**Why two steps?**
- `install_xray_offline.sh` handles Xray installation with fallback mirrors
- `install` handles tunnel configuration (doesn't need to download Xray again)

### Installation Options

```bash
# Interactive mode (recommended)
sudo bash install

# Auto-detect server type
sudo bash install auto

# Specific server type
sudo bash install a    # Server A (Entry)
sudo bash install b    # Server B (Intermediate)
sudo bash install c    # Server C (Final Destination)
```

### What Happens During Installation

1. **Server Type Selection** - Choose A, B, or C
2. **Transport Protocol** - Select XHTTP/TCP/WebSocket/GRPC
3. **Configuration** - Enter connection details
4. **Key Generation** - Reality keys generated automatically
5. **Service Setup** - Systemd services configured
6. **Optimization** - BBR and TCP buffers optimized
7. **Firewall** - Rules configured automatically

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Devices                        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Server A (Entry)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Port 80  │  │ Port 443 │  │ Port 8080│  │ Port 8443│   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │             │             │          │
│       └─────────────┴─────────────┴─────────────┘          │
│                          │                                  │
│                    [VLESS Tunnel]                          │
│              (XHTTP/TCP/WS/GRPC)                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Server B (Intermediate)                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Tunnel Port (Receives from A)                │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                     │
│              ┌──────────┴──────────┐                          │
│              │                     │                          │
│         ┌────▼────┐          ┌────▼────┐                    │
│         │ Forward  │          │  Local  │                    │
│         │  to C    │          │Services │                    │
│         └──────────┘          └─────────┘                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ (Optional)
┌─────────────────────────────────────────────────────────────┐
│              Server C (Final Destination)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Tunnel Port (Receives from B)                │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                     │
│                   ┌─────▼─────┐                              │
│                   │   Local   │                              │
│                   │  Services │                              │
│                   └───────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

### Routing Modes

#### Direct Routing (A → B)
```
Client → Server A → Server B → Local Services
```
- **Use Case**: Simple two-server setup
- **Advantage**: Lower latency, simpler configuration

#### Multi-Hop Routing (A → B → C)
```
Client → Server A → Server B → Server C → Local Services
```
- **Use Case**: Extended routing, additional security layer
- **Advantage**: Enhanced security, geographic distribution

---

## 🌐 Transport Protocols

### 1. XHTTP (SplitHTTP) with Reality ⭐ Recommended

**Best for**: Maximum stealth and DPI bypass

**Features:**
- ✅ No real certificates required
- ✅ Perfect forward secrecy
- ✅ Chrome TLS fingerprinting
- ✅ Multiple short IDs (20 unique)
- ✅ Decoy destination (Microsoft)

**Configuration:**
```json
{
  "network": "splithttp",
  "security": "reality",
  "realitySettings": {
    "serverName": "www.accounts.accesscontrol.windows.net",
    "publicKey": "generated-x25519-public-key",
    "shortIds": ["id1", "id2", "..."],
    "fingerprint": "chrome"
  },
  "splithttpSettings": {
    "path": "/assets",
    "mode": "Paket-up",
    "scMaxEachPostBytes": 2097152,
    "scMaxConcurrentPosts": 4,
    "scMinPostsIntervalMs": 50,
    "xPaddingBytes": 0,
    "keepaliveperiod": 120
  }
}
```

**Performance Settings:**
- `scMaxEachPostBytes`: 2MB (reduced overhead)
- `scMaxConcurrentPosts`: 4 (reduced CPU usage)
- `scMinPostsIntervalMs`: 50ms (reduced CPU usage)
- `xPaddingBytes`: 0 (reduced RAM usage)
- `keepaliveperiod`: 120s (reduced connection overhead)
- `mode`: Paket-up (optimal for SplitHTTP)

### 2. TCP Raw

**Best for**: Maximum speed and simplicity

**Features:**
- ✅ Fastest protocol
- ✅ Lowest overhead
- ✅ No encryption overhead
- ✅ Simple configuration

**Configuration:**
```json
{
  "network": "tcp"
}
```

**Use Cases:**
- Internal networks
- High-speed requirements
- Low-latency applications

### 3. WebSocket

**Best for**: CDN integration and web proxies

**Features:**
- ✅ CDN compatible
- ✅ Web firewall bypass
- ✅ HTTP proxy support
- ✅ Configurable path

**Configuration:**
```json
{
  "network": "ws",
  "wsSettings": {
    "path": "/assets"
  }
}
```

**Use Cases:**
- Cloudflare/CDN integration
- Web-based proxies
- HTTP-only environments

### 4. GRPC

**Best for**: High performance and CDN

**Features:**
- ✅ CDN compatible
- ✅ HTTP/2 multiplexing
- ✅ High performance (up to 20% improvement with multiMode)
- ✅ Configurable service name
- ✅ Optimized with performance settings

**Configuration (Server A - Outbound):**
```json
{
  "network": "grpc",
  "grpcSettings": {
    "serviceName": "/xray.XrayService",
    "multiMode": true,
    "idle_timeout": 60,
    "health_check_timeout": 20,
    "permit_without_stream": false,
    "initial_windows_size": 65535
  }
}
```

**Performance Settings:**
- `multiMode`: Enables multi-mode for ~20% performance improvement
- `idle_timeout`: 60 seconds - triggers health checks when idle
- `health_check_timeout`: 20 seconds - timeout for health checks
- `initial_windows_size`: 65535 - optimal window size for HTTP/2 streams

**Use Cases:**
- High-performance requirements
- CDN integration
- Modern applications
- When maximum throughput is needed

---

## 📦 Installation

### Step-by-Step Installation

#### 1. Server B (Intermediate) Installation

```bash
sudo bash install
# Select: Server B
# Choose transport protocol
# Enter configuration details
```

**Required Information:**
- UUID (from Server A)
- Private Key (from Server A)
- Transport Protocol (must match Server A)
- Transport Path (if WebSocket/GRPC)
- Short IDs (if XHTTP)
- Server Name (if XHTTP)
- Tunnel Port
- Ports to forward

#### 2. Server A (Entry) Installation

```bash
sudo bash install
# Select: Server A
# Choose transport protocol
# Enter Server B details
```

**Required Information:**
- Server B IP address
- Tunnel Port
- Transport Protocol
- Transport Path (if WebSocket/GRPC)
- Server Name (if XHTTP)

**Generated Information (Save for Server B):**
- UUID
- Public Key (for Server A)
- Private Key (for Server B)
- Short IDs (20 different)
- Server Name

#### 3. Server C (Optional - Final Destination)

```bash
sudo bash install
# Select: Server C
# Enter B->C connection details
```

---

## ⚙️ Configuration

### SplitHTTP Optimization Settings

Optimized for high user counts and CPU/RAM efficiency:

```json
{
  "splithttpSettings": {
    "path": "/assets",
    "mode": "Paket-up",
    "scMaxEachPostBytes": 2097152,      // 2MB - Reduced overhead
    "scMaxConcurrentPosts": 4,          // Reduced CPU usage
    "scMinPostsIntervalMs": 50,         // Reduced CPU usage
    "noSSEHeader": false,               // Appears legitimate
    "noGRPCHeader": true,                // Reduces detection
    "xPaddingBytes": 0,                 // Reduced RAM usage
    "keepaliveperiod": 120              // Reduced connection overhead
  }
}
```

### BBR and TCP Optimization

Automatically configured during installation:

```bash
# Manual application
sudo bash scripts/apply_bbr_tcp_optimization.sh
```

**Settings Applied:**
- BBR congestion control
- TCP buffers: 128MB max (read/write)
- TCP window scaling
- TCP Fast Open
- Connection tracking: 1M max
- Socket options optimized
- MTU settings: Default 1350 for packet tunnel (prevents fragmentation)

**Full Documentation:** [BBR_TCP_OPTIMIZATION.md](BBR_TCP_OPTIMIZATION.md)

---

## ⚡ Performance Optimizations

### Xray v26.2.2 Improvements

**Performance Enhancements:**
- ✅ Reduced memory usage at startup (#5581)
- ✅ Geodat optimization - Reduced peak memory
- ✅ VMess replay filter optimization (#5562)
- ✅ TUN inbound improvements - Fixed connection stalls (#5600)
- ✅ Hysteria transport improvements (#5603)
- ✅ XHTTP transport improvements - CDN bypass options (#5414)
- ✅ MPH domain matcher improvements - Cache usage (#5505)

**New Features:**
- 🆕 Finalmask - XICMP, XDNS, header-*, mkcp-*
- 🆕 iOS support - Improved TUN inbound (#5612)
- 🆕 Darwin improvements - Better macOS support (#5598)

**Full Documentation:** [XRAY_V26.2.2_FEATURES.md](XRAY_V26.2.2_FEATURES.md)

### Recommended Settings for High User Counts

1. **SplitHTTP Mode**: `Paket-up` (optimal for SplitHTTP)
2. **xPaddingBytes**: `0` (reduces RAM usage)
3. **scMaxConcurrentPosts**: `4` (reduces CPU usage)
4. **scMinPostsIntervalMs**: `50` (reduces CPU usage)
5. **BBR**: Enabled by default
6. **TCP Buffers**: Optimized for high bandwidth

---

## 🛠️ Management Tools

### Port Management

```bash
# Add new port
sudo bash scripts/manage_ports.sh add 8443

# Remove port
sudo bash scripts/manage_ports.sh remove 8080

# List configured ports
sudo bash scripts/manage_ports.sh list
```

### Configuration Backup

```bash
# Create backup
sudo bash scripts/backup_config.sh create

# List backups
sudo bash scripts/backup_config.sh list

# Restore from backup
sudo bash scripts/backup_config.sh restore backup_20231201_120000

# Clean old backups
sudo bash scripts/backup_config.sh clean
```

### Status Monitoring

```bash
# Detailed status report
sudo bash scripts/status.sh status

# Quick status check
sudo bash scripts/status.sh quick

# Check specific components
sudo bash scripts/status.sh services
sudo bash scripts/status.sh ports
sudo bash scripts/status.sh configs
sudo bash scripts/status.sh logs
sudo bash scripts/status.sh resources
sudo bash scripts/status.sh connectivity
```

### Troubleshooting Tools

```bash
# Comprehensive troubleshooting
sudo bash scripts/troubleshoot.sh

# Quick fix for common issues
sudo bash scripts/quick_fix.sh

# Resolve Xray conflicts
sudo bash scripts/resolve_xray_conflict.sh

# Validate and fix configuration
sudo bash scripts/validate_and_fix_config.sh

# Fix B->C connection keys
sudo bash scripts/fix_b_to_c_keys.sh
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Service Won't Start

```bash
# Check service status
systemctl status xray-a
systemctl status xray-b

# Check logs
journalctl -u xray-a -f
journalctl -u xray-b -f

# Verify configuration
xray -test -config /etc/xray/a.json
xray -test -config /etc/xray/b.json
```

#### 2. Connection Issues

**Check UUID Match:**
```bash
# Server A
jq '.outbounds[0].settings.vnext[0].users[0].id' /etc/xray/a.json

# Server B
jq '.inbounds[0].settings.clients[0].id' /etc/xray/b.json
```

**Check Transport Protocol Match:**
```bash
# Server A
jq '.outbounds[0].streamSettings.network' /etc/xray/a.json

# Server B
jq '.inbounds[0].streamSettings.network' /etc/xray/b.json
```

#### 3. Port Conflicts

```bash
# Check listening ports
ss -tlnp | grep -E ':(80|443|8080|8443|8081)\s'

# Check service conflicts
systemctl list-units | grep -E '(xray|nginx|apache)'
```

#### 4. Firewall Issues

```bash
# Check UFW status
sudo ufw status

# Check iptables rules
sudo iptables -L -n -v

# Allow required ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 8081/tcp
```

#### 5. Performance Issues

```bash
# Check BBR status
sysctl net.ipv4.tcp_congestion_control

# Check TCP buffers
sysctl net.core.rmem_max
sysctl net.core.wmem_max

# Apply optimizations manually
sudo bash scripts/apply_bbr_tcp_optimization.sh
```

### Log Analysis

```bash
# Xray access logs
tail -f /var/log/xray/access.log

# Xray error logs
tail -f /var/log/xray/error.log

# System logs
journalctl -u xray-a -f
journalctl -u xray-b -f

# System messages
dmesg | grep -i xray
```

---

## 📚 Documentation

### Main Documentation

- **[README.md](README.md)** - This file (English)
- **[README_FA.md](README_FA.md)** - Persian documentation
- **[XRAY_V26.2.2_FEATURES.md](XRAY_V26.2.2_FEATURES.md)** - v26.2.2 features and improvements
- **[BBR_TCP_OPTIMIZATION.md](BBR_TCP_OPTIMIZATION.md)** - BBR and TCP optimization guide
- **[CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md)** - Configuration examples
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Detailed project overview

### External Resources

- [Xray-core Documentation](https://xtls.github.io/)
- [Xray-core GitHub](https://github.com/XTLS/Xray-core)
- [Xray-core Releases](https://github.com/XTLS/Xray-core/releases)

---

## 🧪 Testing

### Health Checks

```bash
# Check listening ports
ss -tlnp | grep -E ':(80|443|8080|8443|8081)\s'

# Check service status
systemctl is-active xray-a xray-b

# Test connectivity
curl -I http://server-a-ip:80
curl -I http://server-a-ip:443
```

### End-to-End Testing

1. **Start test service on Server B:**
   ```bash
   sudo nc -l 127.0.0.1 8080
   ```

2. **Connect from client to Server A:**
   ```bash
   nc server-a-ip 8080
   ```

3. **Type messages** - They should appear in Server B's nc session.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style
- Add comments for complex logic
- Update documentation for new features
- Test your changes thoroughly
- Follow semantic versioning

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

This project is provided for **educational and legitimate use cases only**. Users are responsible for:

- Compliance with local laws and regulations
- Proper authorization for network usage
- Ethical use of the software

The authors and contributors are not responsible for any misuse of this software.

---

## 📞 Support

### Getting Help

- **GitHub Issues**: [Open an issue](https://github.com/letmefind/Easy-paqet/issues)
- **Documentation**: Check the [documentation](#-documentation) section
- **Troubleshooting**: Use the [troubleshooting tools](#-troubleshooting)

### Reporting Issues

When reporting issues, please include:

- Xray version (`xray version`)
- Operating system and version
- Installation method
- Error messages and logs
- Steps to reproduce

---

<div align="center">

**Made with ❤️ for communication freedom**

[⬆ Back to top](#-stealth-multiplex-tunnel-xray)

</div>
