-- Disable triggers temporarily for admin user creation
SET session_replication_role = 'replica';

-- Create default admin user and assign permissions
DO $$
DECLARE
    admin_role_id UUID;
    admin_user_id UUID;
BEGIN
    -- Get admin role id
    SELECT id INTO admin_role_id 
    FROM auth.roles 
    WHERE name = 'admin' 
    LIMIT 1;

    -- Create admin user if doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE email = 'cooprin@gmail.com'
    ) THEN
        INSERT INTO auth.users (
            email,
            password,
            first_name,
            last_name,
            is_active
        ) VALUES (
            'cooprin@gmail.com',
            '$2b$10$/8mFF08rYqKd20byMvGwquNb4JrxJ9eDjf8T8WAj1QQifWU6L0q0a',
            'Roman',
            'Tsyupryk',
            true
        ) RETURNING id INTO admin_user_id;

        -- Assign admin role to user
        INSERT INTO auth.user_roles (user_id, role_id)
        VALUES (admin_user_id, admin_role_id);
    END IF;
END $$;

-- Re-enable triggers after admin user creation
SET session_replication_role = 'origin';