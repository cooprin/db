-- Create resources table
DO $$
BEGIN
    -- Resources table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'core' 
        AND tablename = 'resources'
    ) THEN
        CREATE TABLE core.resources (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL,
            type VARCHAR(50) NOT NULL,
            metadata JSONB DEFAULT '{}',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Додаємо унікальний індекс для code
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'core' 
            AND tablename = 'resources' 
            AND indexname = 'resources_code_unique'
        ) THEN
            CREATE UNIQUE INDEX resources_code_unique ON core.resources(code);
        END IF;

        -- Додаємо обмеження для типу ресурсу
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.constraint_column_usage 
            WHERE constraint_name = 'check_resource_type'
        ) THEN
            PERFORM core.add_constraint_if_not_exists(
                'core.resources',
                'check_resource_type',
                'CHECK (type IN (''table'', ''module'', ''function''))'
            );
        END IF;

        -- Додаємо індекс для типу, часто використовується у фільтрах
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'core' 
            AND tablename = 'resources' 
            AND indexname = 'resources_type_idx'
        ) THEN
            CREATE INDEX resources_type_idx ON core.resources(type);
        END IF;

        COMMENT ON TABLE core.resources IS 'System resources that can be managed';
        COMMENT ON COLUMN core.resources.code IS 'Unique identifier code for the resource';
        COMMENT ON COLUMN core.resources.type IS 'Type of resource: table, module, or function';
        COMMENT ON COLUMN core.resources.metadata IS 'Additional resource properties in JSONB format';
    END IF;

    -- Add foreign key to permissions table if it exists
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'permissions'
    ) AND NOT EXISTS (
        SELECT 1 
        FROM information_schema.constraint_column_usage 
        WHERE constraint_name = 'permissions_resource_id_fkey'
    ) THEN
        ALTER TABLE auth.permissions 
        ADD CONSTRAINT permissions_resource_id_fkey 
        FOREIGN KEY (resource_id) 
        REFERENCES core.resources(id) ON DELETE CASCADE;
    END IF;
END $$;