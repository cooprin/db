#!/bin/bash
service cron start
# Використовуємо змінну POSTGRES_USER з docker-compose
exec gosu $POSTGRES_USER postgres