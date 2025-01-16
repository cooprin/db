#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: restore.sh <backup_file>"
    exit 1
fi

BACKUP_FILE=$1

# 
gunzip -c ${BACKUP_FILE} | psql -U postgres -d crm_db