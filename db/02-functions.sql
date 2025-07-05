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
    
    -- Функція для отримання останнього (найсвіжішого) тарифу який діє в заданому місяці
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'get_latest_tariff_for_month'
    ) THEN
    CREATE OR REPLACE FUNCTION billing.get_latest_tariff_for_month(
        p_object_id UUID,
        p_billing_year INTEGER,
        p_billing_month INTEGER
    )
    RETURNS TABLE(
        tariff_id UUID,
        tariff_price DECIMAL(10,2),
        effective_from DATE
    )
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        month_start DATE;
        month_end DATE;
    BEGIN
        -- Визначаємо початок і кінець місяця
        month_start := DATE(p_billing_year || '-' || LPAD(p_billing_month::text, 2, '0') || '-01');
        month_end := (month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
        
        -- Знаходимо останній тариф який почав діяти в цьому місяці або раніше
        -- але ще діє в цьому місяці
        RETURN QUERY
        SELECT 
            ot.tariff_id,
            t.price,
            ot.effective_from
        FROM billing.object_tariffs ot
        JOIN billing.tariffs t ON ot.tariff_id = t.id
        WHERE ot.object_id = p_object_id
        AND ot.effective_from <= month_end
        AND (ot.effective_to IS NULL OR ot.effective_to >= month_start)
        ORDER BY ot.effective_from DESC
        LIMIT 1;
    END;
    $func$;
    END IF;

    -- Wialon token encryption functions
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'encrypt_wialon_token'
    ) THEN
    CREATE OR REPLACE FUNCTION company.encrypt_wialon_token(
        p_token_text TEXT,
        p_encryption_key TEXT
    )
    RETURNS TEXT
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        encrypted_token BYTEA;
    BEGIN
        IF p_encryption_key IS NULL OR length(p_encryption_key) < 32 THEN
            RAISE EXCEPTION 'Encryption key is required and must be at least 32 characters';
        END IF;
        
        encrypted_token := pgp_sym_encrypt(p_token_text, p_encryption_key);
        
        -- Кодуємо в base64 замість ::TEXT
        RETURN encode(encrypted_token, 'base64');
    END;
    $func$;

    -- Виправлена функція розшифрування
    CREATE OR REPLACE FUNCTION company.decrypt_wialon_token(
        p_encrypted_token TEXT,
        p_encryption_key TEXT
    )
    RETURNS TEXT
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        decrypted_token BYTEA;
    BEGIN
        IF p_encryption_key IS NULL OR length(p_encryption_key) < 32 THEN
            RAISE EXCEPTION 'Encryption key is required and must be at least 32 characters';
        END IF;
        
        BEGIN
            -- Декодуємо з base64 замість ::BYTEA
            decrypted_token := pgp_sym_decrypt(decode(p_encrypted_token, 'base64'), p_encryption_key);
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to decrypt Wialon token. Invalid encryption key or corrupted data.';
        END;
        
        -- Конвертуємо BYTEA в TEXT правильно
        RETURN convert_from(decrypted_token, 'UTF8');
    END;
    $func$;

    -- Оновлена функція set_wialon_token (обов'язковий ключ)
    CREATE OR REPLACE FUNCTION company.set_wialon_token(
        p_api_url TEXT,
        p_token_name TEXT,
        p_token_text TEXT,
        p_encryption_key TEXT,              -- Перемістили ПЕРЕД параметри з DEFAULT
        p_sync_interval INTEGER DEFAULT 60,
        p_additional_settings JSONB DEFAULT '{}',
        p_user_id UUID DEFAULT NULL
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
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'cleanup_stale_sessions'
    ) THEN
        CREATE OR REPLACE FUNCTION wialon_sync.cleanup_stale_sessions()
        RETURNS INTEGER
        LANGUAGE plpgsql
        AS $cleanup_func$
        DECLARE
            updated_count INTEGER;
        BEGIN
            UPDATE wialon_sync.sync_sessions 
            SET status = 'failed',
                end_time = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
            WHERE status = 'running' 
            AND start_time < CURRENT_TIMESTAMP - INTERVAL '2 hours';
            
            GET DIAGNOSTICS updated_count = ROW_COUNT;
            
            IF updated_count > 0 THEN
                INSERT INTO wialon_sync.sync_logs (session_id, log_level, message, details)
                SELECT id, 'warning', 'Session marked as failed due to timeout', 
                       jsonb_build_object('timeout_hours', 2, 'cleanup_time', CURRENT_TIMESTAMP)
                FROM wialon_sync.sync_sessions 
                WHERE status = 'failed' 
                AND end_time = CURRENT_TIMESTAMP
                AND start_time < CURRENT_TIMESTAMP - INTERVAL '2 hours';
            END IF;
            
            RETURN updated_count;
        END;
        $cleanup_func$;

        RAISE NOTICE 'Cleanup stale sessions function created';
    END IF;
    -- Reports functions
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'check_report_permission'
    ) THEN
    CREATE OR REPLACE FUNCTION reports.check_report_permission(
        p_report_id UUID,
        p_user_id UUID DEFAULT NULL,
        p_user_type VARCHAR(20) DEFAULT 'staff',
        p_client_id UUID DEFAULT NULL
    )
    RETURNS BOOLEAN
    LANGUAGE plpgsql
    AS $func$
    BEGIN
        -- Перевіряємо чи звіт активний
        IF NOT EXISTS (
            SELECT 1 FROM reports.report_definitions 
            WHERE id = p_report_id AND is_active = true
        ) THEN
            RETURN false;
        END IF;
        
        -- Звіти доступні тільки для персоналу
        -- Перевірка дозволів відбувається на рівні middleware
        IF p_user_type = 'staff' AND p_user_id IS NOT NULL THEN
            RETURN true;
        END IF;
        
        -- Клієнти не мають доступу до звітів
        RETURN false;
    END;
    $func$;

        RAISE NOTICE 'Report permission check function created';
    END IF;

    -- Function to get reports for a specific page
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'get_page_reports'
    ) THEN
        CREATE OR REPLACE FUNCTION reports.get_page_reports(
            p_page_identifier VARCHAR(100),
            p_user_id UUID DEFAULT NULL,
            p_user_type VARCHAR(20) DEFAULT 'staff',
            p_client_id UUID DEFAULT NULL
        )
        RETURNS TABLE(
            report_id UUID,
            report_name VARCHAR(255),
            report_code VARCHAR(100),
            description TEXT,
            output_format VARCHAR(50),
            auto_execute BOOLEAN,
            display_order INTEGER,
            parameters_count BIGINT,
            has_execute_permission BOOLEAN
        )
        LANGUAGE plpgsql
        AS $func$
        BEGIN
            RETURN QUERY
            SELECT 
                rd.id,
                rd.name,
                rd.code,
                rd.description,
                rd.output_format,
                pra.auto_execute,
                pra.display_order,
                COUNT(rp.id) as parameters_count,
                reports.check_report_permission(rd.id, p_user_id, p_user_type, p_client_id) as has_execute_permission
            FROM reports.report_definitions rd
            JOIN reports.page_report_assignments pra ON rd.id = pra.report_id
            LEFT JOIN reports.report_parameters rp ON rd.id = rp.report_id
            WHERE rd.is_active = true
            AND pra.is_visible = true
            AND pra.page_identifier = p_page_identifier
            GROUP BY rd.id, pra.auto_execute, pra.display_order
            ORDER BY pra.display_order, rd.name;
        END;
        $func$;

        RAISE NOTICE 'Get page reports function created';
    END IF;

    -- Function to execute report with parameters
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'execute_report'
    ) THEN
        CREATE OR REPLACE FUNCTION reports.execute_report(
            p_report_id UUID,
            p_parameters JSONB DEFAULT '{}',
            p_user_id UUID DEFAULT NULL,
            p_user_type VARCHAR(20) DEFAULT 'staff',
            p_client_id UUID DEFAULT NULL,
            p_page_identifier VARCHAR(100) DEFAULT NULL,
            p_ip_address INET DEFAULT NULL,
            p_user_agent TEXT DEFAULT NULL
        )
        RETURNS TABLE(
            success BOOLEAN,
            execution_id UUID,
            data JSONB,
            error_message TEXT,
            execution_time DECIMAL,
            rows_count INTEGER,
            from_cache BOOLEAN
        )
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            report_record RECORD;
            sql_query TEXT;
            result_data JSONB;
            param_key TEXT;
            param_value TEXT;
            start_time TIMESTAMP;
            end_time TIMESTAMP;
            exec_time DECIMAL;
            row_count INTEGER := 0;
            cache_key VARCHAR(64);
            cached_result RECORD;
            execution_id UUID;
            error_msg TEXT := NULL;
            is_success BOOLEAN := true;
            is_from_cache BOOLEAN := false;
        BEGIN
            start_time := clock_timestamp();
            execution_id := gen_random_uuid();
            
            -- Перевіряємо дозволи
            IF NOT reports.check_report_permission(p_report_id, p_user_id, p_user_type, p_client_id) THEN
                success := false;
                error_message := 'Access denied';
                execution_time := 0;
                rows_count := 0;
                from_cache := false;
                RETURN NEXT;
                RETURN;
            END IF;
            
            -- Отримуємо дані звіту
            SELECT * INTO report_record
            FROM reports.report_definitions
            WHERE id = p_report_id AND is_active = true;
            
            IF NOT FOUND THEN
                success := false;
                error_message := 'Report not found or inactive';
                execution_time := 0;
                rows_count := 0;
                from_cache := false;
                RETURN NEXT;
                RETURN;
            END IF;
            
            -- Генеруємо ключ кешу з урахуванням користувача
            cache_key := encode(sha256((
                p_report_id::text || 
                p_parameters::text || 
                COALESCE(p_user_id::text, '') || 
                p_user_type
            )::bytea), 'hex');
            
            -- Перевіряємо кеш якщо увімкнено
            IF report_record.cache_duration > 0 THEN
                SELECT * INTO cached_result
                FROM reports.report_cache
                WHERE report_id = p_report_id 
                AND parameters_hash = cache_key
                AND expires_at > CURRENT_TIMESTAMP;
                
                IF FOUND THEN
                    end_time := clock_timestamp();
                    exec_time := EXTRACT(EPOCH FROM (end_time - start_time));
                    
                    -- Логуємо виконання з кешу
                    INSERT INTO reports.report_execution_history (
                        id, report_id, executed_by, executed_by_type, page_identifier,
                        parameters, execution_time, rows_returned, status, cache_hit,
                        ip_address, user_agent
                    ) VALUES (
                        execution_id, p_report_id, p_user_id, p_user_type, p_page_identifier,
                        p_parameters, exec_time, cached_result.rows_count, 'success', true,
                        p_ip_address, p_user_agent
                    );
                    
                    -- Інтеграція з системою аудиту
                    BEGIN
                        PERFORM audit.log_system_event(
                            'REPORT_EXECUTE',
                            'REPORT',
                            p_report_id,
                            jsonb_build_object(
                                'report_id', p_report_id,
                                'user_id', p_user_id,
                                'user_type', p_user_type,
                                'page_identifier', p_page_identifier,
                                'parameters', p_parameters,
                                'execution_time', exec_time,
                                'rows_count', row_count,
                                'status', CASE WHEN is_success THEN 'success' ELSE 'error' END,
                                'from_cache', is_from_cache,
                                'ip_address', p_ip_address
                            ),
                            p_ip_address
                        );
                    EXCEPTION WHEN OTHERS THEN
                        -- Не блокуємо виконання звіту якщо аудит не працює
                        NULL;
                    END;
                    
                    success := true;
                    data := cached_result.cache_data;
                    error_message := NULL;
                    execution_time := exec_time;
                    rows_count := cached_result.rows_count;
                    from_cache := true;
                    RETURN NEXT;
                    RETURN;
                END IF;
            END IF;
            
        -- Підготовляємо SQL запит з параметрами (БЕЗПЕЧНО)
        sql_query := report_record.sql_query;

        -- Валідуємо та замінюємо параметри безпечно
        -- Спочатку замінюємо всі null параметри на порожні рядки для універсальної обробки
        FOR param_key IN SELECT jsonb_object_keys(p_parameters)
        LOOP
            IF p_parameters->param_key = 'null'::jsonb OR p_parameters->param_key IS NULL THEN
                sql_query := replace(sql_query, ':' || param_key, '''''');
            END IF;
        END LOOP;

        -- Тепер обробляємо не-null параметри
        FOR param_key, param_value IN SELECT * FROM jsonb_each_text(p_parameters)
        LOOP
            -- Пропускаємо вже оброблені null параметри
            IF param_value IS NULL OR param_value = 'null' THEN
                CONTINUE;
            END IF;
            
            -- Перевіряємо що параметр існує в схемі звіту
            IF NOT EXISTS (
                SELECT 1 FROM reports.report_parameters 
                WHERE report_id = p_report_id AND parameter_name = param_key
            ) THEN
                error_msg := 'Invalid parameter: ' || param_key;
                is_success := false;
                EXIT;
            END IF;
            
            -- Безпечна заміна параметрів з перевіркою типу
            DECLARE
                param_type VARCHAR(50);
                safe_value TEXT;
            BEGIN
                SELECT parameter_type INTO param_type 
                FROM reports.report_parameters 
                WHERE report_id = p_report_id AND parameter_name = param_key;
                
                -- Валідуємо та форматуємо значення за типом
                CASE param_type
                    WHEN 'number' THEN
                        safe_value := param_value::NUMERIC::TEXT;
                    WHEN 'date' THEN
                        safe_value := quote_literal(param_value::DATE::TEXT);
                    WHEN 'datetime' THEN
                        safe_value := quote_literal(param_value::TIMESTAMP::TEXT);
                    WHEN 'boolean' THEN
                        safe_value := (param_value::BOOLEAN)::TEXT;
                    WHEN 'client_id', 'user_id' THEN
                        safe_value := param_value::UUID::TEXT;
                    ELSE
                        safe_value := quote_literal(param_value);
                END CASE;
                
                sql_query := replace(sql_query, ':' || param_key, safe_value);
            EXCEPTION WHEN OTHERS THEN
                error_msg := 'Invalid parameter value for ' || param_key || ': ' || param_value;
                is_success := false;
                EXIT;
            END;
        END LOOP;

        -- Додаткова перевірка SQL на заборонені команди
        IF is_success AND (
            sql_query ~* '\b(DROP|DELETE|UPDATE|INSERT|ALTER|CREATE|TRUNCATE|GRANT|REVOKE)\b'
            OR sql_query ~* '\b(pg_|information_schema\.|pg_catalog\.)\b'
        ) THEN
            error_msg := 'SQL query contains forbidden operations';
            is_success := false;
        END IF;
            
            BEGIN
                -- Виконуємо запит та збираємо результат в JSON
                EXECUTE format('
                    SELECT jsonb_agg(row_to_json(t)) as result, count(*) as cnt
                    FROM (%s) t
                ', sql_query) INTO result_data, row_count;
                
                end_time := clock_timestamp();
                exec_time := EXTRACT(EPOCH FROM (end_time - start_time));
                
                -- Зберігаємо в кеш якщо потрібно
                IF report_record.cache_duration > 0 THEN
                    INSERT INTO reports.report_cache (
                        report_id, parameters_hash, cache_data, execution_time,
                        rows_count, expires_at
                    ) VALUES (
                        p_report_id, cache_key, result_data, exec_time,
                        row_count, CURRENT_TIMESTAMP + (report_record.cache_duration || ' minutes')::INTERVAL
                    )
                    ON CONFLICT (report_id, parameters_hash) 
                    DO UPDATE SET
                        cache_data = EXCLUDED.cache_data,
                        execution_time = EXCLUDED.execution_time,
                        rows_count = EXCLUDED.rows_count,
                        expires_at = EXCLUDED.expires_at,
                        created_at = CURRENT_TIMESTAMP;
                END IF;
                
            EXCEPTION WHEN OTHERS THEN
                end_time := clock_timestamp();
                exec_time := EXTRACT(EPOCH FROM (end_time - start_time));
                error_msg := SQLERRM;
                is_success := false;
                result_data := NULL;
                row_count := 0;
            END;
            
            -- Логуємо виконання
            INSERT INTO reports.report_execution_history (
                id, report_id, executed_by, executed_by_type, page_identifier,
                parameters, execution_time, rows_returned, status, error_message,
                cache_hit, ip_address, user_agent
            ) VALUES (
                execution_id, p_report_id, p_user_id, p_user_type, p_page_identifier,
                p_parameters, exec_time, row_count, 
                CASE WHEN is_success THEN 'success' ELSE 'error' END,
                error_msg, false, p_ip_address, p_user_agent
            );
            
            success := is_success;
            data := result_data;
            error_message := error_msg;
            execution_time := exec_time;
            rows_count := row_count;
            from_cache := is_from_cache;
            RETURN NEXT;
            RETURN;
        END;
        $func$;

        RAISE NOTICE 'Execute report function created';
    END IF;

    -- Function to clear expired cache
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'clear_expired_cache'
    ) THEN
        CREATE OR REPLACE FUNCTION reports.clear_expired_cache()
        RETURNS INTEGER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            deleted_count INTEGER;
        BEGIN
            DELETE FROM reports.report_cache 
            WHERE expires_at <= CURRENT_TIMESTAMP;
            
            GET DIAGNOSTICS deleted_count = ROW_COUNT;
            
            RETURN deleted_count;
        END;
        $func$;

        RAISE NOTICE 'Clear expired cache function created';
    END IF;

    -- Function to get report parameters schema
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'get_report_parameters'
    ) THEN
        CREATE OR REPLACE FUNCTION reports.get_report_parameters(
            p_report_id UUID
        )
        RETURNS TABLE(
            parameter_name VARCHAR(100),
            parameter_type VARCHAR(50),
            display_name VARCHAR(255),
            description TEXT,
            is_required BOOLEAN,
            default_value TEXT,
            validation_rules JSONB,
            options JSONB,
            ordering INTEGER
        )
        LANGUAGE plpgsql
        AS $func$
        BEGIN
            RETURN QUERY
            SELECT 
                rp.parameter_name,
                rp.parameter_type,
                rp.display_name,
                rp.description,
                rp.is_required,
                rp.default_value,
                rp.validation_rules,
                rp.options,
                rp.ordering
            FROM reports.report_parameters rp
            WHERE rp.report_id = p_report_id
            ORDER BY rp.ordering, rp.parameter_name;
        END;
        $func$;

        RAISE NOTICE 'Get report parameters function created';
    END IF;

        -- Function to export report results
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'export_report_results'
    ) THEN
        CREATE OR REPLACE FUNCTION reports.export_report_results(
            p_report_id UUID,
            p_parameters JSONB DEFAULT '{}',
            p_user_id UUID DEFAULT NULL,
            p_user_type VARCHAR(20) DEFAULT 'staff',
            p_format VARCHAR(10) DEFAULT 'csv'
        )
        RETURNS TABLE(
            success BOOLEAN,
            data TEXT,
            filename VARCHAR(255),
            content_type VARCHAR(100),
            error_message TEXT
        )
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            report_data JSONB;
            csv_data TEXT := '';
            json_data TEXT := '';
            row_data JSONB;
            headers TEXT[];
            values TEXT[];
            report_name VARCHAR(255);
            i INTEGER;
        BEGIN
            -- Виконуємо звіт
            SELECT rd.data, rd.error_message, rdef.name
            INTO report_data, error_message, report_name
            FROM reports.execute_report(p_report_id, p_parameters, p_user_id, p_user_type) rd
            JOIN reports.report_definitions rdef ON rdef.id = p_report_id
            WHERE rd.success = true;
            
            IF report_data IS NULL THEN
                success := false;
                error_message := COALESCE(error_message, 'No data returned from report');
                RETURN NEXT;
                RETURN;
            END IF;
            
            -- Формуємо дані за форматом
            IF p_format = 'csv' THEN
                -- Отримуємо заголовки з першого рядка
                IF jsonb_array_length(report_data) > 0 THEN
                    SELECT array_agg(key ORDER BY key) INTO headers
                    FROM jsonb_object_keys(report_data->0) AS key;
                    
                    -- Додаємо заголовки
                    csv_data := array_to_string(headers, ',') || E'\n';
                    
                    -- Додаємо дані
                    FOR i IN 0..jsonb_array_length(report_data)-1 LOOP
                        row_data := report_data->i;
                        
                        SELECT array_agg(
                            CASE 
                                WHEN row_data->>key IS NULL THEN ''
                                WHEN row_data->>key ~ ',' THEN '"' || replace(row_data->>key, '"', '""') || '"'
                                ELSE row_data->>key
                            END
                            ORDER BY key
                        ) INTO values
                        FROM unnest(headers) AS key;
                        
                        csv_data := csv_data || array_to_string(values, ',') || E'\n';
                    END LOOP;
                END IF;
                
                success := true;
                data := csv_data;
                filename := replace(report_name, ' ', '_') || '_' || to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD_HH24-MI-SS') || '.csv';
                content_type := 'text/csv';
                
            ELSIF p_format = 'json' THEN
                success := true;
                data := report_data::TEXT;
                filename := replace(report_name, ' ', '_') || '_' || to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD_HH24-MI-SS') || '.json';
                content_type := 'application/json';
                
            ELSE
                success := false;
                error_message := 'Unsupported export format: ' || p_format;
            END IF;
            
            RETURN NEXT;
        END;
        $func$;

        RAISE NOTICE 'Export report results function created';
    END IF;

END $$;