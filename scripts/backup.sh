#!/bin/bash
BACKUP_DIR="/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

# Створення бекапу
pg_dump -U postgres -d crm_db > ${BACKUP_FILE}
gzip ${BACKUP_FILE}

# Видалення старих бекапів (зберігаємо останні 7)
find ${BACKUP_DIR} -name "backup_*.sql.gz" -type f -mtime +7 -delete