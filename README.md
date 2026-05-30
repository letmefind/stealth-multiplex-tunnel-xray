# Stealth Multiplex Tunnel (Xray)

Interactive installer for a **VLESS** tunnel built on [Xray-core](https://github.com/XTLS/Xray-core). It configures multi-port forwarding on **Server A** (entry) and a matching inbound on **Server B** (destination), with optional **Server M** relay for **A → M → B** topology.

## Quick start

On each server (as root):

```bash
curl -fsSL https://raw.githubusercontent.com/letmefind/stealth-multiplex-tunnel-xray/main/server.sh -o server.sh
chmod +x server.sh
sudo bash server.sh
```

`server.sh` downloads the latest `install` from GitHub and runs it (avoids broken local copies).

Or clone and run:

```bash
sudo bash install
```

Non-interactive examples:

```bash
sudo bash install xray b              # Server B, direct topology
sudo bash install xray middle b      # Server B for A→M→B
sudo bash install xray m              # Server M (middle relay)
sudo bash install xray a              # Server A
sudo bash install --help
```

## Topology

| Mode | Path | Install order |
|------|------|----------------|
| **Direct** (default) | A → B | B, then A |
| **Middle relay** | A → M → B | B → M → A |

Use the same transport and protocol settings on every hop. Server M only relays; it does not terminate user traffic like B.

## Transports

During install on A and B, choose one protocol (must match on both sides):

| # | Transport | Notes |
|---|-----------|--------|
| 1 | XHTTP (SplitHTTP) + Reality | Recommended for stealth |
| 2 | XHTTP (SplitHTTP) | Plain HTTP transport, CDN-friendly |
| 3 | TCP (raw) | Simple TCP |
| 4 | TCP + Reality | TCP with Reality |
| 5 | WebSocket | Needs domain/path as prompted |
| 6 | gRPC | Needs service name |
| 7 | KCP (mKCP) | UDP; defaults: MTU 1350, TTI 20 ms, uplink/downlink 500, congestion on, 32 MB buffers, tunnel port 2053 |

Reality keys, UUID, ports, and forward port lists are generated or prompted during setup.

## What gets installed

- **Xray-core** from official release (architecture auto-detected)
- **systemd** units: `xray-a`, `xray-b`, and optionally `xray-m`
- Config under `/etc/xray/` (`a.json`, `b.json`, `m.json`)
- Logs under `/var/log/xray/`
- Optional **BBR** / TCP tuning when selected in the wizard
- **ufw** rules for chosen ports when ufw is present

Reference unit files are in `systemd/` for review; the installer writes live units under `/etc/systemd/system/`.

## Repository layout

```
├── install              # Main installer (all logic)
├── server.sh            # Launcher: fetch install from GitHub
├── systemd/             # Reference unit files (a, b, m)
└── scripts/
    ├── apply_bbr_tcp_optimization.sh
    ├── find_optimal_mtu.sh
    ├── manage_ports.sh          # Add/list ports on Server A
    ├── status.sh                # Service and config health
    ├── troubleshoot.sh          # Common Xray issues
    └── validate_and_fix_config.sh
```

## Helper scripts (on the server)

Copy or run from a cloned repo (root required):

```bash
sudo bash scripts/status.sh quick
sudo bash scripts/troubleshoot.sh
sudo bash scripts/manage_ports.sh list
sudo bash scripts/apply_bbr_tcp_optimization.sh
```

## Requirements

- Linux with **systemd**
- **root** for install and service management
- **bash**, **curl**, **jq** (installer installs missing tools where possible)
- Open firewall ports you select during setup
- For XHTTP/Reality with a domain: DNS pointing to the correct server

## Troubleshooting

1. Re-run via `server.sh` to ensure a fresh `install` from GitHub.
2. `sudo systemctl status xray-a` (or `xray-b` / `xray-m`)
3. `sudo journalctl -u xray-a -n 50 --no-pager`
4. `sudo bash scripts/troubleshoot.sh`
5. `sudo xray run -test -config /etc/xray/a.json`

If you see garbled terminal output (`$'\E[?12'`, `\EP1+r...`), the local `install` file is corrupted — use `server.sh` or re-download from GitHub.

## License

MIT — see [LICENSE](LICENSE).

## Persian documentation

See [README_FA.md](README_FA.md).
