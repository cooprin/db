DO $$
BEGIN
    -- Clients table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'clients' AND table_name = 'clients'
    ) THEN
        CREATE TABLE clients.clients (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            full_name VARCHAR(500),
            description TEXT,
            address TEXT,
            contact_person VARCHAR(255),
            phone VARCHAR(50),
            email VARCHAR(255),
            wialon_id VARCHAR(100),
            wialon_username VARCHAR(100),
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Додаємо унікальні обмеження
        ALTER TABLE clients.clients ADD CONSTRAINT clients_name_unique UNIQUE (name);
        CREATE UNIQUE INDEX clients_email_unique ON clients.clients (email) 
        WHERE email IS NOT NULL AND email != '';
        
        COMMENT ON TABLE clients.clients IS 'Clients catalog';
        COMMENT ON COLUMN clients.clients.wialon_id IS 'ID of the client in Wialon system';
        COMMENT ON COLUMN clients.clients.wialon_username IS 'Username of the client in Wialon system';
        RAISE NOTICE 'Clients table created with unique constraints';
    END IF;

    -- Перевіряємо чи існують обмеження для існуючої таблиці
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'clients' AND table_name = 'clients'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_schema = 'clients' 
        AND table_name = 'clients' 
        AND constraint_name = 'clients_name_unique'
    ) THEN
        ALTER TABLE clients.clients ADD CONSTRAINT clients_name_unique UNIQUE (name);
        RAISE NOTICE 'Added unique constraint for client name';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'clients' AND table_name = 'clients'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'clients' 
        AND tablename = 'clients' 
        AND indexname = 'clients_email_unique'
    ) THEN
        CREATE UNIQUE INDEX clients_email_unique ON clients.clients (email) 
        WHERE email IS NOT NULL AND email != '';
        RAISE NOTICE 'Added unique index for client email';
    END IF;

    -- Client documents table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'clients' AND table_name = 'client_documents'
    ) THEN
        CREATE TABLE clients.client_documents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL,
            document_name VARCHAR(255) NOT NULL,
            document_type VARCHAR(50) NOT NULL,
            file_path VARCHAR(500) NOT NULL,
            file_size INTEGER,
            description TEXT,
            uploaded_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_client_documents_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id) ON DELETE CASCADE,
            CONSTRAINT fk_client_documents_user FOREIGN KEY (uploaded_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );

        COMMENT ON TABLE clients.client_documents IS 'Documents attached to clients';
        RAISE NOTICE 'Client documents table created';
    END IF;

    -- Contacts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'clients' AND table_name = 'contacts'
    ) THEN
        CREATE TABLE clients.contacts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL,
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100),
            position VARCHAR(100),
            phone VARCHAR(50),
            email VARCHAR(255),
            is_primary BOOLEAN DEFAULT false,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_contacts_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id) ON DELETE CASCADE
        );

        COMMENT ON TABLE clients.contacts IS 'Client contacts';
        RAISE NOTICE 'Contacts table created';
    END IF;
END $$;