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

    -- Audit logging triggers
    -- Users table audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_users_changes'
    ) THEN
        CREATE TRIGGER audit_users_changes
            AFTER INSERT OR UPDATE OR DELETE ON auth.users
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;

    -- Roles table audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_roles_changes'
    ) THEN
        CREATE TRIGGER audit_roles_changes
            AFTER INSERT OR UPDATE OR DELETE ON auth.roles
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;

    -- Permissions table audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_permissions_changes'
    ) THEN
        CREATE TRIGGER audit_permissions_changes
            AFTER INSERT OR UPDATE OR DELETE ON auth.permissions
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;

    -- Resources table audit
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_resources_changes'
    ) THEN
        CREATE TRIGGER audit_resources_changes
            AFTER INSERT OR UPDATE OR DELETE ON core.resources
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;
END;
$$;