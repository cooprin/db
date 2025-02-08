-- Create additional indexes for performance optimization
DO $$
BEGIN
    -- Auth schema indexes
    -- Users table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'users' 
        AND indexname = 'idx_users_email_lower'
    ) THEN
        CREATE INDEX idx_users_email_lower ON auth.users (lower(email));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'users' 
        AND indexname = 'idx_users_last_login'
    ) THEN
        CREATE INDEX idx_users_last_login ON auth.users(last_login);
    END IF;

    -- Permissions table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'permissions' 
        AND indexname = 'idx_permissions_group_id'
    ) THEN
        CREATE INDEX idx_permissions_group_id ON auth.permissions(group_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'permissions' 
        AND indexname = 'idx_permissions_resource_id'
    ) THEN
        CREATE INDEX idx_permissions_resource_id ON auth.permissions(resource_id);
    END IF;

    -- Core schema indexes
    -- Resources table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'core' 
        AND tablename = 'resources' 
        AND indexname = 'idx_resources_type_code'
    ) THEN
        CREATE INDEX idx_resources_type_code ON core.resources(type, code);
    END IF;

    -- Actions table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'core' 
        AND tablename = 'actions' 
        AND indexname = 'idx_actions_code_lower'
    ) THEN
        CREATE INDEX idx_actions_code_lower ON core.actions(lower(code));
    END IF;

    -- Audit schema indexes
    -- Additional audit_logs indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'audit' 
        AND tablename = 'audit_logs' 
        AND indexname = 'idx_audit_logs_created_at_action'
    ) THEN
        CREATE INDEX idx_audit_logs_created_at_action 
        ON audit.audit_logs(created_at, action_type);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'audit' 
        AND tablename = 'audit_logs' 
        AND indexname = 'idx_audit_logs_entity_created'
    ) THEN
        CREATE INDEX idx_audit_logs_entity_created 
        ON audit.audit_logs(entity_type, entity_id, created_at);
    END IF;

    -- Grant privileges
    -- Auth schema
    GRANT USAGE ON SCHEMA auth TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO current_user;

    -- Core schema
    GRANT USAGE ON SCHEMA core TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core TO current_user;

    -- Audit schema
    GRANT USAGE ON SCHEMA audit TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO current_user;

END $$;