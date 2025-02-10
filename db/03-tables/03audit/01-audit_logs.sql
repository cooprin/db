CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.audit_logs (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    action_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,  -- Тепер може бути NULL для бізнес-подій
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    audit_type TEXT NOT NULL DEFAULT 'SYSTEM',  -- 'SYSTEM' або 'BUSINESS'
    created_at TIMESTAMP DEFAULT now()
);

-- Додаємо індекс для швидкого пошуку по типу аудиту
CREATE INDEX IF NOT EXISTS idx_audit_logs_audit_type ON audit.audit_logs(audit_type);

COMMENT ON TABLE audit.audit_logs IS 'Лог змін у системі';
COMMENT ON COLUMN audit.audit_logs.id IS 'Унікальний ідентифікатор запису аудиту';
COMMENT ON COLUMN audit.audit_logs.user_id IS 'Ідентифікатор користувача, який виконав дію';
COMMENT ON COLUMN audit.audit_logs.action_type IS 'Тип дії (INSERT, UPDATE, DELETE, LOGIN, etc)';
COMMENT ON COLUMN audit.audit_logs.entity_type IS 'Тип сутності (наприклад, users, orders)';
COMMENT ON COLUMN audit.audit_logs.entity_id IS 'Ідентифікатор зміненої сутності';
COMMENT ON COLUMN audit.audit_logs.old_values IS 'Старі значення (NULL, якщо INSERT)';
COMMENT ON COLUMN audit.audit_logs.new_values IS 'Нові значення (NULL, якщо DELETE)';
COMMENT ON COLUMN audit.audit_logs.ip_address IS 'IP-адреса користувача';
COMMENT ON COLUMN audit.audit_logs.audit_type IS 'Тип аудиту (SYSTEM - через тригери, BUSINESS - через API)';
COMMENT ON COLUMN audit.audit_logs.created_at IS 'Час створення запису';