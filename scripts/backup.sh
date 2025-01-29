#!/bin/bash

BACKUP_DIR="/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Створення бекапу
pg_dump -U $POSTGRES_USER -d $POSTGRES_DB > $BACKUP_FILE