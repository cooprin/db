-- Create roles related tables
DO $$
BEGIN
    -- Roles table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'roles'
    ) THEN
        CREATE TABLE auth.roles (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(50) NOT NULL,
            description TEXT,
            is_system BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Додаємо унікальний індекс для name
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'auth' 
            AND tablename = 'roles' 
            AND indexname = 'roles_name_unique'
        ) THEN
            CREATE UNIQUE INDEX roles_name_unique ON auth.roles(name);
        END IF;

        -- Додаємо коментарі
        COMMENT ON TABLE auth.roles IS 'Roles table for storing user roles';
        COMMENT ON COLUMN auth.roles.name IS 'Unique role name';
        COMMENT ON COLUMN auth.roles.is_system IS 'Flag indicating if this is a system role that cannot be modified';
    END IF;

    -- Role permissions table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'role_permissions'
    ) THEN
        CREATE TABLE auth.role_permissions (
            role_id UUID REFERENCES auth.roles(id) ON DELETE CASCADE,
            permission_id UUID, -- Reference will be added after permissions table is created
            granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            granted_by UUID, -- Reference will be added after all tables are created
            PRIMARY KEY (role_id, permission_id)
        );

        COMMENT ON TABLE auth.role_permissions IS 'Junction table between roles and permissions';
    END IF;
END $$;