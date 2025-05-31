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
            wialon_id VARCHAR(100) NOT NULL,
            name VARCHAR(255) NOT NULL,
            full_name VARCHAR(500),
            description TEXT,
            additional_data JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_temp_clients_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE
        );
        
        CREATE INDEX idx_temp_wialon_clients_session ON wialon_sync.temp_wialon_clients(session_id);
        CREATE INDEX idx_temp_wialon_clients_wialon_id ON wialon_sync.temp_wialon_clients(wialon_id);
        
        COMMENT ON TABLE wialon_sync.temp_wialon_clients IS 'Temporary storage for clients data from Wialon API';
        COMMENT ON COLUMN wialon_sync.temp_wialon_clients.wialon_id IS 'Client ID in Wialon system';
        COMMENT ON COLUMN wialon_sync.temp_wialon_clients.additional_data IS 'Additional client data from Wialon API in JSON format';
        RAISE NOTICE 'Temporary Wialon clients table created';
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
            owner_wialon_id VARCHAR(100),
            tracker_id VARCHAR(100),
            phone_numbers JSONB,
            additional_data JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_temp_objects_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE
        );
        
        CREATE INDEX idx_temp_wialon_objects_session ON wialon_sync.temp_wialon_objects(session_id);
        CREATE INDEX idx_temp_wialon_objects_wialon_id ON wialon_sync.temp_wialon_objects(wialon_id);
        CREATE INDEX idx_temp_wialon_objects_owner ON wialon_sync.temp_wialon_objects(owner_wialon_id);
        CREATE INDEX idx_temp_wialon_objects_tracker ON wialon_sync.temp_wialon_objects(tracker_id);
        
        COMMENT ON TABLE wialon_sync.temp_wialon_objects IS 'Temporary storage for objects data from Wialon API';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.wialon_id IS 'Object ID in Wialon system';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.owner_wialon_id IS 'Owner client ID in Wialon system';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.tracker_id IS 'Tracker device ID from Wialon';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.phone_numbers IS 'Array of phone numbers in JSON format';
        COMMENT ON COLUMN wialon_sync.temp_wialon_objects.additional_data IS 'Additional object data from Wialon API in JSON format';
        RAISE NOTICE 'Temporary Wialon objects table created';
    END IF;
END $$;