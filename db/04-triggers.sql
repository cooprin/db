-- Create triggers for timestamp updates
DO $$
BEGIN
    -- Auth schema triggers
    -- Users table
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_users_timestamp'
    ) THEN
        CREATE TRIGGER update_users_timestamp
            BEFORE UPDATE ON auth.users
            FOR EACH ROW
            EXECUTE FUNCTION core.update_timestamp();
    END IF;

    -- Roles table
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_roles_timestamp'
    ) THEN
        CREATE TRIGGER update_roles_timestamp
            BEFORE UPDATE ON auth.roles
            FOR EACH ROW
            EXECUTE FUNCTION core.update_timestamp();
    END IF;

    -- Permissions table
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_permissions_timestamp'
    ) THEN
        CREATE TRIGGER update_permissions_timestamp
            BEFORE UPDATE ON auth.permissions
            FOR EACH ROW
            EXECUTE FUNCTION core.update_timestamp();
    END IF;

    -- Permission groups table
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_permission_groups_timestamp'
    ) THEN
        CREATE TRIGGER update_permission_groups_timestamp
            BEFORE UPDATE ON auth.permission_groups
            FOR EACH ROW
            EXECUTE FUNCTION core.update_timestamp();
    END IF;

    -- Core schema triggers
    -- Resources table
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_resources_timestamp'
    ) THEN
        CREATE TRIGGER update_resources_timestamp
            BEFORE UPDATE ON core.resources
            FOR EACH ROW
            EXECUTE FUNCTION core.update_timestamp();
    END IF;

    -- Audit logging trigger functions
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'log_table_change'
    ) THEN
        CREATE OR REPLACE FUNCTION audit.log_table_change()
        RETURNS TRIGGER AS $$
        DECLARE
            change_type varchar(50);
            old_data jsonb;
            new_data jsonb;
        BEGIN
            IF (TG_OP = 'DELETE') THEN
                change_type := 'delete';
                old_data := to_jsonb(OLD);
                new_data := null;
            ELSIF (TG_OP = 'UPDATE') THEN
                change_type := 'update';
                old_data := to_jsonb(OLD);
                new_data := to_jsonb(NEW);
            ELSIF (TG_OP = 'INSERT') THEN
                change_type := 'create';
                old_data := null;
                new_data := to_jsonb(NEW);
            END IF;

            INSERT INTO audit.audit_logs(
                user_id,
                action_type,
                entity_type,
                entity_id,
                old_values,
                new_values,
                created_at
            )
            VALUES (
                current_setting('app.current_user_id', true)::uuid,
                change_type,
                TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
                CASE 
                    WHEN TG_OP = 'DELETE' THEN OLD.id
                    ELSE NEW.id
                END,
                old_data,
                new_data,
                CURRENT_TIMESTAMP
            );

            IF (TG_OP = 'DELETE') THEN
                RETURN OLD;
            END IF;
            
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    END IF;

    -- Add audit triggers to tables
    -- Users audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_users_changes'
    ) THEN
        CREATE TRIGGER audit_users_changes
            AFTER INSERT OR UPDATE OR DELETE ON auth.users
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;

    -- Roles audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_roles_changes'
    ) THEN
        CREATE TRIGGER audit_roles_changes
            AFTER INSERT OR UPDATE OR DELETE ON auth.roles
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;

    -- Resources audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_resources_changes'
    ) THEN
        CREATE TRIGGER audit_resources_changes
            AFTER INSERT OR UPDATE OR DELETE ON core.resources
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;
END $$;