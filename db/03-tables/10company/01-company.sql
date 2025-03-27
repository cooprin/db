DO $$
BEGIN
    -- Organization details table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'organization_details'
    ) THEN
        CREATE TABLE company.organization_details (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            legal_name VARCHAR(500) NOT NULL,
            short_name VARCHAR(255),
            legal_form VARCHAR(100),
            edrpou VARCHAR(10),
            tax_number VARCHAR(20),
            legal_address TEXT,
            actual_address TEXT,
            phone VARCHAR(50),
            email VARCHAR(255),
            website VARCHAR(255),
            director_name VARCHAR(255),
            director_position VARCHAR(100),
            accountant_name VARCHAR(255),
            logo_path VARCHAR(500),
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE company.organization_details IS 'Company legal and contact information';
        RAISE NOTICE 'Organization details table created';
    END IF;

    -- Bank accounts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'bank_accounts'
    ) THEN
        CREATE TABLE company.bank_accounts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            organization_id UUID NOT NULL,
            bank_name VARCHAR(255) NOT NULL,
            account_number VARCHAR(50) NOT NULL,
            iban VARCHAR(50),
            mfo VARCHAR(10),
            swift_code VARCHAR(20),
            currency VARCHAR(3) DEFAULT 'UAH',
            is_default BOOLEAN DEFAULT false,
            is_active BOOLEAN DEFAULT true,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_bank_accounts_organization FOREIGN KEY (organization_id) 
                REFERENCES company.organization_details(id) ON DELETE CASCADE
        );
        
        COMMENT ON TABLE company.bank_accounts IS 'Company bank accounts';
        RAISE NOTICE 'Bank accounts table created';
    END IF;

    -- Legal documents table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'legal_documents'
    ) THEN
        CREATE TABLE company.legal_documents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            organization_id UUID NOT NULL,
            document_name VARCHAR(255) NOT NULL,
            document_type VARCHAR(100) NOT NULL,
            file_path VARCHAR(500) NOT NULL,
            file_size INTEGER,
            effective_date DATE,
            expiry_date DATE,
            description TEXT,
            uploaded_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_legal_documents_organization FOREIGN KEY (organization_id) 
                REFERENCES company.organization_details(id) ON DELETE CASCADE,
            CONSTRAINT fk_legal_documents_user FOREIGN KEY (uploaded_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );
        
        COMMENT ON TABLE company.legal_documents IS 'Company legal documents';
        RAISE NOTICE 'Legal documents table created';
    END IF;

    -- Wialon integration settings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'wialon_integration'
    ) THEN
        CREATE TABLE company.wialon_integration (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            api_url VARCHAR(255) NOT NULL,
            token_name VARCHAR(100) NOT NULL,
            token_value TEXT NOT NULL,
            is_active BOOLEAN DEFAULT true,
            last_sync_time TIMESTAMP WITH TIME ZONE,
            sync_interval INTEGER DEFAULT 60, -- in minutes
            additional_settings JSONB,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_wialon_integration_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );
        
        COMMENT ON TABLE company.wialon_integration IS 'Wialon API integration settings';
        RAISE NOTICE 'Wialon integration table created';
    END IF;

    -- Email settings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'email_settings'
    ) THEN
        CREATE TABLE company.email_settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email_address VARCHAR(255) NOT NULL,
            display_name VARCHAR(255),
            smtp_server VARCHAR(255) NOT NULL,
            smtp_port INTEGER NOT NULL,
            smtp_username VARCHAR(255),
            smtp_password TEXT,
            use_ssl BOOLEAN DEFAULT true,
            oauth_client_id TEXT,
            oauth_client_secret TEXT,
            oauth_refresh_token TEXT,
            oauth_access_token TEXT,
            oauth_expiry_time TIMESTAMP WITH TIME ZONE,
            is_default BOOLEAN DEFAULT false,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE company.email_settings IS 'Email server and authentication settings';
        RAISE NOTICE 'Email settings table created';
    END IF;

    -- Email templates
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'email_templates'
    ) THEN
        CREATE TABLE company.email_templates (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL UNIQUE,
            subject VARCHAR(255) NOT NULL,
            body_html TEXT NOT NULL,
            body_text TEXT,
            variables JSONB,
            description TEXT,
            is_active BOOLEAN DEFAULT true,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_email_templates_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );
        
        COMMENT ON TABLE company.email_templates IS 'Email templates for automated messages';
        RAISE NOTICE 'Email templates table created';
    END IF;

    -- Email queue
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'email_queue'
    ) THEN
        CREATE TABLE company.email_queue (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email_settings_id UUID,
            template_id UUID,
            recipient VARCHAR(255) NOT NULL,
            cc VARCHAR(500),
            bcc VARCHAR(500),
            subject VARCHAR(255) NOT NULL,
            body_html TEXT,
            body_text TEXT,
            attachments JSONB,
            metadata JSONB,
            status VARCHAR(50) DEFAULT 'pending',
            priority INTEGER DEFAULT 0,
            scheduled_time TIMESTAMP WITH TIME ZONE,
            sent_time TIMESTAMP WITH TIME ZONE,
            error_message TEXT,
            retry_count INTEGER DEFAULT 0,
            max_retries INTEGER DEFAULT 3,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_email_queue_settings FOREIGN KEY (email_settings_id) 
                REFERENCES company.email_settings(id) ON DELETE SET NULL,
            CONSTRAINT fk_email_queue_template FOREIGN KEY (template_id) 
                REFERENCES company.email_templates(id) ON DELETE SET NULL,
            CONSTRAINT fk_email_queue_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_email_queue_status CHECK (status IN ('pending', 'processing', 'sent', 'failed', 'cancelled'))
        );
        
        CREATE INDEX idx_email_queue_status ON company.email_queue(status);
        CREATE INDEX idx_email_queue_scheduled ON company.email_queue(scheduled_time);
        
        COMMENT ON TABLE company.email_queue IS 'Queue for outgoing emails';
        RAISE NOTICE 'Email queue table created';
    END IF;

    -- System settings
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'company' AND table_name = 'system_settings'
    ) THEN
        CREATE TABLE company.system_settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            category VARCHAR(100) NOT NULL,
            key VARCHAR(100) NOT NULL,
            value TEXT,
            value_type VARCHAR(20) DEFAULT 'string',
            description TEXT,
            is_public BOOLEAN DEFAULT false,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_system_settings_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT system_settings_key_unique UNIQUE(category, key),
            CONSTRAINT chk_value_type CHECK (value_type IN ('string', 'number', 'boolean', 'json', 'date'))
        );
        
        COMMENT ON TABLE company.system_settings IS 'System-wide configuration settings';
        RAISE NOTICE 'System settings table created';
    END IF;
END $$;