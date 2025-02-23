DO $$
BEGIN
    -- Warehouses table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'warehouses' AND table_name = 'warehouses'
    ) THEN
        CREATE TABLE warehouses.warehouses (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            address TEXT,
            description TEXT,
            responsible_person_id UUID NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE warehouses.warehouses IS 'Warehouses list';
        RAISE NOTICE 'Warehouses table created';
    END IF;

-- Stock table
IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'warehouses' AND table_name = 'stock'
) THEN
    CREATE TABLE warehouses.stock (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        warehouse_id UUID NOT NULL,
        product_id UUID NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,  -- змінено DEFAULT на 1
        price DECIMAL(10,2),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT stock_warehouse_product_unique UNIQUE(warehouse_id, product_id)
    );
    
    COMMENT ON TABLE warehouses.stock IS 'Current stock in warehouses';
    RAISE NOTICE 'Stock table created';
END IF;

    -- Stock movements table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'warehouses' AND table_name = 'stock_movements'
    ) THEN
        CREATE TABLE warehouses.stock_movements (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_id UUID NOT NULL,
            from_warehouse_id UUID,
            to_warehouse_id UUID,
            quantity INTEGER NOT NULL,
            type VARCHAR(50) NOT NULL,
            wialon_object_id UUID,
            warranty_change_days INTEGER,
            comment TEXT,
            created_by UUID NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        COMMENT ON TABLE warehouses.stock_movements IS 'History of stock movements';
        RAISE NOTICE 'Stock movements table created';
    END IF;

    -- Add foreign key constraints
    PERFORM core.add_constraint_if_not_exists(
        'warehouses.warehouses',
        'fk_warehouses_responsible_person',
        'FOREIGN KEY (responsible_person_id) REFERENCES auth.users(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock',
        'fk_stock_warehouse',
        'FOREIGN KEY (warehouse_id) REFERENCES warehouses.warehouses(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock',
        'fk_stock_product',
        'FOREIGN KEY (product_id) REFERENCES products.products(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock_movements',
        'fk_movements_product',
        'FOREIGN KEY (product_id) REFERENCES products.products(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock_movements',
        'fk_movements_from_warehouse',
        'FOREIGN KEY (from_warehouse_id) REFERENCES warehouses.warehouses(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock_movements',
        'fk_movements_to_warehouse',
        'FOREIGN KEY (to_warehouse_id) REFERENCES warehouses.warehouses(id)'
    );

    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock_movements',
        'fk_movements_created_by',
        'FOREIGN KEY (created_by) REFERENCES auth.users(id)'
    );

    -- Add movement types constraint
    PERFORM core.add_constraint_if_not_exists(
        'warehouses.stock_movements',
        'chk_movement_type',
        'CHECK (type IN (''transfer'', ''install'', ''uninstall'', ''repair_send'', ''repair_return'', ''write_off'', ''warranty_change''))'
    );

END $$;