-- Спрощена система ресурсів з 4 основними діями
-- Зберігає гнучкість але спрощує структуру

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
    -- Insert permission groups
    INSERT INTO auth.permission_groups (name, description)
    SELECT * FROM (VALUES
        ('System Management', 'System-level permissions (users, roles, permissions, audit)'),
        ('Product Management', 'Product catalog and inventory management'),
        ('Warehouse Management', 'Warehouse and stock operations'),
        ('Client Management', 'Client and service management'),
        ('Financial Management', 'Billing, invoices, payments, and company settings'),
        ('Wialon Management', 'Wialon objects and integration'),
        ('Resource Management', 'System resources and configuration'),
        ('Dashboard Management', 'Dashboard access and widgets')
    ) AS v (name, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permission_groups
        WHERE name = v.name
    );

    -- Insert ONLY 4 basic actions (спрощення!)
    INSERT INTO core.actions (name, code, description)
    SELECT * FROM (VALUES
        ('Create', 'create', 'Permission to create new records'),
        ('Read', 'read', 'Permission to read records'),
        ('Update', 'update', 'Permission to update records'),
        ('Delete', 'delete', 'Permission to delete records')
    ) AS v (name, code, description)
    WHERE NOT EXISTS (
        SELECT 1 FROM core.actions
        WHERE code = v.code
    );

    -- Insert resources (тільки ті що реально використовуються)
    INSERT INTO core.resources (name, code, type)
    SELECT * FROM (VALUES
        -- System resources
        ('Users', 'users', 'module'),
        ('Roles', 'roles', 'module'),
        ('Permissions', 'permissions', 'module'),
        ('Resources', 'resources', 'module'),
        ('Audit Logs', 'audit', 'module'),
        
        -- Business resources
        ('Products', 'products', 'module'),
        ('Warehouses', 'warehouses', 'module'),
        ('Clients', 'clients', 'module'),
        ('Services', 'services', 'module'),
        ('Invoices', 'invoices', 'module'),
        ('Payments', 'payments', 'module'),
        ('Tariffs', 'tariffs', 'module'),
        ('Company Profile', 'company_profile', 'module'),
        ('Wialon Objects', 'wialon_objects', 'module'),
        ('Wialon Sync', 'wialon_sync', 'module'),
        ('Reports', 'reports', 'module'),
        -- Dashboard resources
        ('Dashboard Overdue', 'dashboards.overdue', 'module'),
        ('Dashboard Tickets', 'dashboards.tickets', 'module'),
        ('Dashboard Inventory', 'dashboards.inventory', 'module'),

        -- Customer portal resources
        ('Customer Portal', 'customer_portal', 'module'),
        ('Tickets', 'tickets', 'module'),
        ('Chat', 'chat', 'module')
    ) AS v (name, code, type)
    WHERE NOT EXISTS (
        SELECT 1 FROM core.resources
        WHERE code = v.code
    );

    -- Link ALL resources with ALL 4 actions (автогенерація зв'язків)
    INSERT INTO core.resource_actions (resource_id, action_id, is_default)
    SELECT r.id, a.id, true
    FROM core.resources r
    CROSS JOIN core.actions a
    WHERE NOT EXISTS (
        SELECT 1 FROM core.resource_actions
        WHERE resource_id = r.id AND action_id = a.id
    );

    -- Auto-generate permissions for each resource+action combination
    INSERT INTO auth.permissions (group_id, resource_id, name, code, is_system)
    SELECT 
        pg.id as group_id,
        r.id as resource_id,
        r.code || '.' || a.code as name,
        r.code || '.' || a.code as code,
        true as is_system
    FROM core.resources r
    CROSS JOIN core.actions a
    JOIN core.resource_actions ra ON r.id = ra.resource_id AND a.id = ra.action_id
    LEFT JOIN auth.permission_groups pg ON (
        -- Mapping resources to permission groups
        (r.code IN ('users', 'roles', 'permissions', 'resources', 'audit') AND pg.name = 'System Management') OR
        (r.code = 'products' AND pg.name = 'Product Management') OR
        (r.code = 'warehouses' AND pg.name = 'Warehouse Management') OR
        (r.code IN ('clients', 'services') AND pg.name = 'Client Management') OR
        (r.code IN ('invoices', 'payments', 'tariffs', 'company_profile') AND pg.name = 'Financial Management') OR
        (r.code IN ('wialon_objects', 'wialon_sync') AND pg.name = 'Wialon Management') OR 
        (r.code = 'reports' AND pg.name = 'Resource Management') OR
        (r.code IN ('chat', 'customer_portal', 'tickets') AND pg.name = 'Client Management') OR
        (r.code LIKE 'dashboards.%' AND pg.name = 'Dashboard Management')
    )
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.permissions
        WHERE code = r.code || '.' || a.code
    ) AND r.code NOT LIKE 'dashboards.%';
    -- Manually add dashboard permissions (only read permissions needed)
    INSERT INTO auth.permissions (group_id, resource_id, name, code, is_system)
    SELECT 
        pg.id as group_id,
        r.id as resource_id,
        r.code as name,
        r.code as code,
        true as is_system
    FROM core.resources r
    LEFT JOIN auth.permission_groups pg ON pg.name = 'Dashboard Management'  -- ВИПРАВЛЕНО
    WHERE r.code IN ('dashboards.overdue', 'dashboards.tickets', 'dashboards.inventory')
    AND NOT EXISTS (
        SELECT 1 FROM auth.permissions
        WHERE code = r.code
    );

    -- Insert optimized roles
    INSERT INTO auth.roles (name, description, is_system)
    SELECT * FROM (VALUES
        ('admin', 'Administrator with full system access', true),
        ('manager', 'Manager with client and service management access', true),
        ('operator', 'Operator with payment and invoice management', true),
        ('warehouse_manager', 'Warehouse manager with inventory control', true),
        ('accountant', 'Accountant with financial operations access', true),
        ('viewer', 'Read-only access to main data', true),
        ('client', 'Client with access to customer portal', true)
    ) AS v (name, description, is_system)
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.roles
        WHERE name = v.name
    );

    -- Grant permissions to roles

    -- ADMIN: all permissions
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'admin'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- MANAGER: обмежені права (ВИПРАВЛЕНО)
    -- Повний доступ до управління клієнтами
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'manager'
    AND pg.name = 'Client Management'  -- clients, services, tickets, chat, customer_portal
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Обмежений доступ до Wialon (тільки читання + редагування)
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'manager'
    AND p.code IN (
        'wialon_objects.read',
        'wialon_objects.update',  -- редагування існуючих об'єктів
        'wialon_sync.read'        -- перегляд синхронізації
    )
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Читання інших модулів
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    JOIN auth.permission_groups pg ON p.group_id = pg.id
    WHERE r.name = 'manager'
    AND pg.name IN ('Product Management', 'Warehouse Management', 'Financial Management')
    AND p.code LIKE '%.read'
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
    -- CLIENT: only portal access with read permissions for own data
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'client'
    AND p.code IN (
        'customer_portal.read',
        'tickets.read', 'tickets.create', 'tickets.update',
        'chat.read', 'chat.create'
    )
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- Додаємо дозволи на звіти для ролей
-- ADMIN: вже має всі дозволи

-- MANAGER: читання та виконання звітів
INSERT INTO auth.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth.roles r
CROSS JOIN auth.permissions p
WHERE r.name = 'manager'
AND p.code IN ('reports.read')
AND NOT EXISTS (
    SELECT 1 FROM auth.role_permissions
    WHERE role_id = r.id AND permission_id = p.id
);

-- OPERATOR: тільки читання звітів
INSERT INTO auth.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth.roles r
CROSS JOIN auth.permissions p
WHERE r.name = 'operator'
AND p.code IN ('reports.read')
AND NOT EXISTS (
    SELECT 1 FROM auth.role_permissions
    WHERE role_id = r.id AND permission_id = p.id
);

-- ACCOUNTANT: повний доступ до звітів
INSERT INTO auth.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth.roles r
CROSS JOIN auth.permissions p
WHERE r.name = 'accountant'
AND p.code LIKE 'reports.%'
AND NOT EXISTS (
    SELECT 1 FROM auth.role_permissions
    WHERE role_id = r.id AND permission_id = p.id
);

-- VIEWER: тільки читання звітів
INSERT INTO auth.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth.roles r
CROSS JOIN auth.permissions p
WHERE r.name = 'viewer'
AND p.code IN ('reports.read')
AND NOT EXISTS (
    SELECT 1 FROM auth.role_permissions
    WHERE role_id = r.id AND permission_id = p.id
);
-- Призначити дозволи на дашборди
    -- ADMIN: вже має всі дозволи через загальне призначення

    -- MANAGER: overdue + tickets
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'manager'
    AND p.code IN ('dashboards.overdue', 'dashboards.tickets')
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- OPERATOR: тільки overdue
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'operator'
    AND p.code = 'dashboards.overdue'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- WAREHOUSE_MANAGER: inventory
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'warehouse_manager'
    AND p.code = 'dashboards.inventory'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

    -- ACCOUNTANT: overdue
    INSERT INTO auth.role_permissions (role_id, permission_id)
    SELECT r.id, p.id
    FROM auth.roles r
    CROSS JOIN auth.permissions p
    WHERE r.name = 'accountant'
    AND p.code = 'dashboards.overdue'
    AND NOT EXISTS (
        SELECT 1 FROM auth.role_permissions
        WHERE role_id = r.id AND permission_id = p.id
    );

END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';