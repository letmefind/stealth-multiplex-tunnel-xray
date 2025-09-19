# Stealth Multiplex Tunnel Xray - Project Summary

## Project Overview

This project provides a complete, production-ready stealth tunnel solution supporting multiple protocols (VLESS/Trojan) and security options (TLS/Reality) with multi-port support and interactive configuration.

## Key Features

### Protocol Support
- **VLESS**: Advanced protocol with SplitHTTP transport for enhanced stealth
- **Trojan**: Simple, efficient protocol with TCP transport

### Security Options
- **TLS**: Standard TLS encryption with valid certificates
- **Reality**: Enhanced stealth protocol that doesn't require real certificates

### Multi-Port Support
- Server A can listen on multiple ports simultaneously
- Dynamic port management (add/remove ports after installation)
- Port preservation (client port = destination port on Server B)

### Stealth Features
- Decoy website served by Nginx
- Tunnel hidden behind static-like paths
- Chrome TLS fingerprinting
- Reality protocol support for enhanced stealth

## Project Structure

```
stealth-multiplex-tunnel-xray/
├── README.md                    # Comprehensive documentation
├── .env.example                 # Configuration template
├── .gitignore                   # Git ignore rules
├── scripts/
│   ├── install_a.sh            # Server A installer
│   ├── install_b.sh            # Server B installer
│   ├── manage_ports.sh         # Port management utility
│   ├── backup_config.sh        # Configuration backup utility
│   └── status.sh               # Status monitoring utility
├── systemd/
│   ├── xray-a.service          # Server A systemd service
│   └── xray-b.service          # Server B systemd service
├── nginx/
│   └── stealth-8081.conf       # Nginx configuration template
└── xray/
    └── templates/
        ├── a.tmpl.json         # Server A Xray template
        └── b.tmpl.json         # Server B Xray template
```

## Installation Process

### 1. Server B (Receiver) Installation
```bash
sudo bash scripts/install_b.sh
```

**Interactive prompts:**
- Server domain name
- TLS port (default: 8081)
- Stealth path (default: /assets)
- Protocol choice (VLESS/Trojan)
- Security choice (TLS/Reality)
- Certificate configuration
- UUID (must match Server A)
- Proxy protocol support
- TCP BBR optimization
- Decoy site creation

### 2. Server A (Entry) Installation
```bash
sudo bash scripts/install_a.sh
```

**Interactive prompts:**
- Server B domain (must match Server B)
- Server B TLS port
- Stealth path (must match Server B)
- Protocol choice (must match Server B)
- Security choice (must match Server B)
- Client ports (comma-separated)
- UUID (must match Server B)
- Reality keys (if using Reality)
- TCP BBR optimization

## Configuration Management

### Port Management
```bash
# Add a new port
sudo bash scripts/manage_ports.sh add 8443

# Remove a port
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

# Restore backup
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

## Protocol & Security Combinations

### VLESS + TLS
- **Transport**: SplitHTTP
- **Security**: TLS with valid certificate
- **Features**: Chrome fingerprint, HTTP/1.1 ALPN
- **Use case**: Maximum stealth with real certificate

### VLESS + Reality
- **Transport**: SplitHTTP
- **Security**: Reality protocol
- **Features**: No real certificate needed, SNI-based
- **Use case**: Enhanced stealth without certificate management

### Trojan + TLS
- **Transport**: TCP
- **Security**: TLS with valid certificate
- **Features**: Simple configuration, standard TLS
- **Use case**: Simplicity with good security

### Trojan + Reality
- **Transport**: TCP
- **Security**: Reality protocol
- **Features**: Simple configuration, enhanced stealth
- **Use case**: Balance of simplicity and stealth

## Security Features

### Certificate Management
- **TLS Mode**: Requires valid SSL certificate
- **Reality Mode**: Uses SNI-based certificate generation
- **Certbot Integration**: Automatic certificate renewal
- **Certificate Validation**: Built-in validation checks

### Firewall Configuration
- **UFW Support**: Automatic firewall rule management
- **Manual Rules**: iptables examples provided
- **Port Management**: Dynamic port opening/closing

### Stealth Features
- **Decoy Site**: Legitimate-looking website
- **Hidden Tunnel**: Static-like path masking
- **TLS Fingerprinting**: Chrome-like fingerprint
- **Reality Support**: Enhanced stealth capabilities

## Testing & Verification

### Health Checks
```bash
# Check listening ports
ss -tlnp | grep -E ':(80|443|8080|8443)\s'

# Check service status
systemctl status xray-a xray-b nginx

# Check logs
journalctl -u xray-a -e
journalctl -u xray-b -e
```

### End-to-End Testing
```bash
# On Server B
sudo nc -l 127.0.0.1 8080

# From client
nc server-a-ip 8080
```

### Connectivity Tests
```bash
# Test decoy site
curl -I https://your-domain.com:8081/

# Test tunnel path
curl -I https://your-domain.com:8081/assets
```

## Performance Optimization

### TCP BBR
- Automatic BBR configuration
- Improved throughput and latency
- Configurable during installation

### Resource Limits
- Optimized systemd service limits
- Memory and file descriptor limits
- Process and connection limits

### Logging Configuration
- Configurable log levels
- Log rotation support
- Performance monitoring

## Troubleshooting

### Common Issues
1. **Certificate Errors**: Verify domain DNS and certificate validity
2. **Port Conflicts**: Check for existing services on ports
3. **Firewall Issues**: Verify firewall rules
4. **UUID Mismatch**: Ensure Server A and B use same UUID

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

## Advanced Configuration

### Custom Stealth Paths
- Change from default `/assets` to custom paths
- Configure during installation
- Update both servers with same path

### Multiple Domains
- Reality mode supports multiple SNI domains
- Enhanced stealth with domain rotation
- Configurable during installation

### Load Balancing
- Multiple Server B instances
- DNS round-robin for Server A
- Connection pooling optimization

## Security Considerations

### UUID Security
- Generate strong, unique UUIDs
- Rotate UUIDs periodically
- Never share UUIDs in logs

### Certificate Security
- Use valid certificates for TLS mode
- Regular certificate renewal
- Proper certificate storage

### Network Security
- Firewall configuration
- Port management
- Access control

## Support & Maintenance

### Regular Maintenance
- Monitor service status
- Check logs for errors
- Update configurations as needed
- Backup configurations regularly

### Monitoring
- Use status script for health checks
- Monitor system resources
- Track connection statistics
- Alert on service failures

## Compliance & Legal

### Usage Guidelines
- Educational and legitimate use only
- Compliance with local laws required
- Responsible disclosure of vulnerabilities
- No malicious use permitted

### Security Best Practices
- Regular security updates
- Strong authentication
- Network segmentation
- Access logging

## Conclusion

This project provides a comprehensive, production-ready stealth tunnel solution with:

- **Multi-protocol support** (VLESS/Trojan)
- **Multi-security options** (TLS/Reality)
- **Interactive installation** with validation
- **Dynamic port management**
- **Comprehensive monitoring**
- **Configuration backup/restore**
- **Security best practices**
- **Production-ready features**

The solution is designed for legitimate use cases requiring secure, stealthy communication channels with high availability and performance.
