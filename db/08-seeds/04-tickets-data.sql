-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert initial ticket categories with translation keys
DO $$
BEGIN
    INSERT INTO tickets.ticket_categories (name, description, color, icon, sort_order)
    SELECT * FROM (VALUES
        ('tickets.categories.technical_support', 'tickets.categories.technical_support_desc', '#007bff', 'support_agent', 10),
        ('tickets.categories.hardware_issues', 'tickets.categories.hardware_issues_desc', '#dc3545', 'hardware', 20),
        ('tickets.categories.configuration', 'tickets.categories.configuration_desc', '#28a745', 'settings', 30),
        ('tickets.categories.billing_payment', 'tickets.categories.billing_payment_desc', '#ffc107', 'payment', 40),
        ('tickets.categories.system_access', 'tickets.categories.system_access_desc', '#6f42c1', 'login', 50),
        ('tickets.categories.other', 'tickets.categories.other_desc', '#6c757d', 'help', 100)
    ) AS v (name, description, color, icon, sort_order)
    WHERE NOT EXISTS (
        SELECT 1 FROM tickets.ticket_categories LIMIT 1
    );

    RAISE NOTICE 'Initial ticket categories with translation keys inserted';
END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';