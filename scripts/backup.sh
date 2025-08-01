#!/bin/bash

# =================================================================
# QUEUE MANAGEMENT SYSTEM - BACKUP SCRIPT
# =================================================================

set -e

echo "💾 Starting backup process..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="queue_app_backup_$TIMESTAMP"
POSTGRES_HOST=${POSTGRES_HOST:-db}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-queue_app}

# Create backup directory
create_backup_dir() {
    print_status "Creating backup directory: $BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
}

# Wait for database
wait_for_database() {
    print_status "Waiting for database connection..."
    
    local max_attempts=30
    local attempt=0
    
    while ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            print_error "Database not available after $max_attempts attempts"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    
    print_success "Database is ready"
}

# Create database backup
backup_database() {
    print_status "Creating database backup..."
    
    local backup_file="$BACKUP_DIR/$BACKUP_NAME/database.sql"
    
    pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
            --verbose --clean --no-owner --no-acl \
            --format=custom \
            "$POSTGRES_DB" > "$backup_file.custom" || {
        print_error "Database backup failed!"
        exit 1
    }
    
    # Also create a plain SQL backup
    pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
            --verbose --clean --no-owner --no-acl \
            "$POSTGRES_DB" > "$backup_file" || {
        print_warning "Plain SQL backup failed, but custom format succeeded"
    }
    
    # Get database size info
    local db_size=$(psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
                         -d "$POSTGRES_DB" -t -c "SELECT pg_size_pretty(pg_database_size('$POSTGRES_DB'));" | xargs)
    
    print_success "Database backup completed (Size: $db_size)"
}

# Create schema-only backup
backup_schema() {
    print_status "Creating schema-only backup..."
    
    local schema_file="$BACKUP_DIR/$BACKUP_NAME/schema.sql"
    
    pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
            --schema-only --verbose --clean --no-owner --no-acl \
            "$POSTGRES_DB" > "$schema_file" || {
        print_warning "Schema backup failed"
        return 1
    }
    
    print_success "Schema backup completed"
}

# Backup specific tables
backup_critical_tables() {
    print_status "Creating backup of critical tables..."
    
    local tables=("users" "points" "cashiers" "orders" "order_statuses")
    
    for table in "${tables[@]}"; do
        local table_file="$BACKUP_DIR/$BACKUP_NAME/table_$table.sql"
        
        pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
                --table="$table" --data-only --verbose \
                "$POSTGRES_DB" > "$table_file" 2>/dev/null || {
            print_warning "Backup of table '$table' failed"
        }
    done
    
    print_success "Critical tables backup completed"
}

# Create metadata file
create_metadata() {
    print_status "Creating backup metadata..."
    
    local metadata_file="$BACKUP_DIR/$BACKUP_NAME/metadata.json"
    
    cat > "$metadata_file" << EOF
{
    "backup_name": "$BACKUP_NAME",
    "timestamp": "$TIMESTAMP",
    "database": "$POSTGRES_DB",
    "host": "$POSTGRES_HOST",
    "port": "$POSTGRES_PORT",
    "user": "$POSTGRES_USER",
    "environment": "${ENVIRONMENT:-unknown}",
    "backup_type": "full",
    "files": [
        "database.sql",
        "database.sql.custom",
        "schema.sql"
    ],
    "created_at": "$(date -Iseconds)",
    "version": "1.0"
}
EOF
    
    print_success "Metadata file created"
}

# Compress backup
compress_backup() {
    print_status "Compressing backup..."
    
    cd "$BACKUP_DIR"
    tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME/" || {
        print_warning "Compression failed, keeping uncompressed backup"
        return 1
    }
    
    # Remove uncompressed directory
    rm -rf "$BACKUP_NAME/"
    
    local compressed_size=$(du -h "$BACKUP_NAME.tar.gz" | cut -f1)
    print_success "Backup compressed to $BACKUP_NAME.tar.gz (Size: $compressed_size)"
}

# Cleanup old backups
cleanup_old_backups() {
    local retention_days=${BACKUP_RETENTION_DAYS:-7}
    
    print_status "Cleaning up backups older than $retention_days days..."
    
    cd "$BACKUP_DIR"
    find . -name "queue_app_backup_*.tar.gz" -type f -mtime +$retention_days -delete || {
        print_warning "Cleanup failed"
    }
    
    local remaining_backups=$(find . -name "queue_app_backup_*.tar.gz" -type f | wc -l)
    print_success "Cleanup completed ($remaining_backups backups remaining)"
}

# Verify backup
verify_backup() {
    print_status "Verifying backup integrity..."
    
    cd "$BACKUP_DIR"
    
    if [ -f "$BACKUP_NAME.tar.gz" ]; then
        tar -tzf "$BACKUP_NAME.tar.gz" > /dev/null || {
            print_error "Backup verification failed - archive is corrupted!"
            exit 1
        }
        
        print_success "Backup verification passed"
    else
        print_warning "Compressed backup not found, checking directory..."
        
        if [ -d "$BACKUP_NAME" ] && [ -f "$BACKUP_NAME/database.sql" ]; then
            print_success "Uncompressed backup verified"
        else
            print_error "Backup verification failed - files missing!"
            exit 1
        fi
    fi
}

# Send notification (placeholder for future webhook/email integration)
send_notification() {
    print_status "Sending backup notification..."
    
    # Future: implement webhook or email notification
    # For now, just log the completion
    
    local backup_info=""
    if [ -f "$BACKUP_DIR/$BACKUP_NAME.tar.gz" ]; then
        backup_info="Compressed: $(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)"
    else
        backup_info="Uncompressed: $(du -sh "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"
    fi
    
    print_success "Backup notification: $BACKUP_NAME completed ($backup_info)"
}

# Main execution
main() {
    print_status "Starting backup process for database: $POSTGRES_DB"
    print_status "Backup name: $BACKUP_NAME"
    print_status "Target directory: $BACKUP_DIR"
    
    # Execute backup steps
    create_backup_dir
    wait_for_database
    backup_database
    backup_schema
    backup_critical_tables
    create_metadata
    
    # Verify before compression
    verify_backup
    
    # Compress if enabled
    if [ "$COMPRESS_BACKUP" != "false" ]; then
        compress_backup
    fi
    
    # Cleanup old backups
    if [ "$SKIP_CLEANUP" != "true" ]; then
        cleanup_old_backups
    fi
    
    # Send notification
    send_notification
    
    print_success "Backup process completed successfully! 🎉"
    print_status "Backup location: $BACKUP_DIR/$BACKUP_NAME"
}

# Handle command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-compress)
            export COMPRESS_BACKUP=false
            shift
            ;;
        --no-cleanup)
            export SKIP_CLEANUP=true
            shift
            ;;
        --retention)
            export BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--no-compress] [--no-cleanup] [--retention DAYS]"
            exit 1
            ;;
    esac
done

# Execute main function
main "$@"