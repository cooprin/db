CREATE OR REPLACE FUNCTION audit.log_table_change()
RETURNS TRIGGER AS $$
DECLARE
    change_type varchar(50);
    old_data jsonb;
    new_data jsonb;
BEGIN
    -- Визначаємо тип зміни
    CASE TG_OP
        WHEN 'INSERT' THEN
            change_type := 'INSERT';
            old_data := null;
            new_data := to_jsonb(NEW);
        WHEN 'UPDATE' THEN
            change_type := 'UPDATE';
            old_data := to_jsonb(OLD);
            new_data := to_jsonb(NEW);
        WHEN 'DELETE' THEN
            change_type := 'DELETE';
            old_data := to_jsonb(OLD);
            new_data := null;
    END CASE;

    -- Записуємо зміни в лог
    INSERT INTO audit.audit_logs (
        schema_name,
        table_name,
        change_type,
        old_data,
        new_data,
        changed_by
    ) VALUES (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        change_type,
        old_data,
        new_data,
        current_user
    );

    -- Повертаємо NEW для INSERT/UPDATE або OLD для DELETE
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;