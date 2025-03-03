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

   -- Characteristic types table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_characteristic_types_timestamp'
   ) THEN
       CREATE TRIGGER update_characteristic_types_timestamp
           BEFORE UPDATE ON products.characteristic_types
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Додати тригер аудиту
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_characteristic_types_changes'
   ) THEN
       CREATE TRIGGER audit_characteristic_types_changes
           AFTER INSERT OR UPDATE OR DELETE ON products.characteristic_types
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Тригерна функція для перевірки моделі продукту
   IF NOT EXISTS (
       SELECT 1 FROM pg_proc 
       WHERE proname = 'check_product_type_match' 
       AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'products')
   ) THEN
       CREATE OR REPLACE FUNCTION products.check_product_type_match()
       RETURNS TRIGGER 
       LANGUAGE plpgsql
       AS $function$
       BEGIN
           IF NOT EXISTS (SELECT 1 FROM products.models WHERE id = NEW.model_id) THEN
               RAISE EXCEPTION 'Модель не знайдено';
           END IF;
           RETURN NEW;
       END;
       $function$;

       -- Створення тригера для перевірки моделі
       DROP TRIGGER IF EXISTS check_product_type_match_trigger ON products.products;
       
       CREATE TRIGGER check_product_type_match_trigger
           BEFORE INSERT OR UPDATE ON products.products
           FOR EACH ROW
           EXECUTE FUNCTION products.check_product_type_match();

       RAISE NOTICE 'Тригер перевірки моделі продукту створено';
   END IF;

   -- Add index for models product type
   IF NOT EXISTS (
       SELECT 1 FROM pg_indexes 
       WHERE schemaname = 'products' 
       AND tablename = 'models' 
       AND indexname = 'idx_models_product_type'
   ) THEN
       CREATE INDEX idx_models_product_type ON products.models(product_type_id);
   END IF;

   -- Clients schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_clients_timestamp'
   ) THEN
       CREATE TRIGGER update_clients_timestamp
           BEFORE UPDATE ON clients.clients
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_client_documents_timestamp'
   ) THEN
       CREATE TRIGGER update_client_documents_timestamp
           BEFORE UPDATE ON clients.client_documents
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_contacts_timestamp'
   ) THEN
       CREATE TRIGGER update_contacts_timestamp
           BEFORE UPDATE ON clients.contacts
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Wialon schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_wialon_objects_timestamp'
   ) THEN
       CREATE TRIGGER update_wialon_objects_timestamp
           BEFORE UPDATE ON wialon.objects
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_object_attributes_timestamp'
   ) THEN
       CREATE TRIGGER update_object_attributes_timestamp
           BEFORE UPDATE ON wialon.object_attributes
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Billing schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_tariffs_timestamp'
   ) THEN
       CREATE TRIGGER update_tariffs_timestamp
           BEFORE UPDATE ON billing.tariffs
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Services schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_services_timestamp'
   ) THEN
       CREATE TRIGGER update_services_timestamp
           BEFORE UPDATE ON services.services
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_client_services_timestamp'
   ) THEN
       CREATE TRIGGER update_client_services_timestamp
           BEFORE UPDATE ON services.client_services
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_invoices_timestamp'
   ) THEN
       CREATE TRIGGER update_invoices_timestamp
           BEFORE UPDATE ON services.invoices
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Audit triggers for Clients schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_clients_changes'
   ) THEN
       CREATE TRIGGER audit_clients_changes
           AFTER INSERT OR UPDATE OR DELETE ON clients.clients
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_client_documents_changes'
   ) THEN
       CREATE TRIGGER audit_client_documents_changes
           AFTER INSERT OR UPDATE OR DELETE ON clients.client_documents
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_contacts_changes'
   ) THEN
       CREATE TRIGGER audit_contacts_changes
           AFTER INSERT OR UPDATE OR DELETE ON clients.contacts
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Audit triggers for Wialon schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_wialon_objects_changes'
   ) THEN
       CREATE TRIGGER audit_wialon_objects_changes
           AFTER INSERT OR UPDATE OR DELETE ON wialon.objects
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_object_ownership_history_changes'
   ) THEN
       CREATE TRIGGER audit_object_ownership_history_changes
           AFTER INSERT OR UPDATE OR DELETE ON wialon.object_ownership_history
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Audit triggers for Billing schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_tariffs_changes'
   ) THEN
       CREATE TRIGGER audit_tariffs_changes
           AFTER INSERT OR UPDATE OR DELETE ON billing.tariffs
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_object_tariffs_changes'
   ) THEN
       CREATE TRIGGER audit_object_tariffs_changes
           AFTER INSERT OR UPDATE OR DELETE ON billing.object_tariffs
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_payments_changes'
   ) THEN
       CREATE TRIGGER audit_payments_changes
           AFTER INSERT OR UPDATE OR DELETE ON billing.payments
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Audit triggers for Services schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_services_changes'
   ) THEN
       CREATE TRIGGER audit_services_changes
           AFTER INSERT OR UPDATE OR DELETE ON services.services
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_client_services_changes'
   ) THEN
       CREATE TRIGGER audit_client_services_changes
           AFTER INSERT OR UPDATE OR DELETE ON services.client_services
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_invoices_changes'
   ) THEN
       CREATE TRIGGER audit_invoices_changes
           AFTER INSERT OR UPDATE OR DELETE ON services.invoices
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Trigger to update object ownership
   IF NOT EXISTS (
       SELECT 1 FROM pg_proc 
       WHERE proname = 'update_object_ownership' 
       AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'wialon')
   ) THEN
       CREATE OR REPLACE FUNCTION wialon.update_object_ownership()
       RETURNS TRIGGER 
       LANGUAGE plpgsql
       AS $function$
       BEGIN
           -- If client changed, close the previous ownership record
           IF (TG_OP = 'UPDATE' AND OLD.client_id IS DISTINCT FROM NEW.client_id) THEN
               UPDATE wialon.object_ownership_history 
               SET end_date = CURRENT_DATE
               WHERE object_id = NEW.id AND end_date IS NULL;
               
               -- Insert a new ownership record
               INSERT INTO wialon.object_ownership_history
                  (object_id, client_id, start_date, created_by)
               VALUES
                  (NEW.id, NEW.client_id, CURRENT_DATE, 
                   coalesce(current_setting('audit.user_id', false)::uuid, '00000000-0000-0000-0000-000000000000'::uuid));
           END IF;

           -- For new objects, create an initial ownership record
           IF (TG_OP = 'INSERT') THEN
               INSERT INTO wialon.object_ownership_history
                  (object_id, client_id, start_date, created_by)
               VALUES
                  (NEW.id, NEW.client_id, CURRENT_DATE, 
                   coalesce(current_setting('audit.user_id', false)::uuid, '00000000-0000-0000-0000-000000000000'::uuid));
           END IF;

           RETURN NEW;
       END;
       $function$;

       -- Create the trigger
       DROP TRIGGER IF EXISTS update_object_ownership_trigger ON wialon.objects;
       
       CREATE TRIGGER update_object_ownership_trigger
           AFTER INSERT OR UPDATE ON wialon.objects
           FOR EACH ROW
           EXECUTE FUNCTION wialon.update_object_ownership();

       RAISE NOTICE 'Trigger for managing object ownership created';
   END IF;

   -- Trigger to handle tariff changes
   IF NOT EXISTS (
       SELECT 1 FROM pg_proc 
       WHERE proname = 'handle_tariff_change' 
       AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'billing')
   ) THEN
       CREATE OR REPLACE FUNCTION billing.handle_tariff_change()
       RETURNS TRIGGER 
       LANGUAGE plpgsql
       AS $function$
       BEGIN
           -- Close previous active tariff when adding a new one
           IF (TG_OP = 'INSERT') THEN
               UPDATE billing.object_tariffs
               SET effective_to = NEW.effective_from - INTERVAL '1 day'
               WHERE object_id = NEW.object_id 
                 AND effective_to IS NULL
                 AND id != NEW.id;
           END IF;

           RETURN NEW;
       END;
       $function$;

       -- Create the trigger
       DROP TRIGGER IF EXISTS handle_tariff_change_trigger ON billing.object_tariffs;
       
       CREATE TRIGGER handle_tariff_change_trigger
           AFTER INSERT ON billing.object_tariffs
           FOR EACH ROW
           EXECUTE FUNCTION billing.handle_tariff_change();

       RAISE NOTICE 'Trigger for handling tariff changes created';
   END IF;

END;
$$;