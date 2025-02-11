-- Створюємо схему аудиту
CREATE SCHEMA IF NOT EXISTS audit;

-- Створюємо таблицю для зберігання логів
CREATE TABLE IF NOT EXISTS audit.audit_logs (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    action_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,  -- Змінюємо тип на TEXT для підтримки різних форматів ID
    old_values JSONB,
    new_values JSONB,
    changes JSONB, -- Зберігаємо тільки змінені поля
    ip_address INET,
    browser_info JSONB, -- Інформація про браузер у форматі JSON
    user_agent TEXT,
    table_schema TEXT, -- Схема таблиці
    table_name TEXT,   -- Назва таблиці
    audit_type TEXT NOT NULL DEFAULT 'SYSTEM',  -- SYSTEM або BUSINESS
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Створюємо індекси для оптимізації пошуку
CREATE INDEX IF NOT EXISTS idx_audit_logs_audit_type 
    ON audit.audit_logs(audit_type);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity 
    ON audit.audit_logs(entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user 
    ON audit.audit_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_date 
    ON audit.audit_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_audit_logs_table 
    ON audit.audit_logs(table_schema, table_name);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action 
    ON audit.audit_logs(action_type);

-- Додаємо коментарі до таблиці та колонок
COMMENT ON TABLE audit.audit_logs IS 'Таблиця для зберігання аудиту всіх змін у системі';
COMMENT ON COLUMN audit.audit_logs.id IS 'Унікальний ідентифікатор запису аудиту';
COMMENT ON COLUMN audit.audit_logs.user_id IS 'ID користувача, який виконав дію';
COMMENT ON COLUMN audit.audit_logs.action_type IS 'Тип дії (CREATE, UPDATE, DELETE, LOGIN, etc)';
COMMENT ON COLUMN audit.audit_logs.entity_type IS 'Тип сутності (users, warehouses, products, etc)';
COMMENT ON COLUMN audit.audit_logs.entity_id IS 'ID зміненої сутності';
COMMENT ON COLUMN audit.audit_logs.old_values IS 'Старі значення у форматі JSON';
COMMENT ON COLUMN audit.audit_logs.new_values IS 'Нові значення у форматі JSON';
COMMENT ON COLUMN audit.audit_logs.changes IS 'Тільки змінені поля у форматі JSON';
COMMENT ON COLUMN audit.audit_logs.ip_address IS 'IP-адреса користувача';
COMMENT ON COLUMN audit.audit_logs.browser_info IS 'Інформація про браузер у форматі JSON';
COMMENT ON COLUMN audit.audit_logs.user_agent IS 'User agent браузера';
COMMENT ON COLUMN audit.audit_logs.table_schema IS 'Назва схеми таблиці';
COMMENT ON COLUMN audit.audit_logs.table_name IS 'Назва таблиці';
COMMENT ON COLUMN audit.audit_logs.audit_type IS 'Тип аудиту (SYSTEM - через тригери, BUSINESS - через API)';
COMMENT ON COLUMN audit.audit_logs.created_at IS 'Дата та час створення запису з часовим поясом';