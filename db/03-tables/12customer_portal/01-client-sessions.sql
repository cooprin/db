DO $$
BEGIN
    -- Client sessions table for Wialon authentication
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'customer_portal' AND table_name = 'client_sessions'
    ) THEN
        CREATE TABLE customer_portal.client_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL,
            wialon_session_id VARCHAR(255),
            wialon_token TEXT,
            expires_at TIMESTAMP WITH TIME ZONE,
            ip_address INET,
            user_agent TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_client_sessions_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id) ON DELETE CASCADE
        );

        CREATE INDEX idx_client_sessions_client_id ON customer_portal.client_sessions(client_id);
        CREATE INDEX idx_client_sessions_active ON customer_portal.client_sessions(is_active, expires_at);
        CREATE INDEX idx_client_sessions_wialon_session ON customer_portal.client_sessions(wialon_session_id);

        COMMENT ON TABLE customer_portal.client_sessions IS 'Client authentication sessions with Wialon tokens';
        COMMENT ON COLUMN customer_portal.client_sessions.wialon_session_id IS 'Session ID from Wialon API';
        COMMENT ON COLUMN customer_portal.client_sessions.wialon_token IS 'Encrypted Wialon token for API calls';
        RAISE NOTICE 'Client sessions table created';
    END IF;
END $$;