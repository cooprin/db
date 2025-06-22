DO $$
BEGIN
    -- Chat rooms table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'chat' AND table_name = 'chat_rooms'
    ) THEN
        CREATE TABLE chat.chat_rooms (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL,
            ticket_id UUID,
            room_type VARCHAR(20) DEFAULT 'support',
            assigned_staff_id UUID,
            is_active BOOLEAN DEFAULT true,
            last_message_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_chat_rooms_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id) ON DELETE CASCADE,
            CONSTRAINT fk_chat_rooms_ticket FOREIGN KEY (ticket_id) 
                REFERENCES tickets.tickets(id) ON DELETE SET NULL,
            CONSTRAINT fk_chat_rooms_staff FOREIGN KEY (assigned_staff_id) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_room_type CHECK (room_type IN ('support', 'ticket'))
        );

        CREATE INDEX idx_chat_rooms_client_id ON chat.chat_rooms(client_id);
        CREATE INDEX idx_chat_rooms_ticket_id ON chat.chat_rooms(ticket_id);
        CREATE INDEX idx_chat_rooms_staff_id ON chat.chat_rooms(assigned_staff_id);
        CREATE INDEX idx_chat_rooms_active ON chat.chat_rooms(is_active, last_message_at DESC);

        COMMENT ON TABLE chat.chat_rooms IS 'Chat rooms between clients and staff';
        COMMENT ON COLUMN chat.chat_rooms.room_type IS 'support: general support chat, ticket: chat linked to specific ticket';
        RAISE NOTICE 'Chat rooms table created';
    END IF;

    -- Chat messages table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'chat' AND table_name = 'chat_messages'
    ) THEN
        CREATE TABLE chat.chat_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            room_id UUID NOT NULL,
            message_text TEXT NOT NULL,
            sender_id UUID NOT NULL,
            sender_type VARCHAR(20) NOT NULL,
            is_read BOOLEAN DEFAULT false,
            read_at TIMESTAMP WITH TIME ZONE,
            external_message_id VARCHAR(255),
            external_platform VARCHAR(20),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_chat_messages_room FOREIGN KEY (room_id) 
                REFERENCES chat.chat_rooms(id) ON DELETE CASCADE,
            CONSTRAINT chk_sender_type CHECK (sender_type IN ('client', 'staff')),
            CONSTRAINT chk_external_platform CHECK (external_platform IN ('viber', 'telegram', 'web') OR external_platform IS NULL)
        );

        CREATE INDEX idx_chat_messages_room_id ON chat.chat_messages(room_id);
        CREATE INDEX idx_chat_messages_created_at ON chat.chat_messages(created_at DESC);
        CREATE INDEX idx_chat_messages_sender ON chat.chat_messages(sender_id, sender_type);
        CREATE INDEX idx_chat_messages_unread ON chat.chat_messages(is_read, sender_type);
        CREATE INDEX idx_chat_messages_external ON chat.chat_messages(external_platform, external_message_id);

        COMMENT ON TABLE chat.chat_messages IS 'Messages in chat rooms';
        COMMENT ON COLUMN chat.chat_messages.external_message_id IS 'Message ID from external platform (Viber/Telegram)';
        RAISE NOTICE 'Chat messages table created';
    END IF;

    -- Chat files table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'chat' AND table_name = 'chat_files'
    ) THEN
        CREATE TABLE chat.chat_files (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            message_id UUID NOT NULL,
            file_name VARCHAR(255) NOT NULL,
            original_name VARCHAR(255) NOT NULL,
            file_path VARCHAR(500) NOT NULL,
            file_size INTEGER NOT NULL,
            mime_type VARCHAR(100),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_chat_files_message FOREIGN KEY (message_id) 
                REFERENCES chat.chat_messages(id) ON DELETE CASCADE
        );

        CREATE INDEX idx_chat_files_message_id ON chat.chat_files(message_id);
        CREATE INDEX idx_chat_files_created_at ON chat.chat_files(created_at);

        COMMENT ON TABLE chat.chat_files IS 'Files attached to chat messages';
        RAISE NOTICE 'Chat files table created';
    END IF;

    -- External integrations table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'chat' AND table_name = 'external_integrations'
    ) THEN
        CREATE TABLE chat.external_integrations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            platform VARCHAR(20) NOT NULL,
            name VARCHAR(255) NOT NULL,
            api_token TEXT,
            webhook_url TEXT,
            webhook_secret TEXT,
            settings JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            last_sync_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT chk_integration_platform CHECK (platform IN ('viber', 'telegram')),
            CONSTRAINT uk_external_integrations_platform UNIQUE (platform)
        );

        CREATE INDEX idx_external_integrations_platform ON chat.external_integrations(platform);
        CREATE INDEX idx_external_integrations_active ON chat.external_integrations(is_active);

        COMMENT ON TABLE chat.external_integrations IS 'Configuration for external chat platforms';
        RAISE NOTICE 'External integrations table created';
    END IF;
END $$;