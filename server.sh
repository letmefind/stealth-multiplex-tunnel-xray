#!/bin/bash
# Wrapper for the main installer (same as install)
# Use: sudo bash server.sh
if [ -z "$BASH_VERSION" ]; then
    echo "Error: Run with bash: bash $0" >&2
    exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/install" "$@"
