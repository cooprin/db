CREATE OR REPLACE FUNCTION audit.log_table_change()
RETURNS TRIGGER AS $$
DECLARE
    action_type_val varchar(50);
    entity_type_val varchar(50);
    old_values_val jsonb;
    new_values_val jsonb;
BEGIN
    -- Визначаємо тип дії
    CASE TG_OP
        WHEN 'INSERT' THEN
            action_type_val := 'create';
            old_values_val := null;
            new_values_val := to_jsonb(NEW);
        WHEN 'UPDATE' THEN
            action_type_val := 'update';
            old_values_val := to_jsonb(OLD);
            new_values_val := to_jsonb(NEW);
        WHEN 'DELETE' THEN
            action_type_val := 'delete';
            old_values_val := to_jsonb(OLD);
            new_values_val := null;
    END CASE;

    -- Формуємо тип сутності зі схеми та назви таблиці
    entity_type_val := TG_TABLE_NAME;

    -- Записуємо зміни в лог
    INSERT INTO audit.audit_logs (
        action_type,
        entity_type,
        entity_id,
        old_values,
        new_values,
        created_at
    ) VALUES (
        action_type_val,
        entity_type_val,
        CASE 
            WHEN TG_OP = 'DELETE' THEN (OLD).id
            ELSE (NEW).id
        END,
        old_values_val,
        new_values_val,
        CURRENT_TIMESTAMP
    );

    -- Повертаємо NEW для INSERT/UPDATE або OLD для DELETE
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;