#!/bin/bash

# Debug X25519 key generation
echo "Debugging X25519 key generation..."

# Create temporary files for key generation
temp_priv=$(mktemp)

# Generate X25519 private key (32 bytes)
openssl genpkey -algorithm X25519 -out "$temp_priv" 2>/dev/null

echo "DER private key (hex):"
openssl pkey -in "$temp_priv" -outform DER 2>/dev/null | xxd

echo "DER private key (base64):"
openssl pkey -in "$temp_priv" -outform DER 2>/dev/null | base64

echo "Raw private key (last 32 bytes, hex):"
openssl pkey -in "$temp_priv" -outform DER 2>/dev/null | tail -c +13 | xxd

echo "Raw private key (last 32 bytes, base64):"
openssl pkey -in "$temp_priv" -outform DER 2>/dev/null | tail -c +13 | base64

# Clean up
rm -f "$temp_priv"
