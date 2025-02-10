CREATE OR REPLACE FUNCTION audit.log_table_change()
RETURNS TRIGGER AS $$ 
DECLARE
    acting_user_id UUID;
    client_ip INET;
    entity_name TEXT;
BEGIN 
    -- Get acting user id based on the table
    CASE TG_TABLE_NAME 
        WHEN 'users' THEN
            acting_user_id := CASE 
                WHEN TG_OP = 'DELETE' THEN OLD.id
                ELSE NEW.id
            END;
        ELSE
            BEGIN
                acting_user_id := current_setting('audit.user_id', false)::uuid;
            EXCEPTION WHEN OTHERS THEN
                acting_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
            END;
    END CASE;

    -- Try to get client IP
    BEGIN
        client_ip := current_setting('request.client_ip', false)::inet;
    EXCEPTION WHEN OTHERS THEN
        client_ip := NULL;
    END;

    -- Standardize entity type names
    entity_name := CASE TG_TABLE_NAME
        WHEN 'users' THEN 'USER'
        WHEN 'roles' THEN 'ROLE'
        WHEN 'permissions' THEN 'PERMISSION'
        WHEN 'permission_groups' THEN 'PERMISSION_GROUP'
        WHEN 'resources' THEN 'RESOURCE'
        WHEN 'resource_actions' THEN 'RESOURCE_ACTION'
        ELSE UPPER(TG_TABLE_NAME)
    END;

    INSERT INTO audit.audit_logs(
        user_id,
        action_type,
        entity_type,
        entity_id,
        old_values,
        new_values,
        ip_address,
        audit_type
    ) VALUES (
        acting_user_id,
        TG_OP,
        entity_name,
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
        END,
        client_ip,
        'SYSTEM'
    );

    IF TG_OP = 'DELETE' THEN 
        RETURN OLD; 
    ELSE 
        RETURN NEW; 
    END IF; 
END;
$$ LANGUAGE plpgsql;