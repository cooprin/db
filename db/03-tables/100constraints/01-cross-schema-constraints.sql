-- Додавання міжсхемних зовнішніх ключів
DO $$
BEGIN
    -- Додаємо зовнішній ключ для services.invoices.payment_id, якщо обидві таблиці вже існують
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

    -- Додаємо інші міжсхемні зовнішні ключі, якщо потрібно
END $$;