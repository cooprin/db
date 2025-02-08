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

        -- Grant all existing permissions to admin role
        INSERT INTO auth.role_permissions (role_id, permission_id)
        SELECT admin_role_id, p.id
        FROM auth.permissions p
        WHERE NOT EXISTS (
            SELECT 1 FROM auth.role_permissions
            WHERE role_id = admin_role_id 
            AND permission_id = p.id
        );

        -- Log admin user creation
        INSERT INTO audit.audit_logs (
            user_id,
            action_type,
            entity_type,
            entity_id,
            new_values,
            ip_address
        ) VALUES (
            admin_user_id,
            'create',
            'auth.users',
            admin_user_id,
            jsonb_build_object(
                'email', 'cooprin@gmail.com',
                'first_name', 'Roman',
                'last_name', 'Tsyupryk',
                'is_active', true
            ),
            '127.0.0.1'
        );
    END IF;
END $$;