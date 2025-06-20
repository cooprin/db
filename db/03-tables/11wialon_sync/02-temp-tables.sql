DO $$
BEGIN
    -- Temporary Wialon clients table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'temp_wialon_clients'
    ) THEN
        CREATE TABLE wialon_sync.temp_wialon_clients (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id UUID NOT NULL,
            wialon_resource_id VARCHAR(100) NOT NULL,
            wialon_user_id VARCHAR(100) NOT NULL,
            name VARCHAR(255) NOT NULL,
            full_name VARCHAR(500),
            description TEXT,
            wialon_username VARCHAR(100),
            additional_data JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_temp_clients_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE
        );
        
        CREATE INDEX idx_temp_wialon_clients_session ON wialon_sync.temp_wialon_clients(session_id);
        CREATE INDEX idx_temp_wialon_clients_resource_id ON wialon_sync.temp_wialon_clients(wialon_resource_id);
        CREATE INDEX idx_temp_wialon_clients_user_id ON wialon_sync.temp_wialon_clients(wialon_user_id);
        CREATE INDEX idx_temp_wialon_clients_username ON wialon_sync.temp_wialon_clients(wialon_username);
        
        COMMENT ON TABLE wialon_sync.temp_wialon_clients IS 'Temporary storage for clients data from Wialon API';
        COMMENT ON COLUMN wialon_sync.temp_wialon_clients.wialon_resource_id IS 'Resource ID in Wialon system (for billing)';
        COMMENT ON COLUMN wialon_sync.temp_wialon_clients.wialon_user_id IS 'User ID in Wialon system (for authorization)';
        COMMENT ON COLUMN wialon_sync.temp_wialon_clients.additional_data IS 'Additional client data from Wialon API in JSON format';
        RAISE NOTICE 'Temporary Wialon clients table created';
    END IF;

    -- Додаємо нові поля до існуючої таблиці якщо потрібно
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'temp_wialon_clients'
    ) THEN
        -- Додаємо wialon_resource_id якщо його немає
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'wialon_sync' 
            AND table_name = 'temp_wialon_clients' 
            AND column_name = 'wialon_resource_id'
        ) THEN
            ALTER TABLE wialon_sync.temp_wialon_clients ADD COLUMN wialon_resource_id VARCHAR(100);
            CREATE INDEX idx_temp_wialon_clients_resource_id ON wialon_sync.temp_wialon_clients(wialon_resource_id);
            RAISE NOTICE 'Added wialon_resource_id column to temp_wialon_clients';
        END IF;
        
        -- Додаємо wialon_user_id якщо його немає
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'wialon_sync' 
            AND table_name = 'temp_wialon_clients' 
            AND column_name = 'wialon_user_id'
        ) THEN
            ALTER TABLE wialon_sync.temp_wialon_clients ADD COLUMN wialon_user_id VARCHAR(100);
            CREATE INDEX idx_temp_wialon_clients_user_id ON wialon_sync.temp_wialon_clients(wialon_user_id);
            RAISE NOTICE 'Added wialon_user_id column to temp_wialon_clients';
        END IF;

        -- Перейменовуємо старе поле wialon_id якщо воно існує
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'wialon_sync' 
            AND table_name = 'temp_wialon_clients' 
            AND column_name = 'wialon_id'
        ) AND NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'wialon_sync' 
            AND table_name = 'temp_wialon_clients' 
            AND column_name = 'wialon_user_id'
        ) THEN
            -- Перейменовуємо wialon_id в wialon_user_id
            ALTER TABLE wialon_sync.temp_wialon_clients RENAME COLUMN wialon_id TO wialon_user_id;
            RAISE NOTICE 'Renamed wialon_id to wialon_user_id in temp_wialon_clients';
        END IF;
    END IF;

    -- Temporary Wialon objects table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'temp_wialon_objects'
    ) THEN
        CREATE TABLE wialon_sync.temp_wialon_objects (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id UUID NOT NULL,
            wialon_id VARCHAR(100) NOT NULL,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            tracker_id VARCHAR(100),
            phone_numbers JSONB,
            additional_data JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_temp_objects_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE
        );
        
        CREATE INDEX idx_temp_wialon_objects_session ON wialon_sync.temp_wialon_objects(session_id);
        CREATE INDEX idx_temp_wialon_objects_wialon_id ON wialon_sync.temp_wialon_objects(wialon_id);
        CREATE INDEX idx_temp_wialon_objects_tracker ON wialon_sync.temp_wialon_objects(tracker_id);
        
        COMMENT ON TABLE wialon_sync.temp_wialon_objects IS 'Temporary storage for objects data from Wialon API';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.wialon_id IS 'Object ID in Wialon system';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.tracker_id IS 'Tracker device ID from Wialon';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.phone_numbers IS 'Array of phone numbers in JSON format';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.additional_data IS 'Additional object data from Wialon API in JSON format';
        RAISE NOTICE 'Temporary Wialon objects table created';
    END IF;
END $$;