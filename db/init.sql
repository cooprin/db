-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Функція для створення таблиць
CREATE OR REPLACE FUNCTION create_table_if_not_exists() RETURNS void AS $$
BEGIN
    -- Таблиця ресурсів системи (для зберігання списку всіх таблиць/модулів до яких надаються права)
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'resources') THEN
        CREATE TABLE resources (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL UNIQUE,
            type VARCHAR(50) NOT NULL, -- 'table', 'module', 'function'
            metadata JSONB DEFAULT '{}',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        RAISE NOTICE 'Table resources created';
    END IF;

    -- Таблиця можливих дій (create, read, update, delete, etc.)
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'actions') THEN
        CREATE TABLE actions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL UNIQUE,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Вставка базових дій
        INSERT INTO actions (name, code, description) VALUES 
            ('Create', 'create', 'Permission to create new records'),
            ('Read', 'read', 'Permission to read records'),
            ('Update', 'update', 'Permission to update records'),
            ('Delete', 'delete', 'Permission to delete records');
            
        RAISE NOTICE 'Table actions created with default values';
    END IF;

    -- Зв'язок ресурсів з можливими діями
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'resource_actions') THEN
        CREATE TABLE resource_actions (
            resource_id UUID REFERENCES resources(id),
            action_id UUID REFERENCES actions(id),
            is_default BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (resource_id, action_id)
        );
        RAISE NOTICE 'Table resource_actions created';
    END IF;

    -- Групи прав (для логічного групування прав)
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'permission_groups') THEN
        CREATE TABLE permission_groups (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Створення базових груп
        INSERT INTO permission_groups (name, description) VALUES 
            ('User Management', 'Permissions related to user management'),
            ('Role Management', 'Permissions related to role management'),
            ('System Management', 'System-level permissions');
            
        RAISE NOTICE 'Table permission_groups created with default groups';
    END IF;

    -- Права доступу
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'permissions') THEN
        CREATE TABLE permissions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            group_id UUID REFERENCES permission_groups(id),
            resource_id UUID REFERENCES resources(id),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL UNIQUE,
            conditions JSONB DEFAULT '{}',
            is_system BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        RAISE NOTICE 'Table permissions created';
    END IF;

    -- Таблиця ролей
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'roles') THEN
        CREATE TABLE roles (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(50) NOT NULL UNIQUE,
            description TEXT,
            is_system BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Створення ролі адміністратора
        INSERT INTO roles (name, description, is_system) VALUES
            ('admin', 'System administrator', true);
            
        RAISE NOTICE 'Table roles created with admin role';
    END IF;

    -- Зв'язок ролей з правами
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'role_permissions') THEN
        CREATE TABLE role_permissions (
            role_id UUID REFERENCES roles(id),
            permission_id UUID REFERENCES permissions(id),
            granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            granted_by UUID,
            PRIMARY KEY (role_id, permission_id)
        );
        RAISE NOTICE 'Table role_permissions created';
    END IF;

    -- Таблиця користувачів
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'users') THEN
        CREATE TABLE users (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            email VARCHAR(255) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            first_name VARCHAR(100),
            last_name VARCHAR(100),
            phone VARCHAR(20),
            avatar_url TEXT,
            is_active BOOLEAN DEFAULT true,
            last_login TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        RAISE NOTICE 'Table users created';
    END IF;

    -- Зв'язок користувачів з ролями
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_roles') THEN
        CREATE TABLE user_roles (
            user_id UUID REFERENCES users(id),
            role_id UUID REFERENCES roles(id),
            granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            granted_by UUID REFERENCES users(id),
            PRIMARY KEY (user_id, role_id)
        );
        RAISE NOTICE 'Table user_roles created';
    END IF;

    -- Таблиця аудиту
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'audit_logs') THEN
        CREATE TABLE audit_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES users(id),
            action_type VARCHAR(50) NOT NULL,
            entity_type VARCHAR(50) NOT NULL,
            entity_id UUID,
            old_values JSONB,
            new_values JSONB,
            ip_address VARCHAR(45),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Створення індексів для таблиці аудиту
        CREATE INDEX idx_audit_user ON audit_logs(user_id);
        CREATE INDEX idx_audit_action ON audit_logs(action_type);
        CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
        CREATE INDEX idx_audit_created ON audit_logs(created_at);

        RAISE NOTICE 'Table audit_logs created with indexes';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Виконання функції створення таблиць
SELECT create_table_if_not_exists();

-- Створення індексів
DO $$ 
BEGIN
    -- Індекси для користувачів
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_email') THEN
        CREATE INDEX idx_users_email ON users(email);
    END IF;
    
    -- Індекси для прав
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_permissions_code') THEN
        CREATE INDEX idx_permissions_code ON permissions(code);
    END IF;
    
    -- Індекси для ресурсів
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_resources_code') THEN
        CREATE INDEX idx_resources_code ON resources(code);
    END IF;
END $$;

-- Функція оновлення часової мітки
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Створення тригерів
DO $$
BEGIN
    -- Тригери для оновлення часових міток
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_timestamp') THEN
        CREATE TRIGGER update_users_timestamp
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_roles_timestamp') THEN
        CREATE TRIGGER update_roles_timestamp
            BEFORE UPDATE ON roles
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
    END IF;
END $$;

-- Створення корисних представлень
CREATE OR REPLACE VIEW view_users_with_roles AS
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.phone,
    u.avatar_url,
    u.is_active,
    u.last_login,
    array_agg(r.name) as role_names
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
GROUP BY u.id, u.email, u.first_name, u.last_name, u.phone, u.avatar_url, u.is_active, u.last_login;

-- Створення адміністратора системи
DO $$
DECLARE
    admin_role_id UUID;
    admin_user_id UUID;
BEGIN
    -- Отримуємо ID ролі admin
    SELECT id INTO admin_role_id FROM roles WHERE name = 'admin' LIMIT 1;
    
    -- Створюємо адміністратора якщо не існує
    IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'cooprin@gmail.com') THEN
        INSERT INTO users (
            email,
            password,
            first_name,
            last_name,
            is_active
        ) VALUES (
            'cooprin@gmail.com',
            '$2b$10$/8mFF08rYqKd20byMvGwquNb4JrxJ9eDjf8T8WAj1QQifWU6L0q0a',
            'Roman',
            'Tsyupryk',
            true
        ) RETURNING id INTO admin_user_id;
        
        -- Призначаємо роль адміністратора
        INSERT INTO user_roles (user_id, role_id) 
        VALUES (admin_user_id, admin_role_id);
        
        RAISE NOTICE 'Default admin user created';
    END IF;
END
$$ LANGUAGE plpgsql;

-- Надання необхідних прав
DO $$
BEGIN
    -- Надаємо права на всі таблиці
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %I', current_user);
    -- Надаємо права на всі послідовності
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %I', current_user);
    -- Надаємо права на всі функції
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO %I', current_user);
END $$;