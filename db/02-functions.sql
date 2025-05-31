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

        -- Якщо об'єкт був призначений до 15-го числа місяця, нараховуємо за повний місяць
        IF ownership_date <= mid_month_cutoff THEN
            -- Перевіряємо чи об'єкт активний зараз
            IF EXISTS (
                SELECT 1 FROM wialon.object_status_history 
                WHERE object_id = p_object_id 
                AND status = 'active'
                AND start_date <= CURRENT_DATE
                AND (end_date IS NULL OR end_date >= CURRENT_DATE)
            ) THEN
                RETURN TRUE;
            END IF;
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
        RETURN (active_days > month_days / 2);
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
    DECLARE
        result BOOLEAN;
        p_period_start DATE;
        p_period_end DATE;
        obj_tariff_id UUID;
    BEGIN
        -- Визначаємо початок і кінець періоду
        p_period_start := DATE(p_billing_year || '-' || LPAD(p_billing_month::text, 2, '0') || '-01');
        p_period_end := (p_period_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

        -- Перевіряємо, чи є оплати за об'єкт для цього періоду
        SELECT EXISTS (
            SELECT 1 FROM billing.object_payment_records opr
            WHERE opr.object_id = p_object_id 
            AND opr.billing_year = p_billing_year 
            AND opr.billing_month = p_billing_month 
            AND opr.status IN ('paid', 'partial')
        ) INTO result;

        -- Якщо знайдено будь-яку оплату за цей період, повертаємо true
        RETURN result;
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
        v_start_date DATE;  -- Перейменовано змінну для уникнення конфлікту
        check_year INTEGER;
        check_month INTEGER;
        has_tariff BOOLEAN;
        period_date DATE;
        mid_month_date DATE;  -- Додано змінну для середини місяця
        first_ownership_date DATE;
        object_status VARCHAR(50);
    BEGIN
        -- Отримуємо поточний рік і місяць
        current_year := EXTRACT(YEAR FROM CURRENT_DATE);
        current_month := EXTRACT(MONTH FROM CURRENT_DATE);
        
        -- Перевіряємо статус об'єкта
        SELECT status INTO object_status
        FROM wialon.objects
        WHERE id = p_object_id;
        
        IF object_status != 'active' THEN
            billing_year := current_year;
            billing_month := current_month;
            RETURN NEXT;
            RETURN;
        END IF;
        
        -- Перевіряємо, чи об'єкт має тариф
        SELECT EXISTS (
            SELECT 1 FROM billing.object_tariffs
            WHERE object_id = p_object_id
            AND effective_to IS NULL
        ) INTO has_tariff;
        
        IF NOT has_tariff THEN
            billing_year := current_year;
            billing_month := current_month;
            RETURN NEXT;
            RETURN;
        END IF;
        
        -- Отримуємо дату першого призначення об'єкта клієнту
        SELECT MIN(oh.start_date) INTO first_ownership_date
        FROM wialon.object_ownership_history oh
        WHERE oh.object_id = p_object_id;
        
        -- Отримуємо дату початку активності об'єкта
        SELECT MIN(sh.start_date) INTO v_start_date                         
        FROM wialon.object_status_history sh
        WHERE sh.object_id = p_object_id
        AND sh.status = 'active';
        
        -- Використовуємо пізнішу з дат
        IF v_start_date IS NULL OR first_ownership_date > v_start_date THEN
            v_start_date := first_ownership_date;
        END IF;
        
        -- Якщо немає активного статусу, повертаємо поточний місяць/рік
        IF v_start_date IS NULL THEN
            billing_year := current_year;
            billing_month := current_month;
            RETURN NEXT;
            RETURN;
        END IF;
        
        -- Починаємо пошук з дати початку активності об'єкта
        check_year := EXTRACT(YEAR FROM v_start_date);
        check_month := EXTRACT(MONTH FROM v_start_date);
        
        -- Перевіряємо всі місяці від початку активності до поточного
        WHILE (check_year < current_year OR 
            (check_year = current_year AND check_month <= current_month))
        LOOP
            period_date := make_date(check_year, check_month, 1);
            mid_month_date := make_date(check_year, check_month, 15);  -- 15-е число місяця
            
            -- Перевіряємо чи був об'єкт активний в цей період
            -- Об'єкт повинен бути активований до 15-го числа
            IF EXISTS (
                SELECT 1 
                FROM wialon.object_status_history sh
                WHERE sh.object_id = p_object_id
                AND sh.status = 'active'
                AND sh.start_date < mid_month_date  -- Активація до 15-го числа
                AND (sh.end_date IS NULL OR sh.end_date >= period_date)  -- Об'єкт залишався активним принаймні на початок місяця
            ) AND EXISTS (
                SELECT 1 
                FROM billing.object_tariffs ot
                WHERE ot.object_id = p_object_id
                AND ot.effective_from <= period_date
                AND (ot.effective_to IS NULL OR ot.effective_to >= period_date)
            ) THEN
                -- Перевіряємо чи період оплачений
                IF NOT billing.is_period_paid(p_object_id, check_year, check_month) THEN
                    billing_year := check_year;
                    billing_month := check_month;
                    RETURN NEXT;
                    RETURN;
                END IF;
            END IF;
            
            -- Переходимо до наступного місяця
            check_month := check_month + 1;
            IF check_month > 12 THEN
                check_month := 1;
                check_year := check_year + 1;
            END IF;
        END LOOP;
        
        -- Якщо всі періоди оплачені, повертаємо наступний місяць
        IF current_month = 12 THEN
            billing_year := current_year + 1;
            billing_month := 1;
        ELSE
            billing_year := current_year;
            billing_month := current_month + 1;
        END IF;
        
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

    -- Wialon token encryption functions
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'encrypt_wialon_token'
    ) THEN
-- Функція шифрування (тільки з переданим ключем)
    CREATE OR REPLACE FUNCTION company.encrypt_wialon_token(
        p_token_text TEXT,
        p_encryption_key TEXT
    )
    RETURNS TEXT
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        encrypted_token TEXT;
    BEGIN
        -- Перевіряємо чи передано ключ
        IF p_encryption_key IS NULL OR length(p_encryption_key) < 32 THEN
            RAISE EXCEPTION 'Encryption key is required and must be at least 32 characters';
        END IF;
        
        -- Шифруємо
        encrypted_token := pgp_sym_encrypt(p_token_text, p_encryption_key);
        
        RETURN encrypted_token;
    END;
    $func$;

    -- Функція розшифрування (тільки з переданим ключем)
    CREATE OR REPLACE FUNCTION company.decrypt_wialon_token(
        p_encrypted_token TEXT,
        p_encryption_key TEXT
    )
    RETURNS TEXT
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        decrypted_token TEXT;
    BEGIN
        -- Перевіряємо чи передано ключ
        IF p_encryption_key IS NULL OR length(p_encryption_key) < 32 THEN
            RAISE EXCEPTION 'Encryption key is required and must be at least 32 characters';
        END IF;
        
        -- Розшифровуємо
        BEGIN
            decrypted_token := pgp_sym_decrypt(p_encrypted_token, p_encryption_key);
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to decrypt Wialon token. Invalid encryption key or corrupted data.';
        END;
        
        RETURN decrypted_token;
    END;
    $func$;
    -- Оновлена функція set_wialon_token (обов'язковий ключ)
    CREATE OR REPLACE FUNCTION company.set_wialon_token(
        p_api_url TEXT,
        p_token_name TEXT,
        p_token_text TEXT,
        p_sync_interval INTEGER DEFAULT 60,
        p_additional_settings JSONB DEFAULT '{}',
        p_user_id UUID DEFAULT NULL,
        p_encryption_key TEXT -- Обов'язковий параметр (без DEFAULT)
    )
    RETURNS UUID
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        integration_id UUID;
        encrypted_token TEXT;
    BEGIN
        -- Шифруємо токен з переданим ключем
        encrypted_token := company.encrypt_wialon_token(p_token_text, p_encryption_key);
        
        -- Деактивуємо всі існуючі інтеграції
        UPDATE company.wialon_integration 
        SET is_active = false, updated_at = CURRENT_TIMESTAMP;
        
        -- Вставляємо нову інтеграцію
        INSERT INTO company.wialon_integration (
            api_url,
            token_name,
            token_value,
            encryption_method,
            is_active,
            sync_interval,
            additional_settings,
            created_by
        ) VALUES (
            p_api_url,
            p_token_name,
            encrypted_token,
            'pgp_sym',
            true,
            p_sync_interval,
            p_additional_settings,
            p_user_id
        ) RETURNING id INTO integration_id;
        
        RETURN integration_id;
    END;
    $func$;
    -- Оновлена функція get_wialon_token (обов'язковий ключ)
    CREATE OR REPLACE FUNCTION company.get_wialon_token(
        p_encryption_key TEXT -- Обов'язковий параметр (без DEFAULT)
    )
    RETURNS TABLE(
        integration_id UUID,
        api_url VARCHAR(255),
        token_name VARCHAR(255),
        decrypted_token TEXT,
        sync_interval INTEGER,
        additional_settings JSONB,
        last_sync_time TIMESTAMP WITH TIME ZONE
    )
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        integration_record RECORD;
    BEGIN
        -- Отримуємо активну інтеграцію
        SELECT * INTO integration_record
        FROM company.wialon_integration
        WHERE is_active = true
        ORDER BY created_at DESC
        LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No active Wialon integration found';
        END IF;
        
        -- Повертаємо розшифровані дані з обов'язковою передачею ключа
        RETURN QUERY SELECT
            integration_record.id,
            integration_record.api_url,
            integration_record.token_name,
            company.decrypt_wialon_token(integration_record.token_value, p_encryption_key),
            integration_record.sync_interval,
            integration_record.additional_settings,
            integration_record.last_sync_time;
    END;
    $func$;

        -- Function to update last sync time
        CREATE OR REPLACE FUNCTION company.update_wialon_sync_time()
        RETURNS VOID
        LANGUAGE plpgsql
        AS $func$
        BEGIN
            UPDATE company.wialon_integration 
            SET last_sync_time = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE is_active = true;
        END;
        $func$;

        RAISE NOTICE 'Wialon token encryption functions created';
    END IF;

END $$;