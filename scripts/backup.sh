#!/bin/bash

# Завантаження змінних середовища
source /etc/environment

BACKUP_DIR="/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Створення бекапу
PGPASSWORD=$POSTGRES_PASSWORD pg_dump -U $POSTGRES_USER -d $POSTGRES_DB > $BACKUP_FILE

# Видалення старих бекапів (опціонально, наприклад зберігати тільки за останні 7 днів)
find $BACKUP_DIR -name "backup_*.sql" -type f -mtime +7 -delete