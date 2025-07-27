#!/bin/bash

# SSL Certificate Renewal Script for Ergo Mining Pool
# Automatically renews Let's Encrypt certificates and restarts containers

set -e

# Configuration
SSL_DIR="./ssl"
DOMAIN_NAME=${DOMAIN_NAME:-"your-domain.com"}
PFX_PASSWORD=${PFX_PASSWORD:-"your-pfx-password"}
DOCKER_COMPOSE_FILE="docker-compose.yml"

echo "=================================================="
echo "SSL Certificate Renewal for Ergo Mining Pool"
echo "=================================================="
echo "Domain: $DOMAIN_NAME"
echo "SSL Directory: $SSL_DIR"
echo "=================================================="

# Check if certificates exist
if [ ! -f "$SSL_DIR/live/$DOMAIN_NAME/cert.pem" ]; then
    echo "Error: No existing certificates found for $DOMAIN_NAME"
    echo "Please run generate-ssl.sh first"
    exit 1
fi

# Check certificate expiration
echo "Checking certificate expiration..."
EXPIRE_DATE=$(openssl x509 -enddate -noout -in "$SSL_DIR/live/$DOMAIN_NAME/cert.pem" | cut -d= -f2)
EXPIRE_TIMESTAMP=$(date -d "$EXPIRE_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRE_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))

echo "Certificate expires in $DAYS_UNTIL_EXPIRY days"

# Only renew if certificate expires in less than 30 days
if [ $DAYS_UNTIL_EXPIRY -gt 30 ]; then
    echo "Certificate is still valid for more than 30 days. No renewal needed."
    exit 0
fi

echo "Certificate expires soon. Starting renewal process..."

# Attempt to renew certificates
echo "Renewing Let's Encrypt certificates..."
if certbot renew \
    --config-dir "$SSL_DIR" \
    --work-dir "$SSL_DIR" \
    --logs-dir "$SSL_DIR" \
    --quiet; then
    
    echo "Certificate renewal successful!"
    
    # Convert renewed certificate to PFX format
    echo "Converting renewed certificate to PFX format..."
    openssl pkcs12 -export \
        -out "$SSL_DIR/live/$DOMAIN_NAME/cert.pfx" \
        -inkey "$SSL_DIR/live/$DOMAIN_NAME/privkey.pem" \
        -in "$SSL_DIR/live/$DOMAIN_NAME/fullchain.pem" \
        -passout pass:"$PFX_PASSWORD"
    
    # Set appropriate permissions
    chmod 600 "$SSL_DIR/live/$DOMAIN_NAME"/*.pem
    chmod 600 "$SSL_DIR/live/$DOMAIN_NAME"/*.pfx
    
    echo "Certificate files updated successfully!"
    
    # Restart containers to reload certificates
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        echo "Restarting containers to reload certificates..."
        docker-compose restart miningcore nginx
        echo "Containers restarted successfully!"
    else
        echo "Warning: docker-compose.yml not found. Please restart services manually."
    fi
    
    # Log successful renewal
    echo "$(date): Certificate renewed successfully for $DOMAIN_NAME" >> "$SSL_DIR/renewal.log"
    
else
    echo "Certificate renewal failed!"
    echo "$(date): Certificate renewal failed for $DOMAIN_NAME" >> "$SSL_DIR/renewal.log"
    exit 1
fi

echo "=================================================="
echo "Certificate renewal completed successfully!"
echo "==================================================" 