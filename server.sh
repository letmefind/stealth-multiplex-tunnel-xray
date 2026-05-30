#!/bin/bash
# Installer launcher: downloads a clean copy from GitHub (avoids corrupted local files)
if [ -z "$BASH_VERSION" ]; then
    echo "Error: Run with bash: bash $0" >&2
    exit 1
fi

INSTALL_URL="https://raw.githubusercontent.com/letmefind/stealth-multiplex-tunnel-xray/main/install"
INSTALL_SCRIPT="$(mktemp /tmp/xray-install.XXXXXX.sh)"
trap 'rm -f "$INSTALL_SCRIPT"' EXIT

if ! curl -fsSL "$INSTALL_URL" -o "$INSTALL_SCRIPT"; then
    echo "Error: Could not download installer from GitHub." >&2
    echo "Try: curl -fsSL $INSTALL_URL -o install && sudo bash install" >&2
    exit 1
fi

if ! bash -n "$INSTALL_SCRIPT" 2>/dev/null; then
    echo "Error: Downloaded installer failed syntax check." >&2
    exit 1
fi

exec bash "$INSTALL_SCRIPT" "$@"
