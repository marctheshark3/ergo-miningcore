#!/bin/bash

# PostgreSQL Restore Script for Ergo Mining Pool
# CRITICAL: This restores miners' balances and share data from backups

set -e

# Configuration
BACKUP_DIR="./backups"
POSTGRES_CONTAINER="ergo-miningcore-postgres"
POSTGRES_DB=${POSTGRES_DB:-"miningcore"}
POSTGRES_USER=${POSTGRES_USER:-"miningcore"}

echo "=================================================="
echo "🔄 PostgreSQL Restore for Ergo Mining Pool"
echo "=================================================="

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo "📋 Available backup files:"
    ls -lht "$BACKUP_DIR"/miningcore_backup_*.sql.gz 2>/dev/null | head -10 || echo "No backup files found"
    echo ""
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 ./backups/miningcore_backup_20231215_143022.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file '$BACKUP_FILE' not found"
    exit 1
fi

echo "📁 Backup file: $BACKUP_FILE"
echo "📊 File size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "🗃️ Database: $POSTGRES_DB"
echo "📦 Container: $POSTGRES_CONTAINER"

# Confirm before proceeding
echo ""
echo "⚠️ WARNING: This will COMPLETELY REPLACE the existing database!"
echo "⚠️ All current data will be LOST and replaced with backup data!"
echo ""
read -p "Are you sure you want to continue? (Type 'YES' to proceed): " confirm

if [ "$confirm" != "YES" ]; then
    echo "❌ Restore cancelled by user"
    exit 1
fi

# Check if PostgreSQL container is running
if ! docker ps | grep -q "$POSTGRES_CONTAINER"; then
    echo "❌ Error: PostgreSQL container '$POSTGRES_CONTAINER' is not running"
    echo "💡 Start the container with: docker-compose up -d postgres"
    exit 1
fi

# Verify backup integrity
echo "🔍 Verifying backup integrity..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    if ! gunzip -t "$BACKUP_FILE"; then
        echo "❌ Backup file is corrupted!"
        exit 1
    fi
    echo "✅ Backup integrity verified"
else
    echo "✅ Uncompressed backup file detected"
fi

# Stop miningcore services to prevent data conflicts
echo "⏸️ Stopping miningcore services..."
docker-compose stop miningcore-1 miningcore-2 nginx 2>/dev/null || true

# Create a backup of current database before restore
echo "📦 Creating safety backup of current database..."
SAFETY_BACKUP="$BACKUP_DIR/pre_restore_backup_$(date +"%Y%m%d_%H%M%S").sql"
docker exec "$POSTGRES_CONTAINER" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$SAFETY_BACKUP"
gzip "$SAFETY_BACKUP"
echo "💾 Safety backup saved: $SAFETY_BACKUP.gz"

# Drop and recreate database
echo "🗑️ Dropping existing database..."
docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"
echo "🆕 Creating fresh database..."
docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"

# Restore from backup
echo "📥 Restoring database from backup..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    # Compressed backup
    gunzip -c "$BACKUP_FILE" | docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
else
    # Uncompressed backup
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$BACKUP_FILE"
fi

if [ $? -eq 0 ]; then
    echo "✅ Database restore completed successfully!"
    
    # Verify the restore
    echo "🔍 Verifying restore..."
    RESTORED_TABLES=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    echo "📊 Restored tables: $(echo $RESTORED_TABLES | tr -d ' ')"
    
    if [ "$(echo $RESTORED_TABLES | tr -d ' ')" -gt "0" ]; then
        echo "✅ Restore verification successful!"
    else
        echo "⚠️ Warning: No tables found in restored database"
    fi
else
    echo "❌ Database restore failed!"
    
    # Attempt to restore from safety backup
    echo "🆘 Attempting to restore from safety backup..."
    gunzip -c "$SAFETY_BACKUP.gz" | docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully restored from safety backup"
    else
        echo "❌ Critical error: Both restore and safety restore failed!"
        echo "💔 Manual intervention required!"
        exit 1
    fi
fi

# Restart services
echo "🚀 Restarting miningcore services..."
docker-compose up -d

echo "=================================================="
echo "✅ Restore process completed!"
echo "💡 Monitor the logs: docker-compose logs -f miningcore-1"
echo "🌐 Check the API: curl http://localhost:4000/api/pools"
echo "==================================================" 