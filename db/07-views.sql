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

   -- Products view with characteristics
   DROP VIEW IF EXISTS products.view_products_full;
   CREATE VIEW products.view_products_full AS
   SELECT 
       p.id,
       p.sku,
       p.current_status,
       p.current_object_id,
       p.is_active,
       pt.name as product_type_name,
       pt.code as product_type_code,
       m.name as model_name,
       m.description as model_description,
       m.image_url as model_image,
       m.product_type_id,
       man.name as manufacturer_name,
       s.name as supplier_name,
       s.contact_person as supplier_contact,
       s.phone as supplier_phone,
       s.email as supplier_email,
       p.created_at,
       p.updated_at,
       jsonb_object_agg(
           ptc.code,
           jsonb_build_object(
               'name', ptc.name,
               'type', ptc.type,
               'value', pcv.value
           )
       ) FILTER (WHERE ptc.id IS NOT NULL) as characteristics
   FROM products.products p
   JOIN products.models m ON p.model_id = m.id
   JOIN products.product_types pt ON m.product_type_id = pt.id
   LEFT JOIN products.manufacturers man ON m.manufacturer_id = man.id
   LEFT JOIN products.suppliers s ON p.supplier_id = s.id
   LEFT JOIN products.product_type_characteristics ptc ON pt.id = ptc.product_type_id
   LEFT JOIN products.product_characteristic_values pcv ON p.id = pcv.product_id AND ptc.id = pcv.characteristic_id
   GROUP BY p.id, pt.id, m.id, man.id, s.id;

   COMMENT ON VIEW products.view_products_full IS 'Full product information with related data and characteristics';

   -- Product types view
   DROP VIEW IF EXISTS products.view_product_types_full;
   CREATE VIEW products.view_product_types_full AS
   SELECT 
       pt.id,
       pt.name,
       pt.code,
       pt.description,
       pt.is_active,
       jsonb_agg(
           jsonb_build_object(
               'id', ptc.id,
               'name', ptc.name,
               'code', ptc.code,
               'type', ptc.type,
               'is_required', ptc.is_required,
               'default_value', ptc.default_value,
               'validation_rules', ptc.validation_rules,
               'options', ptc.options,
               'ordering', ptc.ordering
           ) ORDER BY ptc.ordering
       ) FILTER (WHERE ptc.id IS NOT NULL) as characteristics,
       COUNT(DISTINCT m.id) as products_count,
       pt.created_at,
       pt.updated_at
   FROM products.product_types pt
   LEFT JOIN products.product_type_characteristics ptc ON pt.id = ptc.product_type_id
   LEFT JOIN products.models m ON pt.id = m.product_type_id
   GROUP BY pt.id;

   COMMENT ON VIEW products.view_product_types_full IS 'Product types with their characteristics and usage statistics';

   -- Products warranty view
   DROP VIEW IF EXISTS products.view_products_warranty;
   CREATE VIEW products.view_products_warranty AS
   SELECT 
       p.id,
       p.sku,
       m.name as model_name,
       man.name as manufacturer_name,
       s.name as supplier_name,
       p.current_status,
       pt.name as product_type_name,
       MAX(CASE WHEN ptc.code = 'purchase_date' THEN pcv.value END)::date as purchase_date,
       MAX(CASE WHEN ptc.code = 'supplier_warranty_end' THEN pcv.value END)::date as supplier_warranty_end,
       MAX(CASE WHEN ptc.code = 'warranty_end' THEN pcv.value END)::date as warranty_end,
       CASE 
           WHEN MAX(CASE WHEN ptc.code = 'warranty_end' THEN pcv.value END)::date < CURRENT_DATE THEN 'Expired'
           WHEN MAX(CASE WHEN ptc.code = 'warranty_end' THEN pcv.value END)::date < CURRENT_DATE + INTERVAL '30 days' THEN 'Expiring Soon'
           ELSE 'Active'
       END as warranty_status,
       p.current_object_id
   FROM products.products p
   JOIN products.models m ON p.model_id = m.id
   JOIN products.manufacturers man ON m.manufacturer_id = man.id
   JOIN products.suppliers s ON p.supplier_id = s.id
   JOIN products.product_types pt ON m.product_type_id = pt.id
   LEFT JOIN products.product_type_characteristics ptc ON pt.id = ptc.product_type_id
   LEFT JOIN products.product_characteristic_values pcv ON p.id = pcv.product_id AND ptc.id = pcv.characteristic_id
   WHERE p.is_active = true
     AND ptc.code IN ('purchase_date', 'supplier_warranty_end', 'warranty_end')
   GROUP BY p.id, m.name, man.name, s.name, pt.name;

   COMMENT ON VIEW products.view_products_warranty IS 'Products warranty information and status based on characteristics';

   -- Stock view
   DROP VIEW IF EXISTS warehouses.view_stock_current;
   CREATE VIEW warehouses.view_stock_current AS
   SELECT 
       s.warehouse_id,
       w.name as warehouse_name,
       s.product_id,
       p.sku,
       pt.name as product_type_name,
       m.name as model_name,
       man.name as manufacturer_name,
       p.current_status,
       p.current_object_id,
       s.price,
       u.email as responsible_person_email,
       u.first_name || ' ' || u.last_name as responsible_person_name
   FROM warehouses.stock s
   JOIN warehouses.warehouses w ON s.warehouse_id = w.id
   JOIN products.products p ON s.product_id = p.id
   JOIN products.models m ON p.model_id = m.id
   JOIN products.product_types pt ON m.product_type_id = pt.id
   JOIN products.manufacturers man ON m.manufacturer_id = man.id
   LEFT JOIN auth.users u ON w.responsible_person_id = u.id
   WHERE p.current_status = 'in_stock';

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

   -- Modify products.view_product_types_full to include characteristic type details
   DROP VIEW IF EXISTS products.view_product_types_full;
   CREATE VIEW products.view_product_types_full AS
   SELECT 
       pt.id,
       pt.name,
       pt.code,
       pt.description,
       pt.is_active,
       jsonb_agg(
           jsonb_build_object(
               'id', ptc.id,
               'name', ptc.name,
               'code', ptc.code,
               'type', ptc.type,
               'type_label', ct.label,
               'type_description', ct.description,
               'is_required', ptc.is_required,
               'default_value', ptc.default_value,
               'validation_rules', ptc.validation_rules,
               'options', ptc.options,
               'ordering', ptc.ordering
           ) ORDER BY ptc.ordering
       ) FILTER (WHERE ptc.id IS NOT NULL) as characteristics,
       COUNT(DISTINCT m.id) as products_count,
       pt.created_at,
       pt.updated_at
   FROM products.product_types pt
   LEFT JOIN products.product_type_characteristics ptc ON pt.id = ptc.product_type_id
   LEFT JOIN products.characteristic_types ct ON ptc.type = ct.value
   LEFT JOIN products.models m ON pt.id = m.product_type_id
   GROUP BY pt.id;

   COMMENT ON VIEW warehouses.view_stock_movements IS 'Stock movements history with related details';

      -- Clients with details view
   DROP VIEW IF EXISTS clients.view_clients_full;
   CREATE VIEW clients.view_clients_full AS
   SELECT 
       c.id,
       c.name,
       c.full_name,
       c.address,
       c.contact_person,
       c.phone,
       c.email,
       c.wialon_id,
       c.wialon_username,
       c.is_active,
       COUNT(DISTINCT o.id) as objects_count,
       COUNT(DISTINCT cd.id) as documents_count,
       array_agg(DISTINCT cont.first_name || ' ' || coalesce(cont.last_name, '') || ' (' || coalesce(cont.position, '') || ')') FILTER (WHERE cont.id IS NOT NULL) as contacts,
       c.created_at,
       c.updated_at
   FROM clients.clients c
   LEFT JOIN wialon.objects o ON c.id = o.client_id
   LEFT JOIN clients.client_documents cd ON c.id = cd.client_id
   LEFT JOIN clients.contacts cont ON c.id = cont.client_id
   GROUP BY c.id;

   COMMENT ON VIEW clients.view_clients_full IS 'Detailed client information with counts of related entities';

   -- Wialon objects view
   DROP VIEW IF EXISTS wialon.view_objects_full;
   CREATE VIEW wialon.view_objects_full AS
   SELECT 
       o.id,
       o.wialon_id,
       o.name,
       o.description,
       o.status,
       c.id as client_id,
       c.name as client_name,
       c.wialon_username as client_wialon_username,
       t.id as current_tariff_id,
       t.name as current_tariff_name,
       t.price as current_tariff_price,
       ot.effective_from as tariff_effective_from,
       jsonb_object_agg(
           oa.attribute_name, 
           oa.attribute_value
       ) FILTER (WHERE oa.id IS NOT NULL) as attributes,
       o.created_at,
       o.updated_at
   FROM wialon.objects o
   JOIN clients.clients c ON o.client_id = c.id
   LEFT JOIN billing.object_tariffs ot ON o.id = ot.object_id AND ot.effective_to IS NULL
   LEFT JOIN billing.tariffs t ON ot.tariff_id = t.id
   LEFT JOIN wialon.object_attributes oa ON o.id = oa.object_id
   GROUP BY o.id, c.id, t.id, ot.effective_from;

   COMMENT ON VIEW wialon.view_objects_full IS 'Detailed Wialon object information with client and tariff data';

   -- Object ownership history view
   DROP VIEW IF EXISTS wialon.view_object_ownership_history;
   CREATE VIEW wialon.view_object_ownership_history AS
   SELECT 
       ooh.id,
       o.id as object_id,
       o.name as object_name,
       o.wialon_id,
       c.id as client_id,
       c.name as client_name,
       ooh.start_date,
       ooh.end_date,
       CASE 
           WHEN ooh.end_date IS NULL THEN 'Current'
           ELSE 'Historical'
       END as status,
       u.email as created_by_email,
       ooh.created_at
   FROM wialon.object_ownership_history ooh
   JOIN wialon.objects o ON ooh.object_id = o.id
   JOIN clients.clients c ON ooh.client_id = c.id
   LEFT JOIN auth.users u ON ooh.created_by = u.id
   ORDER BY o.name, ooh.start_date DESC;

   COMMENT ON VIEW wialon.view_object_ownership_history IS 'Object ownership history with object and client details';

   -- Active object tariffs view
   DROP VIEW IF EXISTS billing.view_active_object_tariffs;
   CREATE VIEW billing.view_active_object_tariffs AS
   SELECT 
       ot.id,
       o.id as object_id,
       o.name as object_name,
       o.wialon_id,
       c.id as client_id,
       c.name as client_name,
       t.id as tariff_id,
       t.name as tariff_name,
       t.price,
       ot.effective_from,
       ot.effective_to,
       u.email as created_by_email,
       ot.created_at
   FROM billing.object_tariffs ot
   JOIN wialon.objects o ON ot.object_id = o.id
   JOIN clients.clients c ON o.client_id = c.id
   JOIN billing.tariffs t ON ot.tariff_id = t.id
   LEFT JOIN auth.users u ON ot.created_by = u.id
   WHERE (ot.effective_to IS NULL OR ot.effective_to >= CURRENT_DATE)
   AND ot.effective_from <= CURRENT_DATE
   ORDER BY c.name, o.name;

   COMMENT ON VIEW billing.view_active_object_tariffs IS 'Current active tariffs for objects';

   -- Payment history view
   DROP VIEW IF EXISTS billing.view_payment_history;
   CREATE VIEW billing.view_payment_history AS
   SELECT 
       p.id,
       c.id as client_id,
       c.name as client_name,
       p.amount,
       p.payment_date,
       p.payment_month,
       p.payment_year,
       to_char(to_date(p.payment_month::text, 'MM'), 'Month') || ' ' || p.payment_year::text as payment_period,
       p.payment_type,
       p.notes,
       COUNT(opr.id) as objects_count,
       u.email as created_by_email,
       p.created_at
   FROM billing.payments p
   JOIN clients.clients c ON p.client_id = c.id
   LEFT JOIN billing.object_payment_records opr ON p.id = opr.payment_id
   LEFT JOIN auth.users u ON p.created_by = u.id
   GROUP BY p.id, c.id, u.email
   ORDER BY p.payment_year DESC, p.payment_month DESC, c.name;

   COMMENT ON VIEW billing.view_payment_history IS 'Client payment history with details';

   -- Monthly billing report view
   DROP VIEW IF EXISTS billing.view_monthly_billing;
   CREATE VIEW billing.view_monthly_billing AS
   WITH current_month AS (
       SELECT 
           EXTRACT(MONTH FROM CURRENT_DATE) as month,
           EXTRACT(YEAR FROM CURRENT_DATE) as year
   )
   SELECT 
       c.id as client_id,
       c.name as client_name,
       o.id as object_id,
       o.name as object_name,
       o.wialon_id,
       t.id as tariff_id,
       t.name as tariff_name,
       t.price as monthly_price,
       cm.month as billing_month,
       cm.year as billing_year,
       to_char(to_date(cm.month::text, 'MM'), 'Month') || ' ' || cm.year::text as billing_period,
       CASE 
           WHEN opr.id IS NOT NULL THEN 'Paid'
           ELSE 'Unpaid'
       END as payment_status,
       opr.payment_id
   FROM wialon.objects o
   JOIN clients.clients c ON o.client_id = c.id
   JOIN billing.object_tariffs ot ON o.id = ot.object_id
   JOIN billing.tariffs t ON ot.tariff_id = t.id
   CROSS JOIN current_month cm
   LEFT JOIN billing.object_payment_records opr ON o.id = opr.object_id 
       AND opr.billing_month = cm.month 
       AND opr.billing_year = cm.year
   WHERE o.status = 'active'
   AND ot.effective_from <= (cm.year || '-' || cm.month || '-01')::date
   AND (ot.effective_to IS NULL OR ot.effective_to >= (cm.year || '-' || cm.month || '-01')::date)
   ORDER BY c.name, o.name;

   COMMENT ON VIEW billing.view_monthly_billing IS 'Current month billing information for all active objects';

   -- Client services view
   DROP VIEW IF EXISTS services.view_client_services;
   CREATE VIEW services.view_client_services AS
   SELECT 
       cs.id,
       c.id as client_id,
       c.name as client_name,
       s.id as service_id,
       s.name as service_name,
       s.service_type,
       s.fixed_price,
       cs.start_date,
       cs.end_date,
       cs.status,
       cs.notes,
       CASE 
           WHEN s.service_type = 'fixed' THEN s.fixed_price
           WHEN s.service_type = 'object_based' THEN (
               SELECT COALESCE(SUM(t.price), 0)
               FROM wialon.objects o
               JOIN billing.object_tariffs ot ON o.id = ot.object_id
               JOIN billing.tariffs t ON ot.tariff_id = t.id
               WHERE o.client_id = c.id
               AND o.status = 'active'
               AND ot.effective_to IS NULL
           )
           ELSE 0
       END as calculated_price,
       cs.created_at,
       cs.updated_at
   FROM services.client_services cs
   JOIN clients.clients c ON cs.client_id = c.id
   JOIN services.services s ON cs.service_id = s.id
   WHERE cs.status = 'active'
   AND (cs.end_date IS NULL OR cs.end_date >= CURRENT_DATE)
   ORDER BY c.name, s.name;

   COMMENT ON VIEW services.view_client_services IS 'Active client services with calculated prices';

   -- Client invoices view
   DROP VIEW IF EXISTS services.view_client_invoices;
   CREATE VIEW services.view_client_invoices AS
   SELECT 
       i.id,
       c.id as client_id,
       c.name as client_name,
       i.invoice_number,
       i.invoice_date,
       i.billing_month,
       i.billing_year,
       to_char(to_date(i.billing_month::text, 'MM'), 'Month') || ' ' || i.billing_year::text as billing_period,
       i.total_amount,
       i.status,
       COUNT(ii.id) as items_count,
       COUNT(id.id) as documents_count,
       p.id as payment_id,
       p.payment_date,
       u.email as created_by_email,
       i.created_at,
       i.updated_at
   FROM services.invoices i
   JOIN clients.clients c ON i.client_id = c.id
   LEFT JOIN services.invoice_items ii ON i.id = ii.invoice_id
   LEFT JOIN services.invoice_documents id ON i.id = id.invoice_id
   LEFT JOIN billing.payments p ON i.payment_id = p.id
   LEFT JOIN auth.users u ON i.created_by = u.id
   GROUP BY i.id, c.id, p.id, u.email
   ORDER BY i.billing_year DESC, i.billing_month DESC, c.name;

   COMMENT ON VIEW services.view_client_invoices IS 'Client invoices with related information';

-- Company details view
   DROP VIEW IF EXISTS company.view_organization_full;
   CREATE VIEW company.view_organization_full AS
   SELECT 
       o.id,
       o.legal_name,
       o.short_name,
       o.legal_form,
       o.edrpou,
       o.tax_number,
       o.legal_address,
       o.actual_address,
       o.phone,
       o.email,
       o.website,
       o.director_name,
       o.director_position,
       o.accountant_name,
       o.logo_path,
       o.is_active,
       jsonb_agg(
           jsonb_build_object(
               'id', ba.id,
               'bank_name', ba.bank_name,
               'account_number', ba.account_number,
               'iban', ba.iban,
               'mfo', ba.mfo,
               'swift_code', ba.swift_code,
               'currency', ba.currency,
               'is_default', ba.is_default
           ) ORDER BY ba.is_default DESC, ba.created_at
       ) FILTER (WHERE ba.id IS NOT NULL) as bank_accounts,
       COUNT(DISTINCT ld.id) as documents_count,
       o.created_at,
       o.updated_at
   FROM company.organization_details o
   LEFT JOIN company.bank_accounts ba ON o.id = ba.organization_id AND ba.is_active = true
   LEFT JOIN company.legal_documents ld ON o.id = ld.organization_id
   GROUP BY o.id;

   COMMENT ON VIEW company.view_organization_full IS 'Detailed company information with bank accounts';

   -- Email settings view
   DROP VIEW IF EXISTS company.view_email_settings;
   CREATE VIEW company.view_email_settings AS
   SELECT 
       id,
       email_address,
       display_name,
       smtp_server,
       smtp_port,
       smtp_username,
       use_ssl,
       CASE 
           WHEN smtp_password IS NOT NULL THEN true
           ELSE false
       END as has_password,
       CASE 
           WHEN oauth_client_id IS NOT NULL THEN true
           ELSE false
       END as has_oauth,
       is_default,
       is_active,
       created_at,
       updated_at
   FROM company.email_settings;

   COMMENT ON VIEW company.view_email_settings IS 'Email settings without sensitive data';

   -- Email templates view
   DROP VIEW IF EXISTS company.view_email_templates;
   CREATE VIEW company.view_email_templates AS
   SELECT 
       t.id,
       t.name,
       t.code,
       t.subject,
       t.body_html,
       t.body_text,
       t.variables,
       t.description,
       t.is_active,
       u.email as created_by_email,
       u.first_name || ' ' || u.last_name as created_by_name,
       t.created_at,
       t.updated_at
   FROM company.email_templates t
   LEFT JOIN auth.users u ON t.created_by = u.id;

   COMMENT ON VIEW company.view_email_templates IS 'Email templates with creator information';

   -- System settings view
   DROP VIEW IF EXISTS company.view_system_settings;
   CREATE VIEW company.view_system_settings AS
   SELECT 
       s.id,
       s.category,
       s.key,
       s.value,
       s.value_type,
       s.description,
       s.is_public,
       u.email as modified_by,
       s.updated_at
   FROM company.system_settings s
   LEFT JOIN auth.users u ON s.created_by = u.id;

   COMMENT ON VIEW company.view_system_settings IS 'System settings with modified by information';

-- Wialon sync sessions view with details
   DROP VIEW IF EXISTS wialon_sync.view_sync_sessions_full;
   CREATE VIEW wialon_sync.view_sync_sessions_full AS
   SELECT 
       ss.id,
       ss.start_time,
       ss.end_time,
       ss.status,
       ss.total_clients_checked,
       ss.total_objects_checked,
       ss.discrepancies_found,
       EXTRACT(EPOCH FROM (COALESCE(ss.end_time, CURRENT_TIMESTAMP) - ss.start_time)) as duration_seconds,
       u.email as created_by_email,
       u.first_name || ' ' || u.last_name as created_by_name,
       COUNT(DISTINCT sd.id) as total_discrepancies,
       COUNT(DISTINCT CASE WHEN sd.status = 'pending' THEN sd.id END) as pending_discrepancies,
       COUNT(DISTINCT CASE WHEN sd.status = 'approved' THEN sd.id END) as approved_discrepancies,
       ss.created_at,
       ss.updated_at
   FROM wialon_sync.sync_sessions ss
   LEFT JOIN auth.users u ON ss.created_by = u.id
   LEFT JOIN wialon_sync.sync_discrepancies sd ON ss.id = sd.session_id
   GROUP BY ss.id, u.email, u.first_name, u.last_name
   ORDER BY ss.created_at DESC;

   COMMENT ON VIEW wialon_sync.view_sync_sessions_full IS 'Detailed sync sessions with statistics';

   -- Sync discrepancies view with related data
   DROP VIEW IF EXISTS wialon_sync.view_sync_discrepancies_full;
   CREATE VIEW wialon_sync.view_sync_discrepancies_full AS
   SELECT 
       sd.id,
       sd.session_id,
       sd.discrepancy_type,
       sd.entity_type,
       sd.status,
       sd.wialon_entity_data,
       sd.system_entity_data,
       sd.suggested_action,
       sc.id as system_client_id,
       sc.name as system_client_name,
       so.id as system_object_id,
       so.name as system_object_name,
       sug_c.id as suggested_client_id,
       sug_c.name as suggested_client_name,
       sd.resolution_notes,
       res_u.email as resolved_by_email,
       res_u.first_name || ' ' || res_u.last_name as resolved_by_name,
       sd.resolved_at,
       ss.start_time as session_start,
       ss.status as session_status,
       sd.created_at
   FROM wialon_sync.sync_discrepancies sd
   JOIN wialon_sync.sync_sessions ss ON sd.session_id = ss.id
   LEFT JOIN clients.clients sc ON sd.system_client_id = sc.id
   LEFT JOIN wialon.objects so ON sd.system_object_id = so.id
   LEFT JOIN clients.clients sug_c ON sd.suggested_client_id = sug_c.id
   LEFT JOIN auth.users res_u ON sd.resolved_by = res_u.id
   ORDER BY sd.created_at DESC;

   COMMENT ON VIEW wialon_sync.view_sync_discrepancies_full IS 'Detailed sync discrepancies with related entity information';

   -- Active sync rules view
    DROP VIEW IF EXISTS wialon_sync.view_sync_rules_active;
    CREATE VIEW wialon_sync.view_sync_rules_active AS
    SELECT 
        sr.id,
        sr.name,
        sr.description,
        sr.rule_type,
        sr.sql_query,
        sr.parameters,
        sr.execution_order,
        sr.is_active,
        u.email as created_by_email,
       u.first_name || ' ' || u.last_name as created_by_name,
       COUNT(sre.id) as total_executions,
       MAX(sre.execution_start) as last_execution,
       sr.created_at,
       sr.updated_at
   FROM wialon_sync.sync_rules sr
   LEFT JOIN auth.users u ON sr.created_by = u.id
   LEFT JOIN wialon_sync.sync_rule_executions sre ON sr.id = sre.rule_id
   GROUP BY sr.id, u.email, u.first_name, u.last_name, sr.is_active
   ORDER BY sr.execution_order, sr.name;

   COMMENT ON VIEW wialon_sync.view_sync_rules_active IS 'Active synchronization rules with execution statistics';

   -- Equipment mapping view
   DROP VIEW IF EXISTS wialon_sync.view_equipment_mapping_full;
   CREATE VIEW wialon_sync.view_equipment_mapping_full AS
   SELECT 
       em.id,
       em.equipment_name,
       em.wialon_field_name,
       em.system_field_mapping,
       em.validation_rules,
       em.is_active,
       pt.id as product_type_id,
       pt.name as product_type_name,
       pt.code as product_type_code,
       u.email as created_by_email,
       u.first_name || ' ' || u.last_name as created_by_name,
       em.created_at,
       em.updated_at
   FROM wialon_sync.equipment_mapping em
   LEFT JOIN products.product_types pt ON em.product_type_id = pt.id
   LEFT JOIN auth.users u ON em.created_by = u.id
   ORDER BY em.equipment_name;

   COMMENT ON VIEW wialon_sync.view_equipment_mapping_full IS 'Equipment mapping with product type details';

   -- Recent sync logs view
   DROP VIEW IF EXISTS wialon_sync.view_sync_logs_recent;
   CREATE VIEW wialon_sync.view_sync_logs_recent AS
   SELECT 
       sl.id,
       sl.session_id,
       sl.log_level,
       sl.message,
       sl.details,
       sl.created_at,
       ss.status as session_status,
       ss.start_time as session_start
   FROM wialon_sync.sync_logs sl
   JOIN wialon_sync.sync_sessions ss ON sl.session_id = ss.id
   WHERE sl.created_at >= CURRENT_DATE - INTERVAL '30 days'
   ORDER BY sl.created_at DESC;

   COMMENT ON VIEW wialon_sync.view_sync_logs_recent IS 'Recent sync logs from last 30 days';

END $$;