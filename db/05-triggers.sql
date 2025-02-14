DO $$
BEGIN
   -- Auth schema triggers
   -- Users table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_users_timestamp'
   ) THEN
       CREATE TRIGGER update_users_timestamp
           BEFORE UPDATE ON auth.users
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Roles table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_roles_timestamp'
   ) THEN
       CREATE TRIGGER update_roles_timestamp
           BEFORE UPDATE ON auth.roles
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Permissions table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_permissions_timestamp'
   ) THEN
       CREATE TRIGGER update_permissions_timestamp
           BEFORE UPDATE ON auth.permissions
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Permission groups table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_permission_groups_timestamp'
   ) THEN
       CREATE TRIGGER update_permission_groups_timestamp
           BEFORE UPDATE ON auth.permission_groups
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Core schema triggers
   -- Resources table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_resources_timestamp'
   ) THEN
       CREATE TRIGGER update_resources_timestamp
           BEFORE UPDATE ON core.resources
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Audit logging triggers
   -- Users table audit
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_users_changes'
   ) THEN
       CREATE TRIGGER audit_users_changes
           AFTER INSERT OR UPDATE OR DELETE ON auth.users
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Roles table audit
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_roles_changes'
   ) THEN
       CREATE TRIGGER audit_roles_changes
           AFTER INSERT OR UPDATE OR DELETE ON auth.roles
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Permissions table audit
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_permissions_changes'
   ) THEN
       CREATE TRIGGER audit_permissions_changes
           AFTER INSERT OR UPDATE OR DELETE ON auth.permissions
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Resources table audit
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_resources_changes'
   ) THEN
       CREATE TRIGGER audit_resources_changes
           AFTER INSERT OR UPDATE OR DELETE ON core.resources
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Products schema triggers
   -- Manufacturers table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_manufacturers_timestamp'
   ) THEN
       CREATE TRIGGER update_manufacturers_timestamp
           BEFORE UPDATE ON products.manufacturers
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Suppliers table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_suppliers_timestamp'
   ) THEN
       CREATE TRIGGER update_suppliers_timestamp
           BEFORE UPDATE ON products.suppliers
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Models table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_models_timestamp'
   ) THEN
       CREATE TRIGGER update_models_timestamp
           BEFORE UPDATE ON products.models
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Products table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_products_timestamp'
   ) THEN
       CREATE TRIGGER update_products_timestamp
           BEFORE UPDATE ON products.products
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Product types table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_product_types_timestamp'
   ) THEN
       CREATE TRIGGER update_product_types_timestamp
           BEFORE UPDATE ON products.product_types
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Product type characteristics table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_product_type_characteristics_timestamp'
   ) THEN
       CREATE TRIGGER update_product_type_characteristics_timestamp
           BEFORE UPDATE ON products.product_type_characteristics
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Product characteristic values table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_product_characteristic_values_timestamp'
   ) THEN
       CREATE TRIGGER update_product_characteristic_values_timestamp
           BEFORE UPDATE ON products.product_characteristic_values
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Warehouses schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_warehouses_timestamp'
   ) THEN
       CREATE TRIGGER update_warehouses_timestamp
           BEFORE UPDATE ON warehouses.warehouses
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_stock_timestamp'
   ) THEN
       CREATE TRIGGER update_stock_timestamp
           BEFORE UPDATE ON warehouses.stock
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Audit triggers for Products schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_manufacturers_changes'
   ) THEN
       CREATE TRIGGER audit_manufacturers_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.manufacturers
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_suppliers_changes'
   ) THEN
       CREATE TRIGGER audit_suppliers_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.suppliers
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_models_changes'
   ) THEN
       CREATE TRIGGER audit_models_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.models
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_products_changes'
   ) THEN
       CREATE TRIGGER audit_products_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.products
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Audit triggers for product types
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_product_types_changes'
   ) THEN
       CREATE TRIGGER audit_product_types_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.product_types
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_product_type_characteristics_changes'
   ) THEN
       CREATE TRIGGER audit_product_type_characteristics_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.product_type_characteristics
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_product_characteristic_values_changes'
   ) THEN
       CREATE TRIGGER audit_product_characteristic_values_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.product_characteristic_values
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Audit triggers for Warehouses schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_warehouses_changes'
   ) THEN
       CREATE TRIGGER audit_warehouses_changes
           AFTER INSERT OR UPDATE OR DELETE ON warehouses.warehouses
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_stock_changes'
   ) THEN
       CREATE TRIGGER audit_stock_changes
           AFTER INSERT OR UPDATE OR DELETE ON warehouses.stock
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_stock_movements_changes'
   ) THEN
       CREATE TRIGGER audit_stock_movements_changes
           AFTER INSERT OR UPDATE OR DELETE ON warehouses.stock_movements
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;
END;
$$;