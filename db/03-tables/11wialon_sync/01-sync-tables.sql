DO $$
BEGIN
    -- Sync sessions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'sync_sessions'
    ) THEN
        CREATE TABLE wialon_sync.sync_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            end_time TIMESTAMP WITH TIME ZONE,
            status VARCHAR(50) DEFAULT 'running',
            total_clients_checked INTEGER DEFAULT 0,
            total_objects_checked INTEGER DEFAULT 0,
            discrepancies_found INTEGER DEFAULT 0,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_sync_sessions_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_sync_status CHECK (status IN ('running', 'completed', 'failed', 'cancelled'))
        );
        
        COMMENT ON TABLE wialon_sync.sync_sessions IS 'History of synchronization sessions';
        RAISE NOTICE 'Sync sessions table created';
    END IF;

    -- Sync discrepancies table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'sync_discrepancies'
    ) THEN
        CREATE TABLE wialon_sync.sync_discrepancies (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id UUID NOT NULL,
            discrepancy_type VARCHAR(100) NOT NULL,
            entity_type VARCHAR(50) NOT NULL,
            system_client_id UUID,
            system_object_id UUID,
            suggested_client_id UUID,
            suggested_action VARCHAR(100),
            wialon_entity_data JSONB NOT NULL,
            system_entity_data JSONB,
            status VARCHAR(50) DEFAULT 'pending',
            resolution_notes TEXT,
            resolved_by UUID,
            resolved_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_sync_discrepancies_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE,
            CONSTRAINT fk_sync_discrepancies_system_client FOREIGN KEY (system_client_id) 
                REFERENCES clients.clients(id) ON DELETE SET NULL,
            CONSTRAINT fk_sync_discrepancies_system_object FOREIGN KEY (system_object_id) 
                REFERENCES wialon.objects(id) ON DELETE SET NULL,
            CONSTRAINT fk_sync_discrepancies_suggested_client FOREIGN KEY (suggested_client_id) 
                REFERENCES clients.clients(id) ON DELETE SET NULL,
            CONSTRAINT fk_sync_discrepancies_resolved_by FOREIGN KEY (resolved_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_discrepancy_type CHECK (discrepancy_type IN (
                'new_client', 'new_object', 'client_name_changed', 'object_name_changed', 
                'owner_changed', 'new_object_with_known_client', 'client_deleted', 'object_deleted',
                'client_username_changed'
            )),
            CONSTRAINT chk_entity_type CHECK (entity_type IN ('client', 'object')),
            CONSTRAINT chk_discrepancy_status CHECK (status IN ('pending', 'approved', 'added', 'ignored', 'rejected'))
        );
        
        COMMENT ON TABLE wialon_sync.sync_discrepancies IS 'Detected discrepancies between Wialon and system data';
        RAISE NOTICE 'Sync discrepancies table created';
    END IF;

    -- Sync logs table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'sync_logs'
    ) THEN
        CREATE TABLE wialon_sync.sync_logs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id UUID NOT NULL,
            log_level VARCHAR(20) NOT NULL,
            message TEXT NOT NULL,
            details JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_sync_logs_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE,
            CONSTRAINT chk_log_level CHECK (log_level IN ('info', 'warning', 'error', 'debug'))
        );
        
        COMMENT ON TABLE wialon_sync.sync_logs IS 'Detailed logs of synchronization process';
        RAISE NOTICE 'Sync logs table created';
    END IF;
        IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'only_one_running_session'
    ) THEN
        -- Використовуємо унікальний індекс замість EXCLUDE для PostgreSQL сумісності
        CREATE UNIQUE INDEX CONCURRENTLY idx_only_one_running_session 
        ON wialon_sync.sync_sessions (status) 
        WHERE status = 'running';
        
        RAISE NOTICE 'Constraint for single running session created';
    END IF;
END $$;