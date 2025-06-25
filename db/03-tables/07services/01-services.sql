DO $$
BEGIN
    -- Services table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'services' AND table_name = 'services'
    ) THEN
        CREATE TABLE services.services (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            service_type VARCHAR(50) NOT NULL,
            fixed_price DECIMAL(10,2),
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT chk_service_type CHECK (service_type IN ('fixed', 'object_based')),
            CONSTRAINT chk_fixed_price CHECK ((service_type = 'fixed' AND fixed_price IS NOT NULL) OR 
                                             (service_type = 'object_based'))
        );
        
        COMMENT ON TABLE services.services IS 'Services catalog';
        COMMENT ON COLUMN services.services.service_type IS 'fixed - with fixed price, object_based - calculated from objects';
        RAISE NOTICE 'Services table created';
    END IF;

    -- Client services
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'services' AND table_name = 'client_services'
    ) THEN
        CREATE TABLE services.client_services (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL,
            service_id UUID NOT NULL,
            start_date DATE NOT NULL,
            end_date DATE,
            status VARCHAR(50) DEFAULT 'active',
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_client_services_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id),
            CONSTRAINT fk_client_services_service FOREIGN KEY (service_id) 
                REFERENCES services.services(id),
            CONSTRAINT chk_client_service_status CHECK (status IN ('active', 'suspended', 'terminated'))
        );

        COMMENT ON TABLE services.client_services IS 'Services assigned to clients';
        COMMENT ON COLUMN services.client_services.end_date IS 'NULL means ongoing service';
        RAISE NOTICE 'Client services table created';
    END IF;

    -- Service invoices - видаляємо зовнішній ключ на billing.payments
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'services' AND table_name = 'invoices'
    ) THEN
    CREATE TABLE services.invoices (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id UUID NOT NULL,
        invoice_number VARCHAR(50) NOT NULL,
        invoice_date DATE NOT NULL,
        billing_month INTEGER NOT NULL,
        billing_year INTEGER NOT NULL,
        total_amount DECIMAL(10,2) NOT NULL,
        status VARCHAR(50) DEFAULT 'issued',
        payment_id UUID,
        notes TEXT,
        created_by UUID,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        -- ТУТ НЕ БУДЕ template_id!
        CONSTRAINT fk_invoices_client FOREIGN KEY (client_id) 
            REFERENCES clients.clients(id),
        CONSTRAINT fk_invoices_user FOREIGN KEY (created_by) 
            REFERENCES auth.users(id) ON DELETE SET NULL,
        CONSTRAINT chk_invoice_status CHECK (status IN ('draft', 'issued', 'paid', 'cancelled')),
        CONSTRAINT chk_invoice_billing_month CHECK (billing_month BETWEEN 1 AND 12),
        CONSTRAINT chk_invoice_billing_year CHECK (billing_year BETWEEN 2000 AND 2100)
    );

        CREATE UNIQUE INDEX idx_invoice_number ON services.invoices(invoice_number);

        COMMENT ON TABLE services.invoices IS 'Invoices issued to clients';
        RAISE NOTICE 'Invoices table created';
    END IF;

    -- Invoice items
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'services' AND table_name = 'invoice_items'
    ) THEN
        CREATE TABLE services.invoice_items (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            invoice_id UUID NOT NULL,
            service_id UUID,
            description TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            unit_price DECIMAL(10,2) NOT NULL,
            total_price DECIMAL(10,2) NOT NULL,
            metadata JSONB, -- Додана колонка metadata типу JSONB
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) 
                REFERENCES services.invoices(id) ON DELETE CASCADE,
            CONSTRAINT fk_invoice_items_service FOREIGN KEY (service_id) 
                REFERENCES services.services(id) ON DELETE SET NULL
        );

        COMMENT ON TABLE services.invoice_items IS 'Items in client invoices';
        COMMENT ON COLUMN services.invoice_items.metadata IS 'JSON data containing additional information about the invoice item, such as object details or debt information';
        RAISE NOTICE 'Invoice items table created';
    END IF;

    -- Invoice documents
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'services' AND table_name = 'invoice_documents'
    ) THEN
        CREATE TABLE services.invoice_documents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            invoice_id UUID NOT NULL,
            document_name VARCHAR(255) NOT NULL,
            document_type VARCHAR(50) NOT NULL,
            file_path VARCHAR(500) NOT NULL,
            file_size INTEGER,
            uploaded_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_invoice_documents_invoice FOREIGN KEY (invoice_id) 
                REFERENCES services.invoices(id) ON DELETE CASCADE,
            CONSTRAINT fk_invoice_documents_user FOREIGN KEY (uploaded_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );

        COMMENT ON TABLE services.invoice_documents IS 'Documents attached to invoices';
        RAISE NOTICE 'Invoice documents table created';
    END IF;
END $$;