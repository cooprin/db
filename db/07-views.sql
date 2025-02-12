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

    -- Products views
    DROP VIEW IF EXISTS products.view_products_full;
    CREATE VIEW products.view_products_full AS
    SELECT 
        p.id,
        p.sku,
        p.is_own,
        p.purchase_date,
        p.supplier_warranty_end,
        p.warranty_end,
        p.sale_date,
        p.current_status,
        p.current_object_id,
        p.is_active,
        m.name as model_name,
        m.description as model_description,
        m.image_url as model_image,
        man.name as manufacturer_name,
        s.name as supplier_name,
        s.contact_person as supplier_contact,
        s.phone as supplier_phone,
        s.email as supplier_email,
        p.created_at,
        p.updated_at
    FROM products.products p
    LEFT JOIN products.models m ON p.model_id = m.id
    LEFT JOIN products.manufacturers man ON m.manufacturer_id = man.id
    LEFT JOIN products.suppliers s ON p.supplier_id = s.id;

    COMMENT ON VIEW products.view_products_full IS 'Full product information with related data';

    -- Warehouses views
    DROP VIEW IF EXISTS warehouses.view_stock_current;
    CREATE VIEW warehouses.view_stock_current AS
    SELECT 
        s.warehouse_id,
        w.name as warehouse_name,
        s.product_id,
        p.sku,
        m.name as model_name,
        man.name as manufacturer_name,
        s.quantity,
        s.price,
        p.current_status,
        p.is_own,
        u.email as responsible_person_email,
        u.first_name || ' ' || u.last_name as responsible_person_name
    FROM warehouses.stock s
    JOIN warehouses.warehouses w ON s.warehouse_id = w.id
    JOIN products.products p ON s.product_id = p.id
    JOIN products.models m ON p.model_id = m.id
    JOIN products.manufacturers man ON m.manufacturer_id = man.id
    LEFT JOIN auth.users u ON w.responsible_person_id = u.id
    WHERE s.quantity > 0;

    COMMENT ON VIEW warehouses.view_stock_current IS 'Current stock in warehouses with product details';

    -- Stock movements view
    DROP VIEW IF EXISTS warehouses.view_stock_movements;
    CREATE VIEW warehouses.view_stock_movements AS
    SELECT 
        sm.id,
        sm.type,
        sm.quantity,
        sm.created_at,
        p.sku,
        m.name as model_name,
        w_from.name as from_warehouse,
        w_to.name as to_warehouse,
        sm.wialon_object_id,
        sm.warranty_change_days,
        sm.comment,
        u.email as created_by_user,
        u.first_name || ' ' || u.last_name as created_by_name
    FROM warehouses.stock_movements sm
    JOIN products.products p ON sm.product_id = p.id
    JOIN products.models m ON p.model_id = m.id
    LEFT JOIN warehouses.warehouses w_from ON sm.from_warehouse_id = w_from.id
    LEFT JOIN warehouses.warehouses w_to ON sm.to_warehouse_id = w_to.id
    JOIN auth.users u ON sm.created_by = u.id
    ORDER BY sm.created_at DESC;

    COMMENT ON VIEW warehouses.view_stock_movements IS 'Stock movements history with related details';

    -- Products with warranty view
    DROP VIEW IF EXISTS products.view_products_warranty;
    CREATE VIEW products.view_products_warranty AS
    SELECT 
        p.id,
        p.sku,
        m.name as model_name,
        man.name as manufacturer_name,
        s.name as supplier_name,
        p.purchase_date,
        p.supplier_warranty_end,
        p.warranty_end,
        p.current_status,
        CASE 
            WHEN p.warranty_end < CURRENT_DATE THEN 'Expired'
            WHEN p.warranty_end < CURRENT_DATE + INTERVAL '30 days' THEN 'Expiring Soon'
            ELSE 'Active'
        END as warranty_status,
        p.is_own,
        p.current_object_id
    FROM products.products p
    JOIN products.models m ON p.model_id = m.id
    JOIN products.manufacturers man ON m.manufacturer_id = man.id
    JOIN products.suppliers s ON p.supplier_id = s.id
    WHERE p.is_active = true;

    COMMENT ON VIEW products.view_products_warranty IS 'Products warranty information and status';
END $$;