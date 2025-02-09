-- Create or replace views
DO $$
BEGIN
    -- User details view with roles and permissions
    DROP VIEW IF EXISTS auth.view_users_with_roles;
    CREATE VIEW auth.view_users_with_roles AS
    SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.phone,
        u.avatar_url,
        u.is_active,
        u.last_login,
        array_agg(DISTINCT r.name) as role_names,
        array_agg(DISTINCT p.code) as permissions,
        u.created_at,
        u.updated_at
    FROM auth.users u
    LEFT JOIN auth.user_roles ur ON u.id = ur.user_id
    LEFT JOIN auth.roles r ON ur.role_id = r.id
    LEFT JOIN auth.role_permissions rp ON r.id = rp.role_id
    LEFT JOIN auth.permissions p ON rp.permission_id = p.id
    GROUP BY 
        u.id, u.email, u.first_name, u.last_name,
        u.phone, u.avatar_url, u.is_active, u.last_login,
        u.created_at, u.updated_at;

    COMMENT ON VIEW auth.view_users_with_roles IS 'Detailed user information including roles and permissions';

    -- Resources with available actions view
    DROP VIEW IF EXISTS core.view_resources_with_actions;
    CREATE VIEW core.view_resources_with_actions AS
    SELECT 
        r.id,
        r.name,
        r.code,
        r.type,
        r.metadata,
        array_agg(DISTINCT a.code) as action_codes,
        array_agg(DISTINCT jsonb_build_object(
            'action_id', a.id,
            'action_code', a.code,
            'is_default', ra.is_default
        )) as actions,
        r.created_at,
        r.updated_at
    FROM core.resources r
    LEFT JOIN core.resource_actions ra ON r.id = ra.resource_id
    LEFT JOIN core.actions a ON ra.action_id = a.id
    GROUP BY 
        r.id, r.name, r.code, r.type, r.metadata,
        r.created_at, r.updated_at;

    COMMENT ON VIEW core.view_resources_with_actions IS 'Resources with their available actions';

    -- User permissions view
    DROP VIEW IF EXISTS auth.view_user_permissions;
    CREATE VIEW auth.view_user_permissions AS
    SELECT DISTINCT
        u.id as user_id,
        u.email,
        p.id as permission_id,
        p.code as permission_code,
        p.name as permission_name,
        r.id as role_id,
        r.name as role_name,
        pg.name as permission_group,
        res.code as resource_code,
        res.type as resource_type
    FROM auth.users u
    JOIN auth.user_roles ur ON u.id = ur.user_id
    JOIN auth.roles r ON ur.role_id = r.id
    JOIN auth.role_permissions rp ON r.id = rp.role_id
    JOIN auth.permissions p ON rp.permission_id = p.id
    LEFT JOIN auth.permission_groups pg ON p.group_id = pg.id
    LEFT JOIN core.resources res ON p.resource_id = res.id;

    COMMENT ON VIEW auth.view_user_permissions IS 'Detailed user permissions with related information';

    -- Audit logs view with user details
    DROP VIEW IF EXISTS audit.view_audit_logs_with_users;
    CREATE VIEW audit.view_audit_logs_with_users AS
    SELECT 
        al.id,
        al.action_type,
        al.entity_type,
        al.entity_id,
        al.old_values,
        al.new_values,
        al.ip_address,
        al.created_at,
        u.email as user_email,
        u.first_name || ' ' || u.last_name as user_full_name
    FROM audit.audit_logs al
    LEFT JOIN auth.users u ON al.user_id = u.id;

    COMMENT ON VIEW audit.view_audit_logs_with_users IS 'Audit logs with user details';
END $$;