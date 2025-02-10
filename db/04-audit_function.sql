CREATE OR REPLACE FUNCTION audit.log_table_change()
RETURNS TRIGGER AS $$ 
DECLARE
    acting_user_id UUID;
    client_ip INET;
BEGIN 
    -- Get acting user id based on the table and operation type
    CASE TG_TABLE_NAME 
        WHEN 'users' THEN
            acting_user_id := CASE 
                WHEN TG_OP = 'DELETE' THEN OLD.id
                ELSE NEW.id
            END;
        WHEN 'roles' THEN
            -- For roles, try to get from session first
            BEGIN
                acting_user_id := current_setting('audit.user_id', false)::uuid;
            EXCEPTION WHEN OTHERS THEN
                acting_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
            END;
        WHEN 'permissions' THEN
            -- For permissions, try to get from session first
            BEGIN
                acting_user_id := current_setting('audit.user_id', false)::uuid;
            EXCEPTION WHEN OTHERS THEN
                acting_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
            END;
        WHEN 'resources' THEN
            -- For resources, try to get from session first
            BEGIN
                acting_user_id := current_setting('audit.user_id', false)::uuid;
            EXCEPTION WHEN OTHERS THEN
                acting_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
            END;
        ELSE
            -- For any other tables, try to get from session first
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

    -- Custom logic for different tables
    DECLARE
        entity_name TEXT;
    BEGIN
        -- Get readable entity name based on table
        entity_name := CASE TG_TABLE_NAME
            WHEN 'users' THEN 'User'
            WHEN 'roles' THEN 'Role'
            WHEN 'permissions' THEN 'Permission'
            WHEN 'resources' THEN 'Resource'
            ELSE TG_TABLE_NAME
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
    END;

    IF TG_OP = 'DELETE' THEN 
        RETURN OLD; 
    ELSE 
        RETURN NEW; 
    END IF; 
END;
$$ LANGUAGE plpgsql;