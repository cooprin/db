DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'audit' 
        AND p.proname = 'log_table_change'
    ) THEN
        DROP FUNCTION audit.log_table_change CASCADE;
    END IF;
END $$;

CREATE FUNCTION audit.log_table_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit.audit_logs(
        action_type,
        entity_type,
        entity_id,
        old_values,
        new_values
    ) VALUES (
        TG_OP,  
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.id
            ELSE NEW.id
        END,
        CASE 
            WHEN TG_OP = 'DELETE' OR TG_OP = 'UPDATE' 
            THEN to_jsonb(OLD)
            ELSE NULL
        END,
        CASE 
            WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE'
            THEN to_jsonb(NEW)
            ELSE NULL
        END
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
