DO $$
BEGIN
    -- Manufacturers table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'manufacturers'
    ) THEN
        CREATE TABLE products.manufacturers (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE products.manufacturers IS 'Manufacturers catalog';
        RAISE NOTICE 'Manufacturers table created';
    END IF;

    -- Suppliers table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'suppliers'
    ) THEN
        CREATE TABLE products.suppliers (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            contact_person VARCHAR(255),
            phone VARCHAR(50),
            email VARCHAR(255),
            address TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE products.suppliers IS 'Suppliers catalog';
        RAISE NOTICE 'Suppliers table created';
    END IF;

    -- Models table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'models'
    ) THEN
        CREATE TABLE products.models (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            manufacturer_id UUID NOT NULL,
            image_url TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE products.models IS 'Product models catalog';
        RAISE NOTICE 'Models table created';
    END IF;

    -- Products table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'products'
    ) THEN
        CREATE TABLE products.products (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            sku VARCHAR(255) NOT NULL,
            model_id UUID NOT NULL,
            supplier_id UUID NOT NULL,
            product_type_id UUID NOT NULL,
            current_status VARCHAR(50) DEFAULT 'in_stock',
            current_object_id UUID,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT products_sku_unique UNIQUE(sku)
        );
        
        COMMENT ON TABLE products.products IS 'Products catalog';
        RAISE NOTICE 'Products table created';
    END IF;

    -- Add foreign key constraints
    PERFORM core.add_constraint_if_not_exists(
        'products.models',
        'fk_models_manufacturer',
        'FOREIGN KEY (manufacturer_id) REFERENCES products.manufacturers(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'products.products',
        'fk_products_model',
        'FOREIGN KEY (model_id) REFERENCES products.models(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'products.products',
        'fk_products_supplier',
        'FOREIGN KEY (supplier_id) REFERENCES products.suppliers(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'products.products',
        'fk_products_type',
        'FOREIGN KEY (product_type_id) REFERENCES products.product_types(id)'
    );

    -- Status constraint
    PERFORM core.add_constraint_if_not_exists(
        'products.products',
        'chk_products_status',
        'CHECK (current_status IN (''in_stock'', ''installed'', ''in_repair'', ''written_off''))'
    );

END $$;