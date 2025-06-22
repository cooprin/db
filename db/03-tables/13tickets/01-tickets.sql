DO $$
BEGIN
    -- Ticket categories table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'tickets' AND table_name = 'ticket_categories'
    ) THEN
        CREATE TABLE tickets.ticket_categories (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            color VARCHAR(7) DEFAULT '#007bff',
            icon VARCHAR(50),
            is_active BOOLEAN DEFAULT true,
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX idx_ticket_categories_active ON tickets.ticket_categories(is_active, sort_order);
        CREATE UNIQUE INDEX idx_ticket_categories_name ON tickets.ticket_categories(name) WHERE is_active = true;

        COMMENT ON TABLE tickets.ticket_categories IS 'Categories for client tickets/requests';
        RAISE NOTICE 'Ticket categories table created';
    END IF;

    -- Tickets table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'tickets' AND table_name = 'tickets'
    ) THEN
        CREATE TABLE tickets.tickets (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            ticket_number VARCHAR(50) NOT NULL UNIQUE,
            client_id UUID NOT NULL,
            category_id UUID,
            object_id UUID,
            title VARCHAR(500) NOT NULL,
            description TEXT,
            priority VARCHAR(20) DEFAULT 'medium',
            status VARCHAR(20) DEFAULT 'open',
            assigned_to UUID,
            resolved_at TIMESTAMP WITH TIME ZONE,
            closed_at TIMESTAMP WITH TIME ZONE,
            created_by UUID NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_tickets_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id) ON DELETE CASCADE,
            CONSTRAINT fk_tickets_category FOREIGN KEY (category_id) 
                REFERENCES tickets.ticket_categories(id) ON DELETE SET NULL,
            CONSTRAINT fk_tickets_object FOREIGN KEY (object_id) 
                REFERENCES wialon.objects(id) ON DELETE SET NULL,
            CONSTRAINT fk_tickets_assigned_to FOREIGN KEY (assigned_to) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT fk_tickets_created_by FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_tickets_priority CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
            CONSTRAINT chk_tickets_status CHECK (status IN ('open', 'in_progress', 'waiting_client', 'resolved', 'closed', 'cancelled'))
        );

        CREATE INDEX idx_tickets_client_id ON tickets.tickets(client_id);
        CREATE INDEX idx_tickets_status ON tickets.tickets(status);
        CREATE INDEX idx_tickets_priority ON tickets.tickets(priority);
        CREATE INDEX idx_tickets_assigned_to ON tickets.tickets(assigned_to);
        CREATE INDEX idx_tickets_category_id ON tickets.tickets(category_id);
        CREATE INDEX idx_tickets_object_id ON tickets.tickets(object_id);
        CREATE INDEX idx_tickets_created_at ON tickets.tickets(created_at DESC);

        COMMENT ON TABLE tickets.tickets IS 'Client support tickets and requests';
        RAISE NOTICE 'Tickets table created';
    END IF;

    -- Ticket comments table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'tickets' AND table_name = 'ticket_comments'
    ) THEN
        CREATE TABLE tickets.ticket_comments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            ticket_id UUID NOT NULL,
            comment_text TEXT NOT NULL,
            is_internal BOOLEAN DEFAULT false,
            created_by UUID NOT NULL,
            created_by_type VARCHAR(20) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_ticket_comments_ticket FOREIGN KEY (ticket_id) 
                REFERENCES tickets.tickets(id) ON DELETE CASCADE,
            CONSTRAINT chk_created_by_type CHECK (created_by_type IN ('client', 'staff')),
            CONSTRAINT chk_internal_comments CHECK (
                (is_internal = false) OR 
                (is_internal = true AND created_by_type = 'staff')
            )
        );

        CREATE INDEX idx_ticket_comments_ticket_id ON tickets.ticket_comments(ticket_id);
        CREATE INDEX idx_ticket_comments_created_at ON tickets.ticket_comments(created_at);
        CREATE INDEX idx_ticket_comments_created_by ON tickets.ticket_comments(created_by, created_by_type);
        CREATE INDEX idx_ticket_comments_internal ON tickets.ticket_comments(is_internal);

        COMMENT ON TABLE tickets.ticket_comments IS 'Comments and updates for tickets';
        RAISE NOTICE 'Ticket comments table created';
    END IF;

    -- Ticket files table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'tickets' AND table_name = 'ticket_files'
    ) THEN
        CREATE TABLE tickets.ticket_files (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            ticket_id UUID NOT NULL,
            comment_id UUID,
            file_name VARCHAR(255) NOT NULL,
            original_name VARCHAR(255) NOT NULL,
            file_path VARCHAR(500) NOT NULL,
            file_size INTEGER NOT NULL,
            mime_type VARCHAR(100),
            uploaded_by UUID NOT NULL,
            uploaded_by_type VARCHAR(20) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_ticket_files_ticket FOREIGN KEY (ticket_id) 
                REFERENCES tickets.tickets(id) ON DELETE CASCADE,
            CONSTRAINT fk_ticket_files_comment FOREIGN KEY (comment_id) 
                REFERENCES tickets.ticket_comments(id) ON DELETE SET NULL,
            CONSTRAINT chk_uploaded_by_type CHECK (uploaded_by_type IN ('client', 'staff'))
        );

        CREATE INDEX idx_ticket_files_ticket_id ON tickets.ticket_files(ticket_id);
        CREATE INDEX idx_ticket_files_comment_id ON tickets.ticket_files(comment_id);
        CREATE INDEX idx_ticket_files_uploaded_by ON tickets.ticket_files(uploaded_by, uploaded_by_type);
        CREATE INDEX idx_ticket_files_created_at ON tickets.ticket_files(created_at);

        COMMENT ON TABLE tickets.ticket_files IS 'Files attached to tickets and comments';
        RAISE NOTICE 'Ticket files table created';
    END IF;
END $$;