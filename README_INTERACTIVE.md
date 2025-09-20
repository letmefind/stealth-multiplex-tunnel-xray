# VLESS+REALITY Interactive Installation

This repository provides interactive installation scripts for setting up VLESS+REALITY tunnels between two servers.

## Quick Start

### 1. Install on Server A (Tunnel Server)

```bash
# Clone the repository
git clone https://github.com/letmefind/stealth-multiplex-tunnel-xray.git
cd stealth-multiplex-tunnel-xray

# Run interactive installation
bash install a
```

The script will ask you for:
- Server B IP address
- Tunnel port (default: 8081)
- Reality server name (SNI)

**Important:** Save the generated details for Server B installation:
- UUID
- Private Key
- Short ID
- Server Name
- Tunnel Port

### 2. Install on Server B (Destination Server)

```bash
# Clone the repository
git clone https://github.com/letmefind/stealth-multiplex-tunnel-xray.git
cd stealth-multiplex-tunnel-xray

# Run interactive installation
bash install b
```

The script will ask you for:
- UUID from Server A
- Private Key from Server A
- Short ID from Server A
- Server Name from Server A
- Tunnel Port from Server A
- Target port to tunnel (e.g., 8443 for XMPlus)
- Domain name for nginx

## Installation Options

### Auto-detect Server Type
```bash
bash install
```
The script will automatically detect whether you're on Server A or B.

### Manual Server Type Selection
```bash
bash install a          # Force Server A installation
bash install server-b   # Force Server B installation
bash install tunnel     # Force Server A installation
bash install dest       # Force Server B installation
```

### Individual Scripts
```bash
bash install_a.sh       # Server A only
bash install_b.sh       # Server B only
```

## Configuration Details

### Server A (Tunnel Server)
- **Role:** Receives traffic and forwards to Server B
- **Ports:** 80, 443, 8080, 8443 (dokodemo-door inbounds)
- **Protocol:** VLESS+REALITY with splithttp transport
- **Configuration:** `/etc/xray/a.json`
- **Service:** `xray-a.service`

### Server B (Destination Server)
- **Role:** Receives tunneled traffic and routes to local services
- **Ports:** Tunnel port (8081) for VLESS inbound
- **Protocol:** VLESS+REALITY with splithttp transport
- **Routing:** 
  - Ports 80,443 → nginx
  - Ports 8080,8443,8082,9090 → target service
- **Configuration:** `/etc/xray/b.json`
- **Service:** `xray-b.service`
- **Nginx:** Decoy website with SSL

## What Gets Installed

### Server A
- Xray core
- Systemd service (`xray-a.service`)
- Configuration file (`/etc/xray/a.json`)
- Log directory (`/var/log/xray/`)

### Server B
- Xray core
- Nginx web server
- Systemd services (`xray-b.service`)
- Configuration files:
  - `/etc/xray/b.json`
  - `/etc/nginx/conf.d/stealth-8081.conf`
- SSL certificates (self-signed decoy)
- Web root (`/var/www/html/`)

## Service Management

```bash
# Check status
systemctl status xray-a    # Server A
systemctl status xray-b    # Server B
systemctl status nginx     # Server B only

# Restart services
systemctl restart xray-a   # Server A
systemctl restart xray-b  # Server B
systemctl restart nginx    # Server B only

# View logs
tail -f /var/log/xray/access.log
tail -f /var/log/xray/error.log
```

## Configuration Files

### Server A (`/etc/xray/a.json`)
- dokodemo-door inbounds on ports 80, 443, 8080, 8443
- VLESS+REALITY outbound to Server B
- All traffic routed to Server B

### Server B (`/etc/xray/b.json`)
- VLESS+REALITY inbound on tunnel port
- Freedom outbounds to nginx and target service
- Port-based routing rules

### Nginx (`/etc/nginx/conf.d/stealth-8081.conf`)
- HTTP to HTTPS redirect
- Decoy website with SSL
- Security headers
- File serving

## Troubleshooting

### Check Service Status
```bash
systemctl status xray-a --no-pager
systemctl status xray-b --no-pager
systemctl status nginx --no-pager
```

### Check Logs
```bash
journalctl -u xray-a -f
journalctl -u xray-b -f
tail -f /var/log/xray/error.log
```

### Test Configuration
```bash
xray -test -config /etc/xray/a.json
xray -test -config /etc/xray/b.json
nginx -t
```

### Firewall Rules
Make sure these ports are open:
- **Server A:** 80, 443, 8080, 8443
- **Server B:** 80, 443, tunnel port (8081)

## Advanced Usage

### Custom Reality Keys
If you want to use custom Reality keys, you can modify the scripts or use the configuration generator:

```bash
bash install_config_generator --help
```

### Multiple Target Ports
The Server B configuration supports multiple target ports:
- 8080, 8443, 8082, 9090 are routed to the target service
- You can modify the routing rules in `/etc/xray/b.json`

## Security Notes

- Reality keys are automatically generated for security
- SSL certificates are self-signed for the decoy site
- All traffic is encrypted with VLESS+REALITY
- Nginx provides additional security headers
- Services run as non-root user (`nobody`)

## Support

For issues and questions:
1. Check the logs first
2. Verify firewall rules
3. Test configuration files
4. Check service status
5. Review this documentation
