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

   -- Audit triggers for Company schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_organization_details_changes'
   ) THEN
       CREATE TRIGGER audit_organization_details_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.organization_details
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_bank_accounts_changes'
   ) THEN
       CREATE TRIGGER audit_bank_accounts_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.bank_accounts
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_legal_documents_changes'
   ) THEN
       CREATE TRIGGER audit_legal_documents_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.legal_documents
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_wialon_integration_changes'
   ) THEN
       CREATE TRIGGER audit_wialon_integration_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.wialon_integration
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_email_settings_changes'
   ) THEN
       CREATE TRIGGER audit_email_settings_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.email_settings
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_email_templates_changes'
   ) THEN
       CREATE TRIGGER audit_email_templates_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.email_templates
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_system_settings_changes'
   ) THEN
       CREATE TRIGGER audit_system_settings_changes
           AFTER INSERT OR UPDATE OR DELETE ON company.system_settings
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

   -- Тригер для автоматичного призначення послуг "object_based" клієнтам з об'єктами
   IF NOT EXISTS (
       SELECT 1 FROM pg_proc 
       WHERE proname = 'auto_assign_object_based_services' 
       AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'wialon')
   ) THEN
       CREATE OR REPLACE FUNCTION wialon.auto_assign_object_based_services()
       RETURNS TRIGGER 
       LANGUAGE plpgsql
       AS $function$
       DECLARE
           object_service UUID;
           client_has_objects BOOLEAN;
           day_of_month INTEGER;
       BEGIN
           -- Перевіряємо, чи маємо справу з новим об'єктом чи зміною власника
           IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND OLD.client_id IS DISTINCT FROM NEW.client_id) THEN
               
               -- Перевіряємо чи клієнт вже має інші об'єкти (окрім поточного)
               SELECT EXISTS (
                   SELECT 1 FROM wialon.objects 
                   WHERE client_id = NEW.client_id AND id != NEW.id
               ) INTO client_has_objects;
               
               -- Якщо це перший об'єкт клієнта (або клієнт змінився), то призначаємо послуги
               -- Для першого об'єкта - повне призначення
               -- Для наступних - перевіряємо, чи всі послуги типу object_based вже призначені
               
               -- Знаходимо всі послуги типу "object_based"
               FOR object_service IN 
                   SELECT id FROM services.services 
                   WHERE service_type = 'object_based' AND is_active = true
               LOOP
                   -- Перевіряємо чи клієнт вже має цю послугу
                   IF NOT EXISTS (
                       SELECT 1 FROM services.client_services 
                       WHERE client_id = NEW.client_id 
                       AND service_id = object_service 
                       AND (end_date IS NULL OR end_date >= CURRENT_DATE)
                       AND status = 'active'
                   ) THEN
                       -- Призначаємо послугу
                       INSERT INTO services.client_services (
                           client_id, service_id, start_date, status, notes
                       ) VALUES (
                           NEW.client_id, 
                           object_service, 
                           CURRENT_DATE, 
                           'active', 
                           'Автоматично призначено при додаванні об''єкта ' || NEW.name
                       );
                   END IF;
               END LOOP;
           END IF;
           
           RETURN NEW;
       END;
       $function$;

       -- Створення тригера
       DROP TRIGGER IF EXISTS auto_assign_services_trigger ON wialon.objects;
       
       CREATE TRIGGER auto_assign_services_trigger
           AFTER INSERT OR UPDATE OF client_id ON wialon.objects
           FOR EACH ROW
           EXECUTE FUNCTION wialon.auto_assign_object_based_services();

       RAISE NOTICE 'Trigger for automatic service assignment created';
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

    -- Trigger for tracking object status changes
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'track_object_status_changes' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'wialon')
    ) THEN
        CREATE OR REPLACE FUNCTION wialon.track_object_status_changes()
        RETURNS TRIGGER 
        LANGUAGE plpgsql
        AS $function$
        BEGIN
            -- Якщо статус змінився
            IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
                -- Закриваємо попередній запис статусу
                UPDATE wialon.object_status_history 
                SET end_date = CURRENT_DATE
                WHERE object_id = NEW.id AND end_date IS NULL;
                
                -- Додаємо новий запис з поточним статусом
                INSERT INTO wialon.object_status_history (
                    object_id, status, start_date, created_by
                ) VALUES (
                    NEW.id, 
                    NEW.status, 
                    CURRENT_DATE, 
                    NULL  -- Тут можна додати current_user якщо є така можливість
                );
            ELSIF (TG_OP = 'INSERT') THEN
                -- Для нового об'єкта додаємо початковий запис статусу
                INSERT INTO wialon.object_status_history (
                    object_id, status, start_date, created_by
                ) VALUES (
                    NEW.id, 
                    NEW.status, 
                    CURRENT_DATE, 
                    NULL  -- Тут можна додати current_user якщо є така можливість
                );
            END IF;
            
            RETURN NEW;
        END;
        $function$;

        -- Create the trigger
        DROP TRIGGER IF EXISTS track_object_status_changes_trigger ON wialon.objects;
        
        CREATE TRIGGER track_object_status_changes_trigger
            AFTER INSERT OR UPDATE OF status ON wialon.objects
            FOR EACH ROW
            EXECUTE FUNCTION wialon.track_object_status_changes();

        RAISE NOTICE 'Trigger for tracking object status changes created';
    END IF;

    -- Trigger for updating object status history
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_object_status_history_timestamp'
    ) THEN
        CREATE TRIGGER update_object_status_history_timestamp
            BEFORE UPDATE ON wialon.object_status_history
            FOR EACH ROW
            EXECUTE FUNCTION core.update_timestamp();
    END IF;

    -- Audit trigger for object status history
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'audit_object_status_history_changes'
    ) THEN
        CREATE TRIGGER audit_object_status_history_changes
            AFTER INSERT OR UPDATE OR DELETE ON wialon.object_status_history
            FOR EACH ROW
            EXECUTE FUNCTION audit.log_table_change();
    END IF;

   -- Функція для оновлення обчислюваної вартості послуг при зміні тарифів
   IF NOT EXISTS (
       SELECT 1 FROM pg_proc 
       WHERE proname = 'update_object_based_service_prices' 
       AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'billing')
   ) THEN
       CREATE OR REPLACE FUNCTION billing.update_object_based_service_prices()
       RETURNS TRIGGER 
       LANGUAGE plpgsql
       AS $function$
       DECLARE
           client_id_var UUID;
       BEGIN
           -- Отримуємо client_id для об'єкта
           SELECT o.client_id INTO client_id_var
           FROM wialon.objects o
           WHERE o.id = NEW.object_id;
           
           -- Якщо знайдено клієнта, перевіряємо наявність невиставлених рахунків
           IF client_id_var IS NOT NULL THEN
               -- Оновлюємо рахунки, які ще не оплачені
               -- Це стосується лише рахунків зі статусами 'draft' або 'issued'
               UPDATE services.invoices i
               SET total_amount = (
                   SELECT SUM(ii.total_price)
                   FROM services.invoice_items ii
                   WHERE ii.invoice_id = i.id
               )
               WHERE i.client_id = client_id_var
               AND i.status IN ('draft', 'issued')
               AND EXISTS (
                   SELECT 1 FROM services.invoice_items ii
                   JOIN services.services s ON ii.service_id = s.id
                   WHERE ii.invoice_id = i.id
                   AND s.service_type = 'object_based'
               );
           END IF;
           
           RETURN NEW;
       END;
       $function$;

       -- Створення тригера
       DROP TRIGGER IF EXISTS update_service_prices_trigger ON billing.object_tariffs;

       CREATE TRIGGER update_service_prices_trigger
           AFTER INSERT OR UPDATE ON billing.object_tariffs
           FOR EACH ROW
           EXECUTE FUNCTION billing.update_object_based_service_prices();

       RAISE NOTICE 'Trigger for updating object-based service prices created';
   END IF;

   -- Invoice templates table
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_invoice_templates_timestamp'
   ) THEN
       CREATE TRIGGER update_invoice_templates_timestamp
           BEFORE UPDATE ON billing.invoice_templates
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Audit trigger for invoice templates
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_invoice_templates_changes'
   ) THEN
       CREATE TRIGGER audit_invoice_templates_changes
           AFTER INSERT OR UPDATE OR DELETE ON billing.invoice_templates
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   -- Company schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_organization_details_timestamp'
   ) THEN
       CREATE TRIGGER update_organization_details_timestamp
           BEFORE UPDATE ON company.organization_details
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_bank_accounts_timestamp'
   ) THEN
       CREATE TRIGGER update_bank_accounts_timestamp
           BEFORE UPDATE ON company.bank_accounts
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_legal_documents_timestamp'
   ) THEN
       CREATE TRIGGER update_legal_documents_timestamp
           BEFORE UPDATE ON company.legal_documents
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_wialon_integration_timestamp'
   ) THEN
       CREATE TRIGGER update_wialon_integration_timestamp
           BEFORE UPDATE ON company.wialon_integration
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_email_settings_timestamp'
   ) THEN
       CREATE TRIGGER update_email_settings_timestamp
           BEFORE UPDATE ON company.email_settings
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_email_templates_timestamp'
   ) THEN
       CREATE TRIGGER update_email_templates_timestamp
           BEFORE UPDATE ON company.email_templates
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_email_queue_timestamp'
   ) THEN
       CREATE TRIGGER update_email_queue_timestamp
           BEFORE UPDATE ON company.email_queue
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_system_settings_timestamp'
   ) THEN
       CREATE TRIGGER update_system_settings_timestamp
           BEFORE UPDATE ON company.system_settings
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

-- Wialon_sync schema triggers
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_sync_sessions_timestamp'
   ) THEN
       CREATE TRIGGER update_sync_sessions_timestamp
           BEFORE UPDATE ON wialon_sync.sync_sessions
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_sync_rules_timestamp'
   ) THEN
       CREATE TRIGGER update_sync_rules_timestamp
           BEFORE UPDATE ON wialon_sync.sync_rules
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'update_equipment_mapping_timestamp'
   ) THEN
       CREATE TRIGGER update_equipment_mapping_timestamp
           BEFORE UPDATE ON wialon_sync.equipment_mapping
           FOR EACH ROW
           EXECUTE FUNCTION core.update_timestamp();
   END IF;

   -- Audit triggers for Wialon_sync schema
   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_sync_sessions_changes'
   ) THEN
       CREATE TRIGGER audit_sync_sessions_changes
           AFTER INSERT OR UPDATE OR DELETE ON wialon_sync.sync_sessions
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_sync_discrepancies_changes'
   ) THEN
       CREATE TRIGGER audit_sync_discrepancies_changes
           AFTER INSERT OR UPDATE OR DELETE ON wialon_sync.sync_discrepancies
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_sync_rules_changes'
   ) THEN
       CREATE TRIGGER audit_sync_rules_changes
           AFTER INSERT OR UPDATE OR DELETE ON wialon_sync.sync_rules
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

   IF NOT EXISTS (
       SELECT 1 FROM pg_trigger 
       WHERE tgname = 'audit_equipment_mapping_changes'
   ) THEN
       CREATE TRIGGER audit_equipment_mapping_changes
           AFTER INSERT OR UPDATE OR DELETE ON wialon_sync.equipment_mapping
           FOR EACH ROW
           EXECUTE FUNCTION audit.log_table_change();
   END IF;

END;

$$;