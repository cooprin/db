-- Create additional indexes for performance optimization
DO $$
BEGIN
    -- Auth schema indexes
    -- Users table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'users' 
        AND indexname = 'idx_users_email_lower'
    ) THEN
        CREATE INDEX idx_users_email_lower ON auth.users (lower(email));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'users' 
        AND indexname = 'idx_users_last_login'
    ) THEN
        CREATE INDEX idx_users_last_login ON auth.users(last_login);
    END IF;

    -- Permissions table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'permissions' 
        AND indexname = 'idx_permissions_group_id'
    ) THEN
        CREATE INDEX idx_permissions_group_id ON auth.permissions(group_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'auth' 
        AND tablename = 'permissions' 
        AND indexname = 'idx_permissions_resource_id'
    ) THEN
        CREATE INDEX idx_permissions_resource_id ON auth.permissions(resource_id);
    END IF;

    -- Core schema indexes
    -- Resources table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'core' 
        AND tablename = 'resources' 
        AND indexname = 'idx_resources_type_code'
    ) THEN
        CREATE INDEX idx_resources_type_code ON core.resources(type, code);
    END IF;

    -- Actions table indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'core' 
        AND tablename = 'actions' 
        AND indexname = 'idx_actions_code_lower'
    ) THEN
        CREATE INDEX idx_actions_code_lower ON core.actions(lower(code));
    END IF;

    -- Audit schema indexes
    -- Additional audit_logs indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'audit' 
        AND tablename = 'audit_logs' 
        AND indexname = 'idx_audit_logs_created_at_action'
    ) THEN
        CREATE INDEX idx_audit_logs_created_at_action 
        ON audit.audit_logs(created_at, action_type);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'audit' 
        AND tablename = 'audit_logs' 
        AND indexname = 'idx_audit_logs_entity_created'
    ) THEN
        CREATE INDEX idx_audit_logs_entity_created 
        ON audit.audit_logs(entity_type, entity_id, created_at);
    END IF;

    -- Products schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'products' 
        AND indexname = 'idx_products_sku'
    ) THEN
        CREATE INDEX idx_products_sku ON products.products(sku);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'products' 
        AND indexname = 'idx_products_model'
    ) THEN
        CREATE INDEX idx_products_model ON products.products(model_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'products' 
        AND indexname = 'idx_products_supplier'
    ) THEN
        CREATE INDEX idx_products_supplier ON products.products(supplier_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'products' 
        AND indexname = 'idx_products_status'
    ) THEN
        CREATE INDEX idx_products_status ON products.products(current_status);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'models' 
        AND indexname = 'idx_models_manufacturer'
    ) THEN
        CREATE INDEX idx_models_manufacturer ON products.models(manufacturer_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' AND tablename = 'model_files' AND indexname = 'idx_model_files_model_id'
    ) THEN
        CREATE INDEX idx_model_files_model_id ON products.model_files(model_id);
        RAISE NOTICE 'Index on model_files(model_id) created';
    END IF;

    -- Product types indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'product_types' 
        AND indexname = 'idx_product_types_code'
    ) THEN
        CREATE INDEX idx_product_types_code ON products.product_types(code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'product_type_characteristics' 
        AND indexname = 'idx_characteristics_type'
    ) THEN
        CREATE INDEX idx_characteristics_type ON products.product_type_characteristics(product_type_id, code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'product_characteristic_values' 
        AND indexname = 'idx_characteristic_values_product'
    ) THEN
        CREATE INDEX idx_characteristic_values_product ON products.product_characteristic_values(product_id);
    END IF;
    -- Add index for models product type
IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE schemaname = 'products' 
    AND tablename = 'models' 
    AND indexname = 'idx_models_product_type'
) THEN
    CREATE INDEX idx_models_product_type ON products.models(product_type_id);
END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'product_characteristic_values' 
        AND indexname = 'idx_characteristic_values_characteristic'
    ) THEN
        CREATE INDEX idx_characteristic_values_characteristic ON products.product_characteristic_values(characteristic_id);
    END IF;

    -- Warehouses schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'warehouses' 
        AND tablename = 'stock' 
        AND indexname = 'idx_stock_warehouse_product'
    ) THEN
        CREATE INDEX idx_stock_warehouse_product ON warehouses.stock(warehouse_id, product_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'warehouses' 
        AND tablename = 'stock_movements' 
        AND indexname = 'idx_movements_created_at'
    ) THEN
        CREATE INDEX idx_movements_created_at ON warehouses.stock_movements(created_at DESC);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'warehouses' 
        AND tablename = 'stock_movements' 
        AND indexname = 'idx_movements_product'
    ) THEN
        CREATE INDEX idx_movements_product ON warehouses.stock_movements(product_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'warehouses' 
        AND tablename = 'stock_movements' 
        AND indexname = 'idx_movements_type'
    ) THEN
        CREATE INDEX idx_movements_type ON warehouses.stock_movements(type);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'warehouses' 
        AND tablename = 'stock_movements' 
        AND indexname = 'idx_movements_warehouses'
    ) THEN
        CREATE INDEX idx_movements_warehouses 
        ON warehouses.stock_movements(from_warehouse_id, to_warehouse_id);
    END IF;

    -- Characteristic types index
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'products' 
        AND tablename = 'characteristic_types' 
        AND indexname = 'idx_characteristic_types_value'
    ) THEN
        CREATE INDEX idx_characteristic_types_value ON products.characteristic_types(value);
    END IF;

    -- Clients schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'clients' 
        AND tablename = 'clients' 
        AND indexname = 'idx_clients_name'
    ) THEN
        CREATE INDEX idx_clients_name ON clients.clients(name);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'clients' 
        AND tablename = 'clients' 
        AND indexname = 'idx_clients_wialon_id'
    ) THEN
        CREATE INDEX idx_clients_wialon_id ON clients.clients(wialon_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'clients' 
        AND tablename = 'clients' 
        AND indexname = 'idx_clients_wialon_username'
    ) THEN
        CREATE INDEX idx_clients_wialon_username ON clients.clients(wialon_username);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'clients' 
        AND tablename = 'client_documents' 
        AND indexname = 'idx_client_documents_client'
    ) THEN
        CREATE INDEX idx_client_documents_client ON clients.client_documents(client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'clients' 
        AND tablename = 'contacts' 
        AND indexname = 'idx_contacts_client'
    ) THEN
        CREATE INDEX idx_contacts_client ON clients.contacts(client_id);
    END IF;

    -- Wialon schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon' 
        AND tablename = 'objects' 
        AND indexname = 'idx_wialon_objects_client'
    ) THEN
        CREATE INDEX idx_wialon_objects_client ON wialon.objects(client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon' 
        AND tablename = 'objects' 
        AND indexname = 'idx_wialon_objects_status'
    ) THEN
        CREATE INDEX idx_wialon_objects_status ON wialon.objects(status);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon' 
        AND tablename = 'object_ownership_history' 
        AND indexname = 'idx_ownership_history_object'
    ) THEN
        CREATE INDEX idx_ownership_history_object ON wialon.object_ownership_history(object_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon' 
        AND tablename = 'object_ownership_history' 
        AND indexname = 'idx_ownership_history_client'
    ) THEN
        CREATE INDEX idx_ownership_history_client ON wialon.object_ownership_history(client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon' 
        AND tablename = 'object_ownership_history' 
        AND indexname = 'idx_ownership_history_dates'
    ) THEN
        CREATE INDEX idx_ownership_history_dates ON wialon.object_ownership_history(start_date, end_date);
    END IF;

    -- Billing schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'billing' 
        AND tablename = 'object_tariffs' 
        AND indexname = 'idx_object_tariffs_object'
    ) THEN
        CREATE INDEX idx_object_tariffs_object ON billing.object_tariffs(object_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'billing' 
        AND tablename = 'object_tariffs' 
        AND indexname = 'idx_object_tariffs_dates'
    ) THEN
        CREATE INDEX idx_object_tariffs_dates ON billing.object_tariffs(effective_from, effective_to);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'billing' 
        AND tablename = 'payments' 
        AND indexname = 'idx_payments_client'
    ) THEN
        CREATE INDEX idx_payments_client ON billing.payments(client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'billing' 
        AND tablename = 'payments' 
        AND indexname = 'idx_payments_period'
    ) THEN
        CREATE INDEX idx_payments_period ON billing.payments(payment_year, payment_month);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'billing' 
        AND tablename = 'object_payment_records' 
        AND indexname = 'idx_object_payments_payment'
    ) THEN
        CREATE INDEX idx_object_payments_payment ON billing.object_payment_records(payment_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'billing' 
        AND tablename = 'object_payment_records' 
        AND indexname = 'idx_object_payments_object'
    ) THEN
        CREATE INDEX idx_object_payments_object ON billing.object_payment_records(object_id);
    END IF;

    -- Services schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'services' 
        AND tablename = 'client_services' 
        AND indexname = 'idx_client_services_client'
    ) THEN
        CREATE INDEX idx_client_services_client ON services.client_services(client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'services' 
        AND tablename = 'client_services' 
        AND indexname = 'idx_client_services_service'
    ) THEN
        CREATE INDEX idx_client_services_service ON services.client_services(service_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'services' 
        AND tablename = 'client_services' 
        AND indexname = 'idx_client_services_dates'
    ) THEN
        CREATE INDEX idx_client_services_dates ON services.client_services(start_date, end_date);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'services' 
        AND tablename = 'invoices' 
        AND indexname = 'idx_invoices_client'
    ) THEN
        CREATE INDEX idx_invoices_client ON services.invoices(client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'services' 
        AND tablename = 'invoices' 
        AND indexname = 'idx_invoices_period'
    ) THEN
        CREATE INDEX idx_invoices_period ON services.invoices(billing_year, billing_month);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'services' 
        AND tablename = 'invoice_items' 
        AND indexname = 'idx_invoice_items_invoice'
    ) THEN
        CREATE INDEX idx_invoice_items_invoice ON services.invoice_items(invoice_id);
    END IF;

    -- Company schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'company' 
        AND tablename = 'bank_accounts' 
        AND indexname = 'idx_bank_accounts_organization'
    ) THEN
        CREATE INDEX idx_bank_accounts_organization ON company.bank_accounts(organization_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'company' 
        AND tablename = 'bank_accounts' 
        AND indexname = 'idx_bank_accounts_currency'
    ) THEN
        CREATE INDEX idx_bank_accounts_currency ON company.bank_accounts(currency);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'company' 
        AND tablename = 'legal_documents' 
        AND indexname = 'idx_legal_documents_organization'
    ) THEN
        CREATE INDEX idx_legal_documents_organization ON company.legal_documents(organization_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'company' 
        AND tablename = 'legal_documents' 
        AND indexname = 'idx_legal_documents_dates'
    ) THEN
        CREATE INDEX idx_legal_documents_dates ON company.legal_documents(effective_date, expiry_date);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'company' 
        AND tablename = 'email_templates' 
        AND indexname = 'idx_email_templates_code'
    ) THEN
        CREATE INDEX idx_email_templates_code ON company.email_templates(code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'company' 
        AND tablename = 'system_settings' 
        AND indexname = 'idx_system_settings_category'
    ) THEN
        CREATE INDEX idx_system_settings_category ON company.system_settings(category);
    END IF;

    -- Wialon_sync schema indexes
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon_sync' 
        AND tablename = 'sync_sessions' 
        AND indexname = 'idx_sync_sessions_status'
    ) THEN
        CREATE INDEX idx_sync_sessions_status ON wialon_sync.sync_sessions(status);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon_sync' 
        AND tablename = 'sync_sessions' 
        AND indexname = 'idx_sync_sessions_created_by'
    ) THEN
        CREATE INDEX idx_sync_sessions_created_by ON wialon_sync.sync_sessions(created_by);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon_sync' 
        AND tablename = 'sync_discrepancies' 
        AND indexname = 'idx_sync_discrepancies_type_status'
    ) THEN
        CREATE INDEX idx_sync_discrepancies_type_status ON wialon_sync.sync_discrepancies(discrepancy_type, status);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon_sync' 
        AND tablename = 'sync_discrepancies' 
        AND indexname = 'idx_sync_discrepancies_system_client'
    ) THEN
        CREATE INDEX idx_sync_discrepancies_system_client ON wialon_sync.sync_discrepancies(system_client_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon_sync' 
        AND tablename = 'sync_discrepancies' 
        AND indexname = 'idx_sync_discrepancies_system_object'
    ) THEN
        CREATE INDEX idx_sync_discrepancies_system_object ON wialon_sync.sync_discrepancies(system_object_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'wialon_sync' 
        AND tablename = 'sync_logs' 
        AND indexname = 'idx_sync_logs_level_created'
    ) THEN
        CREATE INDEX idx_sync_logs_level_created ON wialon_sync.sync_logs(log_level, created_at);
    END IF;


    -- Grant privileges
    -- Auth schema
    GRANT USAGE ON SCHEMA auth TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO current_user;

    -- Core schema
    GRANT USAGE ON SCHEMA core TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core TO current_user;

    -- Audit schema
    GRANT USAGE ON SCHEMA audit TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO current_user;

    -- Products schema
    GRANT USAGE ON SCHEMA products TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA products TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA products TO current_user;

    -- Warehouses schema
    GRANT USAGE ON SCHEMA warehouses TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA warehouses TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA warehouses TO current_user;

     -- Clients schema
    GRANT USAGE ON SCHEMA clients TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA clients TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA clients TO current_user;

    -- Wialon schema
    GRANT USAGE ON SCHEMA wialon TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA wialon TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wialon TO current_user;

    -- Billing schema
    GRANT USAGE ON SCHEMA billing TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA billing TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA billing TO current_user;

    -- Services schema
    GRANT USAGE ON SCHEMA services TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA services TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA services TO current_user;

 -- Grant privileges for company schema
    GRANT USAGE ON SCHEMA company TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA company TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA company TO current_user;

    -- Grant privileges for wialon_sync schema
    GRANT USAGE ON SCHEMA wialon_sync TO current_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA wialon_sync TO current_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wialon_sync TO current_user;

END $$;