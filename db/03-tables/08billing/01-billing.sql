DO $$
BEGIN
    -- Tariffs table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'tariffs'
    ) THEN
        CREATE TABLE billing.tariffs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            price DECIMAL(10,2) NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE billing.tariffs IS 'Tariff plans catalog';
        RAISE NOTICE 'Tariffs table created';
    END IF;

    -- Object tariffs table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'object_tariffs'
    ) THEN
        CREATE TABLE billing.object_tariffs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            object_id UUID NOT NULL,
            tariff_id UUID NOT NULL,
            effective_from DATE NOT NULL,
            effective_to DATE,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_object_tariffs_object FOREIGN KEY (object_id) 
                REFERENCES wialon.objects(id) ON DELETE CASCADE,
            CONSTRAINT fk_object_tariffs_tariff FOREIGN KEY (tariff_id) 
                REFERENCES billing.tariffs(id),
            CONSTRAINT fk_object_tariffs_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );

        COMMENT ON TABLE billing.object_tariffs IS 'Tariffs assigned to objects with effective dates';
        COMMENT ON COLUMN billing.object_tariffs.effective_to IS 'NULL means currently active';
        RAISE NOTICE 'Object tariffs table created';
    END IF;

    -- Payments table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'payments'
    ) THEN
        CREATE TABLE billing.payments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            payment_date DATE NOT NULL,
            payment_month INTEGER NOT NULL,
            payment_year INTEGER NOT NULL,
            payment_type VARCHAR(50) DEFAULT 'regular',
            notes TEXT,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_payments_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id),
            CONSTRAINT fk_payments_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_payment_month CHECK (payment_month BETWEEN 1 AND 12),
            CONSTRAINT chk_payment_year CHECK (payment_year BETWEEN 2000 AND 2100),
            CONSTRAINT chk_payment_type CHECK (payment_type IN ('regular', 'advance', 'debt', 'adjustment'))
        );

        COMMENT ON TABLE billing.payments IS 'Client payments';
        RAISE NOTICE 'Payments table created';
    END IF;

    -- Object payment records
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'object_payment_records'
    ) THEN
        CREATE TABLE billing.object_payment_records (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            object_id UUID NOT NULL,
            payment_id UUID NOT NULL,
            tariff_id UUID NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            billing_month INTEGER NOT NULL,
            billing_year INTEGER NOT NULL,
            status VARCHAR(50) DEFAULT 'paid',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_object_payments_object FOREIGN KEY (object_id) 
                REFERENCES wialon.objects(id) ON DELETE CASCADE,
            CONSTRAINT fk_object_payments_payment FOREIGN KEY (payment_id) 
                REFERENCES billing.payments(id) ON DELETE CASCADE,
            CONSTRAINT fk_object_payments_tariff FOREIGN KEY (tariff_id) 
                REFERENCES billing.tariffs(id),
            CONSTRAINT chk_billing_month CHECK (billing_month BETWEEN 1 AND 12),
            CONSTRAINT chk_billing_year CHECK (billing_year BETWEEN 2000 AND 2100),
            CONSTRAINT chk_payment_status CHECK (status IN ('paid', 'partial', 'pending', 'overdue'))
        );

        COMMENT ON TABLE billing.object_payment_records IS 'Payment records for each object';
        RAISE NOTICE 'Object payment records table created';
    END IF;
END $$;