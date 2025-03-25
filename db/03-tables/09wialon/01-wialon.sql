DO $$
BEGIN
    -- Wialon objects table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon' AND table_name = 'objects'
    ) THEN
        CREATE TABLE wialon.objects (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            wialon_id VARCHAR(100) NOT NULL,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            client_id UUID NOT NULL,
            status VARCHAR(50) DEFAULT 'active',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_wialon_objects_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id)
        );
        
        CREATE UNIQUE INDEX idx_wialon_objects_wialon_id ON wialon.objects(wialon_id);
        
        COMMENT ON TABLE wialon.objects IS 'Wialon objects';
        COMMENT ON COLUMN wialon.objects.wialon_id IS 'ID of the object in Wialon system';
        COMMENT ON COLUMN wialon.objects.client_id IS 'Current client (owner) of the object';
        RAISE NOTICE 'Wialon objects table created';
    END IF;

    -- Object ownership history table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon' AND table_name = 'object_ownership_history'
    ) THEN
        CREATE TABLE wialon.object_ownership_history (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            object_id UUID NOT NULL,
            client_id UUID NOT NULL,
            start_date DATE NOT NULL,
            end_date DATE,
            notes TEXT,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_ownership_history_object FOREIGN KEY (object_id) 
                REFERENCES wialon.objects(id) ON DELETE CASCADE,
            CONSTRAINT fk_ownership_history_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id),
            CONSTRAINT fk_ownership_history_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );

        COMMENT ON TABLE wialon.object_ownership_history IS 'History of object ownership changes';
        COMMENT ON COLUMN wialon.object_ownership_history.end_date IS 'NULL means currently active';
        RAISE NOTICE 'Object ownership history table created';
    END IF;

    -- Object attributes table (for additional object properties)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon' AND table_name = 'object_attributes'
    ) THEN
        CREATE TABLE wialon.object_attributes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            object_id UUID NOT NULL,
            attribute_name VARCHAR(100) NOT NULL,
            attribute_value TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_object_attributes_object FOREIGN KEY (object_id) 
                REFERENCES wialon.objects(id) ON DELETE CASCADE,
            CONSTRAINT object_attribute_unique UNIQUE(object_id, attribute_name)
        );

        COMMENT ON TABLE wialon.object_attributes IS 'Additional attributes for Wialon objects';
        RAISE NOTICE 'Object attributes table created';
    END IF;

        -- Object status history table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon' AND table_name = 'object_status_history'
    ) THEN
        CREATE TABLE wialon.object_status_history (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            object_id UUID NOT NULL,
            status VARCHAR(50) NOT NULL,
            start_date DATE NOT NULL,
            end_date DATE,
            created_by UUID,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_status_history_object FOREIGN KEY (object_id) 
                REFERENCES wialon.objects(id) ON DELETE CASCADE,
            CONSTRAINT fk_status_history_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_status_values CHECK (status IN ('active', 'suspended', 'inactive'))
        );

        CREATE INDEX idx_object_status_history_object_id ON wialon.object_status_history(object_id);
        CREATE INDEX idx_object_status_history_dates ON wialon.object_status_history(start_date, end_date);

        COMMENT ON TABLE wialon.object_status_history IS 'History of object status changes';
        COMMENT ON COLUMN wialon.object_status_history.end_date IS 'NULL means currently active status';
        RAISE NOTICE 'Object status history table created';
    END IF;
END $$;