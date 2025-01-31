FROM postgres:15

# Встановлення необхідних утиліт
RUN apt-get update && apt-get install -y \
    cron \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Створення директорій
RUN mkdir -p /var/log /backup \
    && touch /var/log/cron.log

# Копіювання SQL скрипта ініціалізації
COPY ./db/init.sql /docker-entrypoint-initdb.d/

# Копіювання скриптів для бекапу та відновлення
COPY ./scripts/backup.sh /usr/local/bin/
COPY ./scripts/restore.sh /usr/local/bin/

# Налаштування прав
RUN chmod 0644 /docker-entrypoint-initdb.d/init.sql \
    && chmod +x /usr/local/bin/backup.sh \
    && chmod +x /usr/local/bin/restore.sh

# Створення crontab для автоматичного бекапу
RUN echo "0 0 * * * /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron \
    && chmod 0644 /etc/cron.d/backup-cron \
    && crontab /etc/cron.d/backup-cron

# Копіювання скрипта запуску
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]