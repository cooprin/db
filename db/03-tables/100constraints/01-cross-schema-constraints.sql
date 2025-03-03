-- Додавання міжсхемних зовнішніх ключів
DO $$
BEGIN
    -- Додаємо зовнішній ключ для services.invoices.payment_id
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'payments'
    ) AND 
       EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'services' AND table_name = 'invoices'
    ) AND 
       NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE table_schema = 'services' AND table_name = 'invoices' AND column_name = 'payment_id'
        AND constraint_name = 'fk_invoices_payment'
    ) THEN
        ALTER TABLE services.invoices 
        ADD CONSTRAINT fk_invoices_payment 
        FOREIGN KEY (payment_id) 
        REFERENCES billing.payments(id);
        
        RAISE NOTICE 'Foreign key constraint from services.invoices to billing.payments added';
    END IF;

    -- Додаємо зовнішній ключ для billing.object_tariffs.object_id
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon' AND table_name = 'objects'
    ) AND 
       EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'object_tariffs'
    ) AND 
       NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE table_schema = 'billing' AND table_name = 'object_tariffs' AND column_name = 'object_id'
        AND constraint_name = 'fk_object_tariffs_object'
    ) THEN
        ALTER TABLE billing.object_tariffs 
        ADD CONSTRAINT fk_object_tariffs_object 
        FOREIGN KEY (object_id) 
        REFERENCES wialon.objects(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint from billing.object_tariffs to wialon.objects added';
    END IF;

    -- Додаємо зовнішній ключ для billing.object_payment_records.object_id
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon' AND table_name = 'objects'
    ) AND 
       EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'billing' AND table_name = 'object_payment_records'
    ) AND 
       NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE table_schema = 'billing' AND table_name = 'object_payment_records' AND column_name = 'object_id'
        AND constraint_name = 'fk_object_payments_object'
    ) THEN
        ALTER TABLE billing.object_payment_records 
        ADD CONSTRAINT fk_object_payments_object 
        FOREIGN KEY (object_id) 
        REFERENCES wialon.objects(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint from billing.object_payment_records to wialon.objects added';
    END IF;
END $$;