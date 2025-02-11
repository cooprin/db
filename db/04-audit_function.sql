CREATE OR REPLACE FUNCTION audit.log_table_change()
RETURNS TRIGGER AS $$ 
DECLARE
    acting_user_id UUID;
    client_ip INET;
    browser_info JSONB;
    user_agent TEXT;
    changes_json JSONB;
    entity_name TEXT;
BEGIN 
    -- Отримуємо ID користувача
    BEGIN
        acting_user_id := CASE 
            WHEN TG_TABLE_NAME = 'users' AND TG_OP = 'DELETE' THEN OLD.id
            WHEN TG_TABLE_NAME = 'users' THEN NEW.id
            ELSE current_setting('audit.user_id', false)::uuid
        END;
    EXCEPTION WHEN OTHERS THEN
        acting_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END;

    -- Отримуємо IP клієнта
    BEGIN
        client_ip := current_setting('request.client_ip', false)::inet;
    EXCEPTION WHEN OTHERS THEN
        client_ip := NULL;
    END;

    -- Отримуємо інформацію про браузер
    BEGIN
        browser_info := current_setting('request.browser_info', false)::jsonb;
    EXCEPTION WHEN OTHERS THEN
        browser_info := NULL;
    END;

    -- Отримуємо User Agent
    BEGIN
        user_agent := current_setting('request.user_agent', false);
    EXCEPTION WHEN OTHERS THEN
        user_agent := NULL;
    END;

    -- Формуємо зміни (тільки змінені поля)
    IF TG_OP = 'UPDATE' THEN
        SELECT jsonb_object_agg(key, value)
        INTO changes_json
        FROM (
            SELECT 
                key,
                jsonb_build_object(
                    'old', old_value,
                    'new', new_value
                ) as value
            FROM jsonb_each_text(to_jsonb(OLD)) old_fields
            FULL OUTER JOIN jsonb_each_text(to_jsonb(NEW)) new_fields USING (key)
            WHERE old_fields.value IS DISTINCT FROM new_fields.value
        ) changes;
    ELSE
        changes_json := NULL;
    END IF;

    -- Стандартизуємо назви сутностей
    entity_name := CASE TG_TABLE_NAME
        WHEN 'users' THEN 'USER'
        WHEN 'roles' THEN 'ROLE'
        WHEN 'permissions' THEN 'PERMISSION'
        WHEN 'permission_groups' THEN 'PERMISSION_GROUP'
        WHEN 'resources' THEN 'RESOURCE'
        WHEN 'resource_actions' THEN 'RESOURCE_ACTION'
        ELSE UPPER(TG_TABLE_NAME)
    END;

    -- Записуємо в лог
    INSERT INTO audit.audit_logs(
        user_id,
        action_type,
        entity_type,
        entity_id,
        old_values,
        new_values,
        changes,
        ip_address,
        browser_info,
        user_agent,
        table_schema,
        table_name,
        audit_type
    ) VALUES (
        acting_user_id,
        TG_OP,
        entity_name,
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.id::text
            ELSE NEW.id::text
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
        changes_json,
        client_ip,
        browser_info,
        user_agent,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        'SYSTEM'
    );

    IF TG_OP = 'DELETE' THEN 
        RETURN OLD; 
    ELSE 
        RETURN NEW; 
    END IF; 
END;
$$ LANGUAGE plpgsql;