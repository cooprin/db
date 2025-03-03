-- Grant privileges to current user
DO $$
BEGIN
    -- Grant schema permissions
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA auth TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA core TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA audit TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA products TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA warehouses TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA clients TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA services TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA billing TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA wialon TO %I', current_user);

    -- Grant table permissions
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA products TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA warehouses TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA clients TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA services TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA billing TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA wialon TO %I', current_user);

    -- Grant sequence permissions
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA products TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA warehouses TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA clients TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA services TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA billing TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wialon TO %I', current_user);

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
        ('Models', 'models', 'table'),
        ('Product Types', 'product_types', 'table'),
        ('Product Characteristics', 'product_characteristics', 'module'),
        ('Warehouses', 'warehouses', 'module'),
        ('Stock', 'stock', 'module'),
        ('Stock Movements', 'stock_movements', 'table'),
        ('Reports', 'reports', 'module'),
        ('Analytics', 'analytics', 'module'),
        ('Warranty Management', 'warranty', 'module'),
        ('Repair Management', 'repair', 'module'),
        ('Notifications', 'notifications', 'module'),
        ('Settings', 'settings', 'module'),
        ('Documents', 'documents', 'module'),
        ('Logs', 'logs', 'module'),
        -- New resources
        ('Clients', 'clients', 'module'),
        ('Client Documents', 'client_documents', 'table'),
        ('Client Contacts', 'client_contacts', 'table'),
        ('Wialon Objects', 'wialon_objects', 'module'),
        ('Object Ownership', 'object_ownership', 'table'),
        ('Tariffs', 'tariffs', 'module'),
        ('Object Tariffs', 'object_tariffs', 'table'),
        ('Payments', 'payments', 'module'),
        ('Services', 'services', 'module'),
        ('Client Services', 'client_services', 'table'),
        ('Invoices', 'invoices', 'module'),
        ('Invoice Documents', 'invoice_documents', 'table'),
        ('Billing', 'billing', 'module')
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
        ('Manage', 'manage', 'Full management permission'),
        ('Export', 'export', 'Permission to export data'),
        ('Import', 'import', 'Permission to import data'),
        ('Print', 'print', 'Permission to print documents'),
        ('Approve', 'approve', 'Permission to approve operations'),
        ('Cancel', 'cancel', 'Permission to cancel operations'),
        ('Archive', 'archive', 'Permission to archive records'),
        ('Restore', 'restore', 'Permission to restore archived records'),
        ('Transfer', 'transfer', 'Permission to transfer items'),
        ('Assign', 'assign', 'Permission to assign items or tasks'),
        ('Configure', 'configure', 'Permission to configure settings'),
        -- New actions
        ('Bill', 'bill', 'Permission to create bills and invoices'),
        ('Pay', 'pay', 'Permission to register payments')
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
        ('Product Type Management', 'Permissions related to product types and characteristics'),
        ('Product Model Management', 'Permissions related to product models'),
        ('Manufacturer Management', 'Permissions related to manufacturers'),
        ('Supplier Management', 'Permissions related to suppliers'),
        ('Warehouse Management', 'Permissions related to warehouse operations'),
        ('Stock Management', 'Permissions related to stock operations'),
        ('Stock Movement Management', 'Permissions related to stock movements and transfers'),
        ('Warranty Management', 'Permissions related to warranty tracking and management'),
        ('Repair Management', 'Permissions related to repair operations'),
        ('Report Management', 'Permissions related to reporting'),
        ('Analytics Access', 'Permissions related to analytics and dashboards'),
        ('Document Management', 'Permissions related to document operations'),
        ('Import Export Management', 'Permissions for import/export operations'),
        ('Notification Management', 'Permissions related to notification settings'),
        ('System Configuration', 'Permissions related to system configuration'),
        ('Audit Log Access', 'Permissions related to audit log viewing'),
        ('Archive Management', 'Permissions related to archiving and restoration'),
        -- New permission groups
        ('Client Management', 'Permissions related to client management'),
        ('Wialon Object Management', 'Permissions related to Wialon objects'),
        ('Tariff Management', 'Permissions related to tariff management'),
        ('Service Management', 'Permissions related to service management'),
        ('Billing Management', 'Permissions related to billing and finances'),
        ('Invoice Management', 'Permissions related to invoice creation and management'),
        ('Payment Management', 'Permissions related to payment tracking')
    ) AS v (name, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permission_groups
        WHERE name = v.name
    );

    -- Insert default permissions with conflict handling
    WITH permission_data AS (
        SELECT DISTINCT
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
            (pg.name = 'Product Management' AND r.code = 'products' AND pg.name = 'Product Management') OR
            (pg.name = 'Product Type Management' AND r.code IN ('product_types', 'product_characteristics')) OR
            (pg.name = 'Product Model Management' AND r.code = 'models') OR
            (pg.name = 'Manufacturer Management' AND r.code = 'manufacturers') OR
            (pg.name = 'Supplier Management' AND r.code = 'suppliers') OR
            (pg.name = 'Warehouse Management' AND r.code = 'warehouses') OR
            (pg.name = 'Stock Management' AND r.code = 'stock') OR
            (pg.name = 'Stock Movement Management' AND r.code = 'stock_movements') OR
            (pg.name = 'Warranty Management' AND r.code = 'warranty') OR
            (pg.name = 'Repair Management' AND r.code = 'repair') OR
            (pg.name = 'Report Management' AND r.code = 'reports') OR
            (pg.name = 'Analytics Access' AND r.code = 'analytics') OR
            (pg.name = 'Document Management' AND r.code = 'documents') OR
            (pg.name = 'Import Export Management' AND r.code = 'products' AND pg.name = 'Import Export Management') OR
            (pg.name = 'Notification Management' AND r.code = 'notifications') OR
            (pg.name = 'System Configuration' AND r.code = 'settings') OR
            (pg.name = 'Audit Log Access' AND r.code = 'logs') OR
            (pg.name = 'Archive Management' AND r.code IN ('products', 'documents', 'stock_movements') AND pg.name = 'Archive Management') OR
            -- New permissions mappings
            (pg.name = 'Client Management' AND r.code IN ('clients', 'client_documents', 'client_contacts')) OR
            (pg.name = 'Wialon Object Management' AND r.code IN ('wialon_objects', 'object_ownership')) OR
            (pg.name = 'Tariff Management' AND r.code IN ('tariffs', 'object_tariffs')) OR
            (pg.name = 'Service Management' AND r.code IN ('services', 'client_services')) OR
            (pg.name = 'Billing Management' AND r.code IN ('billing', 'payments', 'invoices')) OR
            (pg.name = 'Invoice Management' AND r.code IN ('invoices', 'invoice_documents')) OR
            (pg.name = 'Payment Management' AND r.code = 'payments')
    )
    INSERT INTO auth.permissions (
        group_id, 
        resource_id, 
        name, 
        code, 
        is_system
    )
    SELECT DISTINCT
        pd.group_id,
        pd.resource_id,
        pd.resource_code || '.' || pd.action_code as name,
        pd.resource_code || '.' || pd.action_code as code,
        true
    FROM permission_data pd
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permissions
        WHERE code = pd.resource_code || '.' || pd.action_code
    )
    ON CONFLICT (code) DO NOTHING;

    -- Insert default roles if they don't exist
    INSERT INTO auth.roles (name, description, is_system)
    SELECT * FROM (VALUES
        ('admin', 'System administrator with full access', true),
        ('warehouse_manager', 'Warehouse manager with stock control permissions', true),
        ('product_manager', 'Product manager with catalog management permissions', true),
        ('support_specialist', 'Support specialist with repair and warranty management', true),
        ('report_viewer', 'User with read-only access to reports', true),
        ('stock_controller', 'User responsible for stock operations', true),
        ('warranty_manager', 'User managing warranty claims and tracking', true),
        ('system_auditor', 'User with access to audit logs and system monitoring', true),
        ('user', 'Regular user with basic permissions', true),
        -- New roles
        ('client_manager', 'User managing clients and their services', true),
        ('finance_manager', 'User managing billing, invoices and payments', true),
        ('wialon_manager', 'User managing Wialon objects and tariffs', true),
        ('service_manager', 'User managing services and client subscriptions', true)
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

    -- Grant warehouse permissions to warehouse_manager role
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'warehouse_manager'
    AND pg.name IN ('Warehouse Management', 'Stock Management', 'Stock Movement Management', 
                   'Document Management', 'Report Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant product management permissions to product_manager role
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'product_manager'
    AND pg.name IN ('Product Management', 'Product Type Management', 'Product Model Management',
                   'Manufacturer Management', 'Supplier Management', 'Document Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant support permissions to support_specialist role
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'support_specialist'
    AND pg.name IN ('Warranty Management', 'Repair Management', 'Document Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant stock controller permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'stock_controller'
    AND pg.name IN ('Stock Management', 'Stock Movement Management', 'Document Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant system auditor permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'system_auditor'
    AND pg.name IN ('Audit Log Access', 'Report Management', 'Analytics Access')
    AND p.code LIKE '%.read'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant warranty manager permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'warranty_manager'
    AND pg.name IN ('Warranty Management', 'Document Management', 'Report Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant system auditor permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'system_auditor'
    AND pg.name IN ('Audit Log Access', 'Report Management', 'Analytics Access')
    AND p.code LIKE '%.read'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant report viewing permissions to report_viewer role
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'report_viewer'
    AND pg.name IN ('Report Management', 'Analytics Access')
    AND p.code LIKE '%.read'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant basic permissions to user role
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'user'
    AND pg.name IN ('Report Management')
    AND p.code LIKE '%.read'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant client manager permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'client_manager'
    AND pg.name IN ('Client Management', 'Document Management', 'Report Management', 'Service Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant finance manager permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'finance_manager'
    AND pg.name IN ('Billing Management', 'Invoice Management', 'Payment Management', 'Report Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant wialon manager permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'wialon_manager'
    AND pg.name IN ('Wialon Object Management', 'Tariff Management', 'Report Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Grant service manager permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'service_manager'
    AND pg.name IN ('Service Management', 'Client Management', 'Report Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';