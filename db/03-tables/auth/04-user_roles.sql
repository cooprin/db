-- Create user roles table
DO $$
BEGIN
    -- User roles table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'user_roles'
    ) THEN
        CREATE TABLE auth.user_roles (
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            role_id UUID REFERENCES auth.roles(id) ON DELETE CASCADE,
            granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            granted_by UUID REFERENCES auth.users(id),
            PRIMARY KEY (user_id, role_id)
        );

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'auth' 
            AND tablename = 'user_roles' 
            AND indexname = 'user_roles_user_id_idx'
        ) THEN
            CREATE INDEX user_roles_user_id_idx ON auth.user_roles(user_id);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'auth' 
            AND tablename = 'user_roles' 
            AND indexname = 'user_roles_role_id_idx'
        ) THEN
            CREATE INDEX user_roles_role_id_idx ON auth.user_roles(role_id);
        END IF;

        COMMENT ON TABLE auth.user_roles IS 'Junction table between users and roles';
        COMMENT ON COLUMN auth.user_roles.granted_by IS 'User who granted the role';
    END IF;
END $$;