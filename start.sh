#!/bin/bash
service cron start
# Використовуємо системного користувача postgres, але з налаштуваннями з змінних середовища
exec gosu postgres postgres