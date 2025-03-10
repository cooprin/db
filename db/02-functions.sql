-- Helper functions for the database
DO $$
BEGIN
    -- Add constraint if not exists function
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'add_constraint_if_not_exists'
    ) THEN
        CREATE OR REPLACE FUNCTION core.add_constraint_if_not_exists(
            t_name text, c_name text, c_sql text
        ) RETURNS void AS $func$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 
                FROM information_schema.constraint_column_usage 
                WHERE constraint_name = c_name
            ) THEN
                EXECUTE 'ALTER TABLE ' || t_name || ' ADD CONSTRAINT ' || c_name || ' ' || c_sql;
            END IF;
        END;
        $func$ LANGUAGE plpgsql;
    END IF;

    -- Update timestamp function
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'update_timestamp'
    ) THEN
        CREATE OR REPLACE FUNCTION core.update_timestamp()
        RETURNS TRIGGER AS $func$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql;
    END IF;
    
    -- Функція для визначення, чи потрібно нараховувати оплату за об'єкт за поточний місяць
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'should_charge_for_month'
    ) THEN
        CREATE OR REPLACE FUNCTION billing.should_charge_for_month(
            p_object_id UUID, 
            p_client_id UUID, 
            p_billing_year INTEGER, 
            p_billing_month INTEGER
        )
        RETURNS BOOLEAN
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            ownership_date DATE;
            month_start DATE;
            mid_month_cutoff DATE;
        BEGIN
            -- Отримуємо дату призначення об'єкта клієнту
            SELECT start_date INTO ownership_date
            FROM wialon.object_ownership_history
            WHERE object_id = p_object_id AND client_id = p_client_id
            ORDER BY start_date DESC
            LIMIT 1;
            
            -- Якщо не знайдено запису про власність, повертаємо false
            IF ownership_date IS NULL THEN
                RETURN FALSE;
            END IF;
            
            -- Визначаємо початок місяця та дату 15-го числа
            month_start := DATE(p_billing_year || '-' || LPAD(p_billing_month::text, 2, '0') || '-01');
            mid_month_cutoff := DATE(p_billing_year || '-' || LPAD(p_billing_month::text, 2, '0') || '-15');
            
            -- Якщо об'єкт був призначений до 15-го включно, нараховуємо за поточний місяць
            -- Якщо після 15-го, не нараховуємо за поточний місяць
            RETURN (
                ownership_date <= mid_month_cutoff AND 
                ownership_date <= CURRENT_DATE
            );
        END;
        $func$;
    END IF;
END $$;