# Stealth Multiplex Tunnel Xray

A production-ready, stealth tunnel solution supporting multiple protocols (VLESS/Trojan) and security options (TLS/Reality) with multi-port support and interactive configuration.

## Architecture Overview

This solution creates a stealth tunnel between two servers:

- **Server A (Entry)**: Accepts connections on multiple ports and forwards them through a stealth tunnel
- **Server B (Receiver)**: Receives tunneled traffic behind Nginx with TLS termination and decoy site

### Supported Protocols & Security

- **Protocols**: VLESS, Trojan
- **Security**: TLS, Reality
- **Transport**: SplitHTTP (for VLESS), TCP (for Trojan)

## Quick Start

### Unified Installation (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd stealth-multiplex-tunnel-xray

# Run the unified installer
sudo bash install.sh
```

The unified installer will:
- Ask which server you're installing (A or B)
- Provide detailed information about each server type
- Run the appropriate installation script
- Show post-installation guidance

### Direct Installation

If you prefer to run installers directly:

### 1. Install Server B (Receiver)

```bash
# Run the interactive installer
sudo bash scripts/install_b.sh
```

The installer will prompt you for:
- Server domain name
- TLS port (default: 8081)
- Stealth path (default: /assets)
- Protocol choice (VLESS or Trojan)
- Security choice (TLS or Reality)
- Certificate mode (use existing or Certbot)
- UUID (auto-generated if not provided)
- Proxy protocol support
- TCP BBR optimization
- Decoy site creation

### 2. Install Server A (Entry)

```bash
# Run the interactive installer
sudo bash scripts/install_a.sh
```

The installer will prompt you for:
- Server B domain (must match Server B configuration)
- Server B TLS port
- Stealth path (must match Server B)
- Protocol choice (must match Server B)
- Security choice (must match Server B)
- Allowed client ports (comma-separated, e.g., 80,443,8080,8443)
- UUID (must match Server B)
- TCP BBR optimization

### 3. Manage Ports (Optional)

Add or remove ports on Server A after installation:

```bash
# Add a new port
sudo bash scripts/manage_ports.sh add 8443

# Remove a port
sudo bash scripts/manage_ports.sh remove 8080

# List current ports
sudo bash scripts/manage_ports.sh list
```

## Configuration Details

### Protocol & Security Combinations

#### VLESS + TLS
- Uses SplitHTTP transport for better stealth
- Chrome TLS fingerprint
- HTTP/1.1 ALPN
- Valid TLS certificate required

#### VLESS + Reality
- Uses SplitHTTP transport
- Reality protocol for enhanced stealth
- No real certificate needed (uses SNI)
- Better resistance to deep packet inspection

#### Trojan + TLS
- Uses TCP transport
- Standard TLS encryption
- Valid TLS certificate required
- Simpler configuration

#### Trojan + Reality
- Uses TCP transport
- Reality protocol for enhanced stealth
- No real certificate needed
- Good balance of simplicity and stealth

### Port Configuration

Server A can listen on multiple ports simultaneously. Each port creates a separate dokodemo-door inbound that preserves the original port number when forwarding to Server B.

Example: If a client connects to Server A on port 8080, the traffic will be forwarded to Server B and delivered to `127.0.0.1:8080` on Server B.

### Stealth Features

- **Decoy Site**: Nginx serves a legitimate-looking website on the root path
- **Hidden Tunnel**: Actual tunnel traffic is hidden behind a static-like path (default: /assets)
- **TLS Fingerprinting**: Chrome-like TLS fingerprint to avoid detection
- **Reality Support**: Enhanced stealth with Reality protocol
- **Proxy Protocol**: Optional client IP preservation

## File Structure

```
stealth-multiplex-tunnel-xray/
├── README.md
├── .env.example
├── scripts/
│   ├── install_a.sh          # Server A installer
│   ├── install_b.sh          # Server B installer
│   └── manage_ports.sh       # Port management
├── systemd/
│   ├── xray-a.service        # Server A systemd service
│   └── xray-b.service        # Server B systemd service
├── nginx/
│   └── stealth-8081.conf     # Nginx configuration template
└── xray/
    └── templates/
        ├── a.tmpl.json       # Server A Xray template
        └── b.tmpl.json       # Server B Xray template
```

## Testing & Verification

### Server B Health Checks

```bash
# Check if decoy site is accessible
curl -I https://your-domain.com:8081/

# Check if tunnel path responds (should not expose obvious tunnel)
curl -I https://your-domain.com:8081/assets

# Check Xray service status
systemctl status xray-b

# Check logs
journalctl -u xray-b -e
```

### Server A Health Checks

```bash
# Check if ports are listening
ss -tlnp | grep -E ':(80|443|8080|8443)\s'

# Check Xray service status
systemctl status xray-a

# Check logs
journalctl -u xray-a -e
```

### End-to-End Test

1. Start a test service on Server B:
   ```bash
   # On Server B
   sudo nc -l 127.0.0.1 8080
   ```

2. Connect from a client to Server A:
   ```bash
   # From client
   nc server-a-ip 8080
   ```

3. Type messages in the client - they should appear on Server B's nc session.

## Security Considerations

### Certificate Management

- **TLS Mode**: Requires valid SSL certificate for the domain
- **Reality Mode**: Uses SNI-based certificate generation, no real cert needed
- **Certbot Integration**: Automatic certificate renewal support

### Firewall Configuration

The installers will attempt to configure UFW firewall rules. For other firewalls, manual configuration may be required:

```bash
# Example iptables rules for Server A
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT

# Example iptables rules for Server B
iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
```

### UUID Security

- Generate strong, unique UUIDs for each installation
- Rotate UUIDs periodically for enhanced security
- Never share UUIDs in logs or documentation

## Troubleshooting

### Common Issues

1. **Certificate Errors**: Ensure domain DNS points to Server B and certificate is valid
2. **Port Conflicts**: Check if ports are already in use with `ss -tlnp`
3. **Firewall Issues**: Verify firewall rules allow traffic on required ports
4. **UUID Mismatch**: Ensure Server A and B use the same UUID

### Log Analysis

```bash
# Xray logs
journalctl -u xray-a -f
journalctl -u xray-b -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
dmesg | grep -i xray
```

### Performance Optimization

- Enable TCP BBR for better performance
- Adjust Xray buffer sizes for high-traffic scenarios
- Monitor system resources and adjust limits as needed

## Advanced Configuration

### Custom Stealth Paths

Change the stealth path from default `/assets` to something more convincing:

```bash
# During installation, specify custom path
STEALTH_PATH="/api/v1/health"
```

### Multiple Domains

For Reality mode, you can use multiple SNI domains:

```bash
# Specify multiple domains for better stealth
SNI_DOMAINS="cloudflare.com,github.com,google.com"
```

### Load Balancing

For high-traffic scenarios, consider:
- Multiple Server B instances behind a load balancer
- DNS round-robin for Server A
- Connection pooling optimization

## Support

For issues and questions:
1. Check the logs first
2. Verify configuration matches between servers
3. Test with simple tools (nc, curl) before complex applications
4. Ensure all dependencies are installed correctly

## License

This project is provided as-is for educational and legitimate use cases only. Users are responsible for compliance with local laws and regulations.
