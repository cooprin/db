-- Оптимізований файл ініціалізації прав (замість 01-default-data.sql)
-- Створює тільки ті права, які реально використовуються в коді

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
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA company TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA wialon_sync TO %I', current_user);

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
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA company TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA wialon_sync TO %I', current_user);

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
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA company TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA wialon_sync TO %I', current_user);
END $$;

-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert initial data
DO $$
BEGIN
    -- Insert permission groups (тільки потрібні)
    INSERT INTO auth.permission_groups (name, description)
    SELECT * FROM (VALUES
        ('System Management', 'System-level permissions (users, roles, permissions, audit)'),
        ('Product Management', 'Product catalog and inventory management'),
        ('Warehouse Management', 'Warehouse and stock operations'),
        ('Client Management', 'Client and service management'),
        ('Financial Management', 'Billing, invoices, payments, and company settings'),
        ('Wialon Management', 'Wialon objects and integration'),
        ('Resource Management', 'System resources and configuration')
    ) AS v (name, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permission_groups
        WHERE name = v.name
    );

    -- Insert only ACTUALLY USED permissions (64 permissions from code analysis)
    INSERT INTO auth.permissions (group_id, name, code, is_system)
    SELECT pg.id, perm.name, perm.code, true
    FROM auth.permission_groups pg
    CROSS JOIN (VALUES
        -- AUDIT (2 permissions)
        ('System Management', 'Read audit logs', 'audit.read'),
        ('System Management', 'Export audit logs', 'audit.export'),
        
        -- USERS (4 permissions)
        ('System Management', 'Read users', 'users.read'),
        ('System Management', 'Create users', 'users.create'),
        ('System Management', 'Update users', 'users.update'),
        ('System Management', 'Delete users', 'users.delete'),
        
        -- ROLES (4 permissions)
        ('System Management', 'Read roles', 'roles.read'),
        ('System Management', 'Create roles', 'roles.create'),
        ('System Management', 'Update roles', 'roles.update'),
        ('System Management', 'Delete roles', 'roles.delete'),
        
        -- PERMISSIONS (5 permissions)
        ('System Management', 'Read permissions', 'permissions.read'),
        ('System Management', 'Create permissions', 'permissions.create'),
        ('System Management', 'Update permissions', 'permissions.update'),
        ('System Management', 'Delete permissions', 'permissions.delete'),
        ('System Management', 'Manage permission groups', 'permissions.manage'),
        
        -- PRODUCTS (4 permissions)
        ('Product Management', 'Read products', 'products.read'),
        ('Product Management', 'Create products', 'products.create'),
        ('Product Management', 'Update products', 'products.update'),
        ('Product Management', 'Delete products', 'products.delete'),
        
        -- WAREHOUSES (4 permissions)
        ('Warehouse Management', 'Read warehouses', 'warehouses.read'),
        ('Warehouse Management', 'Create warehouses', 'warehouses.create'),
        ('Warehouse Management', 'Update warehouses', 'warehouses.update'),
        ('Warehouse Management', 'Delete warehouses', 'warehouses.delete'),
        
        -- CLIENTS (4 permissions)
        ('Client Management', 'Read clients', 'clients.read'),
        ('Client Management', 'Create clients', 'clients.create'),
        ('Client Management', 'Update clients', 'clients.update'),
        ('Client Management', 'Delete clients', 'clients.delete'),
        
        -- SERVICES (4 permissions)
        ('Client Management', 'Read services', 'services.read'),
        ('Client Management', 'Create services', 'services.create'),
        ('Client Management', 'Update services', 'services.update'),
        ('Client Management', 'Delete services', 'services.delete'),
        
        -- INVOICES (3 permissions)
        ('Financial Management', 'Read invoices', 'invoices.read'),
        ('Financial Management', 'Create invoices', 'invoices.create'),
        ('Financial Management', 'Update invoices', 'invoices.update'),
        
        -- PAYMENTS (4 permissions)
        ('Financial Management', 'Read payments', 'payments.read'),
        ('Financial Management', 'Create payments', 'payments.create'),
        ('Financial Management', 'Update payments', 'payments.update'),
        ('Financial Management', 'Delete payments', 'payments.delete'),
        
        -- TARIFFS (4 permissions)
        ('Financial Management', 'Read tariffs', 'tariffs.read'),
        ('Financial Management', 'Create tariffs', 'tariffs.create'),
        ('Financial Management', 'Update tariffs', 'tariffs.update'),
        ('Financial Management', 'Delete tariffs', 'tariffs.delete'),
        
        -- COMPANY PROFILE (2 permissions)
        ('Financial Management', 'Read company profile', 'company_profile.read'),
        ('Financial Management', 'Update company profile', 'company_profile.update'),
        
        -- BANK ACCOUNTS (4 permissions)
        ('Financial Management', 'Read bank accounts', 'bank_accounts.read'),
        ('Financial Management', 'Create bank accounts', 'bank_accounts.create'),
        ('Financial Management', 'Update bank accounts', 'bank_accounts.update'),
        ('Financial Management', 'Delete bank accounts', 'bank_accounts.delete'),
        
        -- LEGAL DOCUMENTS (3 permissions)
        ('Financial Management', 'Read legal documents', 'legal_documents.read'),
        ('Financial Management', 'Create legal documents', 'legal_documents.create'),
        ('Financial Management', 'Delete legal documents', 'legal_documents.delete'),
        
        -- SETTINGS (3 permissions)
        ('Financial Management', 'Read settings', 'settings.read'),
        ('Financial Management', 'Create settings', 'settings.create'),
        ('Financial Management', 'Delete settings', 'settings.delete'),
        
        -- WIALON OBJECTS (4 permissions)
        ('Wialon Management', 'Read wialon objects', 'wialon_objects.read'),
        ('Wialon Management', 'Create wialon objects', 'wialon_objects.create'),
        ('Wialon Management', 'Update wialon objects', 'wialon_objects.update'),
        ('Wialon Management', 'Delete wialon objects', 'wialon_objects.delete'),
        
        -- WIALON INTEGRATION (2 permissions)
        ('Wialon Management', 'Read wialon integration', 'wialon_integration.read'),
        ('Wialon Management', 'Update wialon integration', 'wialon_integration.update'),
        
        -- WIALON SYNC (4 permissions)
        ('Wialon Management', 'Read wialon sync', 'wialon_sync.read'),
        ('Wialon Management', 'Create wialon sync', 'wialon_sync.create'),
        ('Wialon Management', 'Update wialon sync', 'wialon_sync.update'),
        ('Wialon Management', 'Delete wialon sync', 'wialon_sync.delete'),
        
        -- RESOURCES (4 permissions)
        ('Resource Management', 'Read resources', 'resources.read'),
        ('Resource Management', 'Create resources', 'resources.create'),
        ('Resource Management', 'Update resources', 'resources.update'),
        ('Resource Management', 'Delete resources', 'resources.delete'),
        ('Resource Management', 'Manage resource actions', 'resources.manage')
        
    ) AS perm(group_name, name, code)
    WHERE pg.name = perm.group_name
    AND NOT EXISTS (
        SELECT 1 FROM auth.permissions
        WHERE code = perm.code
    );

    -- Insert optimized roles (fewer, more logical roles)
    INSERT INTO auth.roles (name, description, is_system)
    SELECT * FROM (VALUES
        ('super_admin', 'Super administrator with full system access', true),
        ('admin', 'Administrator with full business access', true),
        ('manager', 'Manager with client and service management access', true),
        ('operator', 'Operator with payment and invoice management', true),
        ('warehouse_manager', 'Warehouse manager with inventory control', true),
        ('accountant', 'Accountant with financial operations access', true),
        ('viewer', 'Read-only access to main data', true)
    ) AS v (name, description, is_system)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.roles
        WHERE name = v.name
    );

    -- Grant permissions to roles
    
    -- SUPER_ADMIN: all permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'super_admin'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- ADMIN: all except system management (users, roles, permissions)
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'admin'
    AND pg.name != 'System Management'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );
    
    -- ADMIN: only audit.read from system management
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'admin'
    AND p.code = 'audit.read'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- MANAGER: client, service, wialon management + reading others
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'manager'
    AND (
        pg.name IN ('Client Management', 'Wialon Management') OR
        (pg.name IN ('Product Management', 'Warehouse Management', 'Financial Management') AND p.code LIKE '%.read')
    )
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- OPERATOR: payments, invoices + reading clients, services
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'operator'
    AND p.code IN (
        'payments.read', 'payments.create', 'payments.update', 'payments.delete',
        'invoices.read', 'invoices.create', 'invoices.update',
        'clients.read', 'services.read', 'wialon_objects.read'
    )
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- WAREHOUSE_MANAGER: full warehouse + product management
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'warehouse_manager'
    AND pg.name IN ('Product Management', 'Warehouse Management')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );
    
    -- WAREHOUSE_MANAGER: reading others
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'warehouse_manager'
    AND pg.name IN ('Client Management') AND p.code LIKE '%.read'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- ACCOUNTANT: financial management + reading others
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'accountant'
    AND (
        pg.name = 'Financial Management' OR
        (pg.name IN ('Client Management', 'Wialon Management') AND p.code LIKE '%.read')
    )
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- VIEWER: only read permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'viewer'
    AND p.code LIKE '%.read'
    AND p.code != 'audit.read' -- exclude audit
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';