FROM postgres:15

# 
RUN apt-get update && apt-get install -y \
    cron \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# 
COPY ./scripts/backup.sh /usr/local/bin/backup.sh
COPY ./scripts/restore.sh /usr/local/bin/restore.sh
COPY ./db/init.sql /docker-entrypoint-initdb.d/

# 
RUN chmod +x /usr/local/bin/backup.sh \
    && chmod +x /usr/local/bin/restore.sh

# cron
COPY ./scripts/crontab /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron \
    && crontab /etc/cron.d/backup-cron

CMD ["postgres"]