#!/bin/bash

# SSL Certificate Generation Script for Ergo Mining Pool
# Supports both Let's Encrypt and self-signed certificates

set -e

# Default values
DOMAIN_NAME=${DOMAIN_NAME:-"your-domain.com"}
EMAIL=${LETSENCRYPT_EMAIL:-"admin@your-domain.com"}
SSL_DIR="./ssl"
USE_LETSENCRYPT=${USE_LETSENCRYPT:-true}
PFX_PASSWORD=${PFX_PASSWORD:-"your-pfx-password"}

echo "=================================================="
echo "SSL Certificate Generation for Ergo Mining Pool"
echo "=================================================="
echo "Domain: $DOMAIN_NAME"
echo "Email: $EMAIL"
echo "SSL Directory: $SSL_DIR"
echo "Use Let's Encrypt: $USE_LETSENCRYPT"
echo "=================================================="

# Create SSL directory structure
mkdir -p "$SSL_DIR"/{live,archive,renewal}
mkdir -p "$SSL_DIR/live/$DOMAIN_NAME"

if [ "$USE_LETSENCRYPT" = "true" ]; then
    echo "Generating Let's Encrypt certificates..."
    
    # Check if certbot is available
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y certbot
        elif command -v yum &> /dev/null; then
            yum install -y certbot
        else
            echo "Please install certbot manually"
            exit 1
        fi
    fi
    
    # Generate certificates using DNS challenge (safest for automation)
    echo "Generating Let's Encrypt certificates using DNS challenge..."
    echo "Note: You'll need to manually add DNS TXT records as prompted"
    
    certbot certonly \
        --manual \
        --preferred-challenges=dns \
        --email "$EMAIL" \
        --server https://acme-v02.api.letsencrypt.org/directory \
        --agree-tos \
        --manual-public-ip-logging-ok \
        -d "$DOMAIN_NAME" \
        --config-dir "$SSL_DIR" \
        --work-dir "$SSL_DIR" \
        --logs-dir "$SSL_DIR"
        
else
    echo "Generating self-signed certificates..."
    
    # Generate private key
    openssl genpkey -algorithm RSA -out "$SSL_DIR/live/$DOMAIN_NAME/privkey.pem" -pkcs8 -pkcs8opt no_encrypt -bits 2048
    
    # Generate certificate signing request
    openssl req -new \
        -key "$SSL_DIR/live/$DOMAIN_NAME/privkey.pem" \
        -out "$SSL_DIR/live/$DOMAIN_NAME/cert.csr" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$DOMAIN_NAME"
    
    # Generate self-signed certificate
    openssl x509 -req \
        -days 365 \
        -in "$SSL_DIR/live/$DOMAIN_NAME/cert.csr" \
        -signkey "$SSL_DIR/live/$DOMAIN_NAME/privkey.pem" \
        -out "$SSL_DIR/live/$DOMAIN_NAME/cert.pem"
    
    # Create full chain (same as cert for self-signed)
    cp "$SSL_DIR/live/$DOMAIN_NAME/cert.pem" "$SSL_DIR/live/$DOMAIN_NAME/fullchain.pem"
    
    # Clean up CSR
    rm "$SSL_DIR/live/$DOMAIN_NAME/cert.csr"
fi

echo "Converting certificates to PFX format for .NET..."

# Convert to PFX format for .NET applications
openssl pkcs12 -export \
    -out "$SSL_DIR/live/$DOMAIN_NAME/cert.pfx" \
    -inkey "$SSL_DIR/live/$DOMAIN_NAME/privkey.pem" \
    -in "$SSL_DIR/live/$DOMAIN_NAME/fullchain.pem" \
    -passout pass:"$PFX_PASSWORD"

echo "Setting appropriate file permissions..."
chmod 600 "$SSL_DIR/live/$DOMAIN_NAME"/*.pem
chmod 600 "$SSL_DIR/live/$DOMAIN_NAME"/*.pfx

echo "=================================================="
echo "SSL certificates generated successfully!"
echo "=================================================="
echo "Certificate files:"
echo "  Private key: $SSL_DIR/live/$DOMAIN_NAME/privkey.pem"
echo "  Certificate: $SSL_DIR/live/$DOMAIN_NAME/cert.pem"
echo "  Full chain:  $SSL_DIR/live/$DOMAIN_NAME/fullchain.pem"
echo "  PFX file:    $SSL_DIR/live/$DOMAIN_NAME/cert.pfx"
echo "=================================================="

if [ "$USE_LETSENCRYPT" = "true" ]; then
    echo "Note: Remember to renew Let's Encrypt certificates every 90 days"
    echo "Use the renew-certs.sh script for automatic renewal"
else
    echo "Note: Self-signed certificates are valid for 365 days"
    echo "For production use, consider using Let's Encrypt certificates"
fi

echo "==================================================" 