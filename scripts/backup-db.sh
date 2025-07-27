#!/bin/bash

# PostgreSQL Backup Script for Ergo Mining Pool
# CRITICAL: This protects miners' balances and share data

set -e

# Configuration
BACKUP_DIR="./backups"
POSTGRES_CONTAINER="ergo-miningcore-postgres"
POSTGRES_DB=${POSTGRES_DB:-"miningcore"}
POSTGRES_USER=${POSTGRES_USER:-"miningcore"}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/miningcore_backup_$TIMESTAMP.sql"

echo "=================================================="
echo "🔒 PostgreSQL Backup for Ergo Mining Pool"
echo "=================================================="
echo "Database: $POSTGRES_DB"
echo "Container: $POSTGRES_CONTAINER"
echo "Backup file: $BACKUP_FILE"
echo "Retention: $RETENTION_DAYS days"
echo "=================================================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if PostgreSQL container is running
if ! docker ps | grep -q "$POSTGRES_CONTAINER"; then
    echo "❌ Error: PostgreSQL container '$POSTGRES_CONTAINER' is not running"
    exit 1
fi

# Create backup
echo "📦 Creating database backup..."
docker exec "$POSTGRES_CONTAINER" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --verbose > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    # Compress backup
    echo "🗜️ Compressing backup..."
    gzip "$BACKUP_FILE"
    BACKUP_FILE="$BACKUP_FILE.gz"
    
    # Calculate backup size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ Backup completed successfully!"
    echo "📁 File: $BACKUP_FILE"
    echo "📊 Size: $BACKUP_SIZE"
    
    # Verify backup integrity
    echo "🔍 Verifying backup integrity..."
    if gunzip -t "$BACKUP_FILE"; then
        echo "✅ Backup integrity verified"
    else
        echo "❌ Backup integrity check failed!"
        exit 1
    fi
else
    echo "❌ Backup failed!"
    rm -f "$BACKUP_FILE" 2>/dev/null
    exit 1
fi

# Clean up old backups (retention policy)
echo "🧹 Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "miningcore_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

# Show remaining backups
echo "📋 Available backups:"
ls -lh "$BACKUP_DIR"/miningcore_backup_*.sql.gz 2>/dev/null || echo "No backup files found"

echo "=================================================="
echo "✅ Backup process completed successfully!"
echo "=================================================="

# Optional: Upload to remote storage (uncomment and configure as needed)
# echo "☁️ Uploading to remote storage..."
# aws s3 cp "$BACKUP_FILE" s3://your-backup-bucket/miningcore/ || echo "Remote backup failed"
# rsync -avz "$BACKUP_FILE" user@backup-server:/path/to/backups/ || echo "Remote backup failed" 