package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"

	"golang.org/x/crypto/curve25519"
)

func main() {
	var privateKey []byte
	var publicKey []byte
	var err error

	// Generate 32 random bytes for private key
	privateKey = make([]byte, curve25519.ScalarSize)
	if _, err = rand.Read(privateKey); err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	// Apply curve25519 bit manipulation
	privateKey[0] &= 248
	privateKey[31] &= 127
	privateKey[31] |= 64

	// Generate public key using curve25519.X25519
	if publicKey, err = curve25519.X25519(privateKey, curve25519.Basepoint); err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	// Output in RawURLEncoding format (no padding)
	fmt.Printf("Private key: %s\n", base64.RawURLEncoding.EncodeToString(privateKey))
	fmt.Printf("Public key: %s\n", base64.RawURLEncoding.EncodeToString(publicKey))
}
