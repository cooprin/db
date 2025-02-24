DO $$
BEGIN
    -- 1. First create basic tables without foreign keys
    
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

    -- Таблиця типів характеристик
IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'products' AND table_name = 'characteristic_types'
) THEN
    CREATE TABLE products.characteristic_types (
        value VARCHAR(20) PRIMARY KEY,
        label VARCHAR(50) NOT NULL,
        description TEXT,
        validation JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Додаємо базові типи
    INSERT INTO products.characteristic_types (value, label, description, validation) VALUES
    ('string', 'Text', 'Text values', '{"maxLength": 255}'),
    ('number', 'Number', 'Numeric values', '{"min": 0, "max": 999999}'),
    ('date', 'Date', 'Date values', '{"min": "1900-01-01", "max": "2100-12-31"}'),
    ('boolean', 'Boolean', 'Yes/No values', '{"values": [true, false]}'),
    ('select', 'Select', 'Selection from predefined options', '{"minOptions": 1, "maxOptions": 50}');

    COMMENT ON TABLE products.characteristic_types IS 'Available characteristic types with validation rules';
    RAISE NOTICE 'Characteristic types table created and populated';
END IF;

-- Після цього модифікуємо таблицю product_type_characteristics
IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'products' AND table_name = 'product_type_characteristics'
) THEN
    CREATE TABLE products.product_type_characteristics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        product_type_id UUID NOT NULL,
        name VARCHAR(255) NOT NULL,
        code VARCHAR(50) NOT NULL,
        type VARCHAR(50) NOT NULL,
        is_required BOOLEAN DEFAULT false,
        default_value TEXT,
        validation_rules JSONB,
        options JSONB,
        ordering INTEGER DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(product_type_id, code),
        FOREIGN KEY (type) REFERENCES products.characteristic_types(value)
    );
    
    COMMENT ON TABLE products.product_type_characteristics IS 'Product type characteristics definition';
    RAISE NOTICE 'Product type characteristics table created';
END IF;

-- Таблиця кодів типів продуктів
IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'products' AND table_name = 'product_type_codes'
) THEN
    CREATE TABLE products.product_type_codes (
        value VARCHAR(10) PRIMARY KEY,
        label VARCHAR(100) NOT NULL,
        description TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    COMMENT ON TABLE products.product_type_codes IS 'Product type codes catalog';
    RAISE NOTICE 'Product type codes table created';
END IF;

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

    -- 2. Create tables that depend on manufacturers
    
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
        product_type_id UUID NOT NULL,  -- додано нове поле
        image_url TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE products.models IS 'Product models catalog';
    RAISE NOTICE 'Models table created';
END IF;

    -- Add foreign key for models
    PERFORM core.add_constraint_if_not_exists(
        'products.models',
        'fk_models_manufacturer',
        'FOREIGN KEY (manufacturer_id) REFERENCES products.manufacturers(id)'
    );
    -- Add foreign key for product type
PERFORM core.add_constraint_if_not_exists(
    'products.models',
    'fk_models_product_type',
    'FOREIGN KEY (product_type_id) REFERENCES products.product_types(id)'
);

    -- 3. Create products table that depends on models, suppliers, and product_types
    
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
            is_own BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT products_sku_unique UNIQUE(sku)
        );
        
        COMMENT ON TABLE products.products IS 'Products catalog';
        RAISE NOTICE 'Products table created';
    END IF;

    -- Add foreign keys for products
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

    -- Status constraint for products
    PERFORM core.add_constraint_if_not_exists(
        'products.products',
        'chk_products_status',
        'CHECK (current_status IN (''in_stock'', ''installed'', ''in_repair'', ''written_off''))'
    );
    -- Check product type matches model type
PERFORM core.add_constraint_if_not_exists(
    'products.products',
    'check_product_type_match',
    'CHECK (product_type_id = (SELECT product_type_id FROM products.models WHERE id = model_id))'
);

    -- 4. Create characteristics tables that depend on product_types
    
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
            type VARCHAR(50) NOT NULL,
            is_required BOOLEAN DEFAULT false,
            default_value TEXT,
            validation_rules JSONB,
            options JSONB,
            ordering INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(product_type_id, code)
        );
        
        COMMENT ON TABLE products.product_type_characteristics IS 'Product type characteristics definition';
        RAISE NOTICE 'Product type characteristics table created';
    END IF;

    -- 5. Create characteristic values table that depends on products and characteristics
    
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

    -- Add remaining foreign key constraints
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