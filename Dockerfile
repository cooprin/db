FROM postgres:15

# Встановлення необхідних утиліт
RUN apt-get update && apt-get install -y \
    cron \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Створення директорій
RUN mkdir -p /var/log /backup \
    && touch /var/log/cron.log

# Створення тимчасової директорії для сортування SQL файлів
RUN mkdir -p /tmp/sql-init

# Копіювання SQL скриптів ініціалізації
COPY ./db/init/ /tmp/sql-init/

# Сортування та перейменування файлів для правильного порядку виконання
RUN cd /tmp/sql-init && \
    # Копіюємо файли верхнього рівня (00-*.sql, 01-*.sql, etc)
    for f in [0-9][0-9]-*.sql; do \
        if [ -f "$f" ]; then \
            cp "$f" "/docker-entrypoint-initdb.d/$(printf %03d ${f%%-*})_${f#*-}"; \
        fi; \
    done && \
    # Копіюємо файли з підкаталогу tables, зберігаючи схему та порядок
    find . -path "*/03-tables/*/*.sql" | sort | while read f; do \
        schema_dir=$(basename $(dirname "$f")); \
        filename=$(basename "$f"); \
        number=$(echo "$filename" | grep -o '^[0-9]\+' || echo "00"); \
        cp "$f" "/docker-entrypoint-initdb.d/300_${schema_dir}_${number}_${filename#*-}"; \
    done && \
    # Копіюємо файли seeds
    find . -path "*/07-seeds/*.sql" | sort | while read f; do \
        filename=$(basename "$f"); \
        number=$(echo "$filename" | grep -o '^[0-9]\+' || echo "00"); \
        cp "$f" "/docker-entrypoint-initdb.d/700_${number}_${filename#*-}"; \
    done && \
    # Видаляємо тимчасову директорію
    rm -rf /tmp/sql-init

# Копіювання скриптів для бекапу та відновлення
COPY ./scripts/backup.sh /usr/local/bin/
COPY ./scripts/restore.sh /usr/local/bin/

# Налаштування прав
RUN chmod -R 0644 /docker-entrypoint-initdb.d/ \
    && find /docker-entrypoint-initdb.d/ -type d -exec chmod 0755 {} + \
    && chmod +x /usr/local/bin/backup.sh \
    && chmod +x /usr/local/bin/restore.sh

# Створення crontab для автоматичного бекапу
RUN echo "0 0 * * * /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron \
    && chmod 0644 /etc/cron.d/backup-cron \
    && crontab /etc/cron.d/backup-cron