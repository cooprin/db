-- Create audit logs table
DO $$
BEGIN
    -- Audit logs table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'audit' 
        AND tablename = 'audit_logs'
    ) THEN
        CREATE TABLE audit.audit_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id),
            action_type VARCHAR(50) NOT NULL,
            entity_type VARCHAR(50) NOT NULL,
            entity_id UUID,
            old_values JSONB,
            new_values JSONB,
            ip_address VARCHAR(45),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'audit' 
            AND tablename = 'audit_logs' 
            AND indexname = 'audit_logs_user_id_idx'
        ) THEN
            CREATE INDEX audit_logs_user_id_idx ON audit.audit_logs(user_id);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'audit' 
            AND tablename = 'audit_logs' 
            AND indexname = 'audit_logs_action_type_idx'
        ) THEN
            CREATE INDEX audit_logs_action_type_idx ON audit.audit_logs(action_type);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'audit' 
            AND tablename = 'audit_logs' 
            AND indexname = 'audit_logs_entity_idx'
        ) THEN
            CREATE INDEX audit_logs_entity_idx ON audit.audit_logs(entity_type, entity_id);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'audit' 
            AND tablename = 'audit_logs' 
            AND indexname = 'audit_logs_created_at_idx'
        ) THEN
            CREATE INDEX audit_logs_created_at_idx ON audit.audit_logs(created_at);
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.constraint_column_usage 
            WHERE constraint_name = 'check_audit_action_type'
        ) THEN
PERFORM core.add_constraint_if_not_exists(
    'audit.audit_logs',
    'check_audit_action_type',
    'CHECK (action_type IN (''create'', ''update'', ''delete'', ''login'', ''logout'', ''other'', ''login_failed'', ''login_success''))'
);
        END IF;

        COMMENT ON TABLE audit.audit_logs IS 'System audit logs for tracking all changes';
        COMMENT ON COLUMN audit.audit_logs.action_type IS 'Type of action performed (create, update, delete, etc.)';
        COMMENT ON COLUMN audit.audit_logs.entity_type IS 'Type of entity that was modified';
        COMMENT ON COLUMN audit.audit_logs.entity_id IS 'ID of the entity that was modified';
        COMMENT ON COLUMN audit.audit_logs.old_values IS 'Previous values before modification in JSONB format';
        COMMENT ON COLUMN audit.audit_logs.new_values IS 'New values after modification in JSONB format';
        COMMENT ON COLUMN audit.audit_logs.ip_address IS 'IP address of the user who performed the action';
    END IF;
END $$;