# VLESS+REALITY Configuration Generator

This script generates VLESS+REALITY tunnel configurations based on your working example.

## Usage

```bash
./generate_reality_config.sh
```

The script will prompt you for:
- Server B IP address (destination server)
- Tunnel port (VLESS connection port, default: 8081)
- Target port to tunnel (e.g., 8443 for XMPlus)
- Reality server name (SNI)
- Domain name for nginx

## Generated Files

The script creates a timestamped directory with:
- `server_a.json` - Configuration for Server A (tunnel server)
- `server_b.json` - Configuration for Server B (destination server)
- `nginx_stealth.conf` - Nginx configuration for Server B
- `install.sh` - Installation script for both servers

## Installation

1. Copy Server A config to your tunnel server: `/etc/xray/a.json`
2. Copy Server B config to your destination server: `/etc/xray/b.json`
3. Copy Nginx config to your destination server: `/etc/nginx/conf.d/stealth-8081.conf`
4. Run the installation script on both servers
5. Restart services: `systemctl restart xray nginx`

## Key Features

- Uses VLESS+REALITY with splithttp transport
- Automatically generates Reality keys
- Supports any target port (except 80,443)
- Includes proper routing for HTTP/HTTPS and target services
- Simple nginx decoy configuration

## Example Configuration

The generated configs match your working example:
- Server A: dokodemo-door inbounds → VLESS+REALITY outbound
- Server B: VLESS+REALITY inbound → freedom outbounds to nginx/target
- Nginx: Simple decoy site with SSL redirect
