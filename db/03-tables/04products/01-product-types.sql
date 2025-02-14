DO $$
BEGIN
    -- Product types table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'product_types'
    ) THEN
        CREATE TABLE products.product_types (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(50) NOT NULL UNIQUE,
            description TEXT,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE products.product_types IS 'Product types catalog';
        RAISE NOTICE 'Product types table created';
    END IF;

    -- Product type characteristics table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'product_type_characteristics'
    ) THEN
        CREATE TABLE products.product_type_characteristics (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_type_id UUID NOT NULL,
            name VARCHAR(255) NOT NULL,
            code VARCHAR(50) NOT NULL,
            type VARCHAR(50) NOT NULL, -- string, number, date, boolean, select
            is_required BOOLEAN DEFAULT false,
            default_value TEXT,
            validation_rules JSONB,
            options JSONB, -- для типу select: масив можливих значень
            ordering INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(product_type_id, code)
        );
        
        COMMENT ON TABLE products.product_type_characteristics IS 'Product type characteristics definition';
        RAISE NOTICE 'Product type characteristics table created';
    END IF;

    -- Product characteristic values table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'products' AND table_name = 'product_characteristic_values'
    ) THEN
        CREATE TABLE products.product_characteristic_values (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_id UUID NOT NULL,
            characteristic_id UUID NOT NULL,
            value TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(product_id, characteristic_id)
        );
        
        COMMENT ON TABLE products.product_characteristic_values IS 'Product characteristic values';
        RAISE NOTICE 'Product characteristic values table created';
    END IF;

    -- Add foreign key constraints
    PERFORM core.add_constraint_if_not_exists(
        'products.product_type_characteristics',
        'fk_characteristic_product_type',
        'FOREIGN KEY (product_type_id) REFERENCES products.product_types(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'products.product_characteristic_values',
        'fk_value_product',
        'FOREIGN KEY (product_id) REFERENCES products.products(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'products.product_characteristic_values',
        'fk_value_characteristic',
        'FOREIGN KEY (characteristic_id) REFERENCES products.product_type_characteristics(id)'
    );

    -- Add type validation constraint
    PERFORM core.add_constraint_if_not_exists(
        'products.product_type_characteristics',
        'chk_characteristic_type',
        'CHECK (type IN (''string'', ''number'', ''date'', ''boolean'', ''select''))'
    );

END $$;