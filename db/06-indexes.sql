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
END $$;