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
    -- Функція для визначення, чи потрібно нараховувати оплату за об'єкт за конкретний місяць
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
        month_end DATE;
        mid_month_cutoff DATE;
        active_days INTEGER := 0;
        month_days INTEGER;
        was_paid BOOLEAN;
    BEGIN
        -- Визначаємо початок місяця, середину місяця та кінець місяця
        month_start := DATE(p_billing_year || '-' || LPAD(p_billing_month::text, 2, '0') || '-01');
        month_end := (month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
        mid_month_cutoff := DATE(p_billing_year || '-' || LPAD(p_billing_month::text, 2, '0') || '-15');
        month_days := EXTRACT(DAY FROM month_end);

        -- Перевірка, чи вже є оплата за цей об'єкт і період
        SELECT EXISTS (
            SELECT 1 FROM billing.object_payment_records 
            WHERE object_id = p_object_id 
            AND billing_month = p_billing_month 
            AND billing_year = p_billing_year 
            AND status IN ('paid', 'partial')
        ) INTO was_paid;
        
        -- Якщо період уже оплачено, не нараховуємо повторно
        IF was_paid THEN
            RETURN FALSE;
        END IF;
        
        -- Отримуємо дату призначення об'єкта клієнту
        SELECT start_date INTO ownership_date
        FROM wialon.object_ownership_history
        WHERE object_id = p_object_id AND client_id = p_client_id
        AND (end_date IS NULL OR end_date >= month_start)
        AND start_date <= month_end
        ORDER BY start_date DESC
        LIMIT 1;
        
        -- Якщо не знайдено запису про власність, повертаємо false
        IF ownership_date IS NULL THEN
            RETURN FALSE;
        END IF;

        -- Підрахунок днів активності об'єкта в заданому місяці
        SELECT COUNT(*)::INTEGER INTO active_days
        FROM (
            SELECT generate_series::DATE
            FROM generate_series(
                GREATEST(month_start, ownership_date)::TIMESTAMP,
                LEAST(month_end, CURRENT_DATE)::TIMESTAMP,
                '1 day'::INTERVAL
            )
        ) days
        WHERE EXISTS (
            SELECT 1 FROM wialon.object_status_history 
            WHERE object_id = p_object_id 
            AND status = 'active'
            AND start_date <= days.generate_series
            AND (end_date IS NULL OR end_date >= days.generate_series)
        );
        
        -- Правило: оплата нараховується, якщо об'єкт був активний більше половини місяця
        -- або якщо об'єкт призначений до 15-го числа і в даний момент активний
        RETURN (
            (active_days > month_days / 2) OR 
            (ownership_date <= mid_month_cutoff AND 
            EXISTS (
                SELECT 1 FROM wialon.object_status_history 
                WHERE object_id = p_object_id 
                AND status = 'active'
                AND start_date <= CURRENT_DATE
                AND (end_date IS NULL OR end_date >= CURRENT_DATE)
            ))
        );
    END;
    $func$;

    -- Функція для перевірки, чи період вже оплачений для об'єкта
    CREATE OR REPLACE FUNCTION billing.is_period_paid(
        p_object_id UUID,
        p_billing_year INTEGER,
        p_billing_month INTEGER
    )
    RETURNS BOOLEAN
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        RETURN EXISTS (
            SELECT 1 FROM billing.object_payment_records 
            WHERE object_id = p_object_id 
            AND billing_year = p_billing_year 
            AND billing_month = p_billing_month 
            AND status IN ('paid', 'partial')
        );
    END;
    $func$;

    -- Функція для отримання наступного неоплаченого періоду для об'єкта
    CREATE OR REPLACE FUNCTION billing.get_next_unpaid_period(
        p_object_id UUID
    )
    RETURNS TABLE(billing_year INTEGER, billing_month INTEGER)
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        current_year INTEGER;
        current_month INTEGER;
        start_date DATE;
        check_year INTEGER;
        check_month INTEGER;
    BEGIN
        -- Отримуємо поточний рік і місяць
        current_year := EXTRACT(YEAR FROM CURRENT_DATE);
        current_month := EXTRACT(MONTH FROM CURRENT_DATE);
        
        -- Отримуємо дату початку активності об'єкта
        SELECT MIN(start_date) INTO start_date
        FROM wialon.object_status_history
        WHERE object_id = p_object_id
        AND status = 'active';
        
        -- Якщо немає активного статусу, повертаємо поточний місяць/рік
        IF start_date IS NULL THEN
            billing_year := current_year;
            billing_month := current_month;
            RETURN NEXT;
            RETURN;
        END IF;
        
        -- Шукаємо найближчий неоплачений період, починаючи з поточного місяця
        check_year := current_year;
        check_month := current_month;
        
        -- Перевіряємо наступні 12 місяців
        FOR i IN 0..11 LOOP
            -- Якщо для цього місяця немає оплати, повертаємо його
            IF NOT billing.is_period_paid(p_object_id, check_year, check_month) THEN
                billing_year := check_year;
                billing_month := check_month;
                RETURN NEXT;
                RETURN;
            END IF;
            
            -- Переходимо до наступного місяця
            check_month := check_month + 1;
            IF check_month > 12 THEN
                check_month := 1;
                check_year := check_year + 1;
            END IF;
        END LOOP;
        
        -- Якщо всі 12 місяців оплачені, повертаємо місяць через рік
        billing_year := CASE WHEN current_month = 12 THEN current_year + 1 ELSE current_year END;
        billing_month := CASE WHEN current_month = 12 THEN 1 ELSE current_month + 1 END;
        RETURN NEXT;
        RETURN;
    END;
    $func$;

    -- Функція для визначення оптимальної дати зміни тарифу (з наступного неоплаченого періоду)
    CREATE OR REPLACE FUNCTION billing.get_optimal_tariff_change_date(
        p_object_id UUID
    )
    RETURNS DATE
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        next_year INTEGER;
        next_month INTEGER;
        change_date DATE;
    BEGIN
        -- Отримуємо наступний неоплачений період
        SELECT billing_year, billing_month INTO next_year, next_month
        FROM billing.get_next_unpaid_period(p_object_id);
        
        -- Формуємо дату (перше число місяця)
        change_date := DATE(next_year || '-' || LPAD(next_month::text, 2, '0') || '-01');
        
        RETURN change_date;
    END;
    $func$;
    END IF;
END $$;