-- Grant privileges to current user
DO $$
BEGIN
    -- Grant schema permissions
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA auth TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA core TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA audit TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA products TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA warehouses TO %I', current_user);

    -- Grant table permissions
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA products TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA warehouses TO %I', current_user);

    -- Grant sequence permissions
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA products TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA warehouses TO %I', current_user);

    -- Grant execute permissions on core functions
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA core TO %I', current_user);
END $$;

-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert initial data
DO $$
BEGIN
    -- Insert default resources if they don't exist
    INSERT INTO core.resources (name, code, type) 
    SELECT * FROM (VALUES
        ('Users', 'users', 'table'),
        ('Roles', 'roles', 'table'),
        ('Permissions', 'permissions', 'module'),
        ('Resources', 'resources', 'module'),
        ('Audit', 'audit', 'module'),
        ('System', 'system', 'module'),
        ('Products', 'products', 'module'),
    ('Manufacturers', 'manufacturers', 'table'),
    ('Suppliers', 'suppliers', 'table'),
    ('Warehouses', 'warehouses', 'module'),
    ('Stock', 'stock', 'module')
    ) AS v (name, code, type)
    WHERE NOT EXISTS (
        SELECT 1 FROM core.resources
        WHERE code = v.code
    );

    -- Insert default actions if they don't exist
    INSERT INTO core.actions (name, code, description)
    SELECT * FROM (VALUES
        ('Create', 'create', 'Permission to create new records'),
        ('Read', 'read', 'Permission to read records'),
        ('Update', 'update', 'Permission to update records'),
        ('Delete', 'delete', 'Permission to delete records'),
        ('Manage', 'manage', 'Full management permission')
    ) AS v (name, code, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM core.actions
        WHERE code = v.code
    );

    -- Insert default resource actions
    INSERT INTO core.resource_actions (resource_id, action_id, is_default)
    SELECT r.id, a.id, true
    FROM core.resources r
    CROSS JOIN core.actions a
    WHERE NOT EXISTS (
        SELECT 1 FROM core.resource_actions
        WHERE resource_id = r.id AND action_id = a.id
    );

    -- Insert permission groups if they don't exist
    INSERT INTO auth.permission_groups (name, description)
    SELECT * FROM (VALUES
        ('User Management', 'Permissions related to user management'),
        ('Role Management', 'Permissions related to role management'),
        ('Permission Management', 'Permissions related to permission management'),
        ('Resource Management', 'Permissions related to resource management'),
        ('System Management', 'System-level permissions'),
            ('Product Management', 'Permissions related to product management'),
    ('Warehouse Management', 'Permissions related to warehouse management')
    ) AS v (name, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permission_groups
        WHERE name = v.name
    );

    -- Insert default permissions
    WITH permission_data AS (
        SELECT 
            pg.id as group_id,
            r.id as resource_id,
            r.code as resource_code,
            a.code as action_code
        FROM auth.permission_groups pg
        CROSS JOIN core.resources r
        CROSS JOIN core.actions a
        WHERE 
            (pg.name = 'User Management' AND r.code = 'users') OR
            (pg.name = 'Role Management' AND r.code = 'roles') OR
            (pg.name = 'Permission Management' AND r.code = 'permissions') OR
            (pg.name = 'Resource Management' AND r.code = 'resources') OR
            (pg.name = 'System Management' AND r.code IN ('audit', 'system')) OR
            (pg.name = 'Product Management' AND r.code IN ('products', 'manufacturers', 'suppliers')) OR
        (pg.name = 'Warehouse Management' AND r.code IN ('warehouses', 'stock'))
    )
    INSERT INTO auth.permissions (
        group_id, 
        resource_id, 
        name, 
        code, 
        is_system
    )
    SELECT 
        pd.group_id,
        pd.resource_id,
        pd.resource_code || '.' || pd.action_code as name,
        pd.resource_code || '.' || pd.action_code as code,
        true
    FROM permission_data pd
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permissions
        WHERE code = pd.resource_code || '.' || pd.action_code
    );

    -- Insert default roles if they don't exist
    INSERT INTO auth.roles (name, description, is_system)
    SELECT * FROM (VALUES
        ('admin', 'System administrator with full access', true),
        ('user', 'Regular user with basic permissions', true)
    ) AS v (name, description, is_system)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.roles
        WHERE name = v.name
    );

    -- Grant all permissions to admin role
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'admin'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );
END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';