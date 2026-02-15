# Stealth Multiplex Tunnel Xray

A production-ready, stealth tunnel solution supporting multiple protocols (VLESS/Trojan) and security options (TLS/Reality) with multi-port support and interactive configuration.

## 🚀 Features

- **Multi-Protocol Support**: VLESS and Trojan protocols
- **Multi-Security Options**: TLS and Reality security
- **Multi-Port Support**: Dynamic port management
- **Interactive Installation**: User-friendly setup process
- **Production Ready**: Comprehensive monitoring and management tools
- **Stealth Features**: Decoy sites, hidden tunnels, Chrome fingerprinting
- **Enhanced Reality**: Multiple short IDs, custom destinations
- **XHTTP Support**: Complete XHTTP configuration with socket settings

## 📋 Quick Start

```bash
# Clone the repository
git clone https://github.com/letmefind/Easy-paqet.git
cd Easy-paqet

# Run the unified installer
sudo bash install.sh
```

## 🏗️ Architecture

- **Server A (Entry)**: Accepts connections on multiple ports and forwards them through a stealth tunnel
- **Server B (Receiver)**: Receives tunneled traffic behind Nginx with TLS termination and decoy site

## 📁 Project Structure

```
Easy-paqet/
├── install.sh                    # Unified installer
├── README.md                     # Comprehensive documentation
├── .env.example                  # Configuration template
├── .gitignore                    # Git ignore rules
├── CONFIGURATION_EXAMPLES.md     # Configuration examples
├── PROJECT_SUMMARY.md            # Detailed project summary
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

## 🔧 Installation Process

1. **Install Server B (Receiver)** - Generates UUID and Reality keys
2. **Install Server A (Entry)** - Uses same configuration
3. **Test connectivity** - Verify end-to-end functionality

## 🛡️ Security Features

- Chrome TLS fingerprinting
- Reality protocol support
- Decoy website serving
- Hidden tunnel paths
- Certificate management
- Firewall integration
- UUID security

## 📊 Management Tools

- **Port Management**: Add/remove ports dynamically
- **Configuration Backup**: Automated backup/restore
- **Status Monitoring**: Comprehensive health checks
- **Log Analysis**: Structured logging and error tracking

## 📖 Documentation

- [README.md](README.md) - Complete installation guide
- [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) - Configuration examples
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview

## ⚠️ Disclaimer

This project is provided for educational and legitimate use cases only. Users are responsible for compliance with local laws and regulations.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions, please open an issue on GitHub.
