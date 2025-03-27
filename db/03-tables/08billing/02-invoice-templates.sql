DO $$
BEGIN
    -- Invoice templates table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'invoice_templates'
    ) THEN
        CREATE TABLE billing.invoice_templates (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL UNIQUE,
            html_template TEXT NOT NULL,
            css_styles TEXT,
            description TEXT,
            is_default BOOLEAN DEFAULT false,
            is_active BOOLEAN DEFAULT true,
            metadata JSONB,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_invoice_templates_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );
        
        COMMENT ON TABLE billing.invoice_templates IS 'Templates for invoice generation';
        RAISE NOTICE 'Invoice templates table created';
    END IF;

    -- Add column to invoices table to link to template if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'services' 
        AND table_name = 'invoices' 
        AND column_name = 'template_id'
    ) THEN
        ALTER TABLE services.invoices 
        ADD COLUMN template_id UUID,
        ADD CONSTRAINT fk_invoices_template 
        FOREIGN KEY (template_id) 
        REFERENCES billing.invoice_templates(id);
        
        RAISE NOTICE 'Added template_id column to services.invoices table';
    END IF;
END $$;