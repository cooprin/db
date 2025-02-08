-- Create permissions related tables
DO $$
BEGIN
    -- Permission groups table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'permission_groups'
    ) THEN
        CREATE TABLE auth.permission_groups (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Додаємо унікальний індекс для name
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'auth' 
            AND tablename = 'permission_groups' 
            AND indexname = 'permission_groups_name_unique'
        ) THEN
            CREATE UNIQUE INDEX permission_groups_name_unique ON auth.permission_groups(name);
        END IF;

        COMMENT ON TABLE auth.permission_groups IS 'Groups for organizing permissions';
    END IF;

    -- Permissions table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'permissions'
    ) THEN
        CREATE TABLE auth.permissions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            group_id UUID REFERENCES auth.permission_groups(id),
            resource_id UUID, -- Reference will be added after resources table is created
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL,
            conditions JSONB DEFAULT '{}',
            is_system BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Додаємо унікальний індекс для code
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'auth' 
            AND tablename = 'permissions' 
            AND indexname = 'permissions_code_unique'
        ) THEN
            CREATE UNIQUE INDEX permissions_code_unique ON auth.permissions(code);
        END IF;

        COMMENT ON TABLE auth.permissions IS 'System permissions';
        COMMENT ON COLUMN auth.permissions.conditions IS 'Additional conditions for permission in JSONB format';
        COMMENT ON COLUMN auth.permissions.is_system IS 'Flag indicating if this is a system permission that cannot be modified';
    END IF;
END $$;