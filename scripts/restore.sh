#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Відновлення бази даних
psql -U $POSTGRES_USER -d $POSTGRES_DB < $BACKUP_FILE

echo "Restore completed from: $BACKUP_FILE"