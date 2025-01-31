-- Перевірка і створення бази даних (це потрібно виконувати підключившись до бази postgres)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = current_database()) THEN
        CREATE DATABASE crm_db;
        RAISE NOTICE 'Database crm_db created';
    ELSE
        RAISE NOTICE 'Database crm_db already exists';
    END IF;
END
$$;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to check if table exists
CREATE OR REPLACE FUNCTION create_table_if_not_exists() RETURNS void AS $$
BEGIN
    -- Roles table
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'roles') THEN
        CREATE TABLE roles (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(50) NOT NULL UNIQUE,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Insert default roles only if table was just created
        INSERT INTO roles (name, description) VALUES
            ('admin', 'System administrator');

        RAISE NOTICE 'Table roles created';
    ELSE
        RAISE NOTICE 'Table roles already exists';
    END IF;

    -- Users table
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'users') THEN
        CREATE TABLE users (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            role_id UUID REFERENCES roles(id),
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
    ELSE
        RAISE NOTICE 'Table users already exists';
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
    ELSE
        RAISE NOTICE 'Table audit_logs already exists';
    END IF;





END;
$$ LANGUAGE plpgsql;

-- Execute the function to create tables
SELECT create_table_if_not_exists();

-- Create indexes if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_email') THEN
        CREATE INDEX idx_users_email ON users(email);
        RAISE NOTICE 'Created index on users(email)';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_role') THEN
        CREATE INDEX idx_users_role ON users(role_id);
        RAISE NOTICE 'Created index on users(role_id)';
    END IF;
END $$;

-- Create timestamp update function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ 

-- Create triggers if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_timestamp') THEN
        CREATE TRIGGER update_users_timestamp
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        RAISE NOTICE 'Created update_timestamp trigger for users';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_roles_timestamp') THEN
        CREATE TRIGGER update_roles_timestamp
            BEFORE UPDATE ON roles
            FOR EACH ROW
            EXECUTE FUNCTION update_timestamp();
        RAISE NOTICE 'Created update_timestamp trigger for roles';
    END IF;
END $$;

-- Create helpful views
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
    r.name as role_name,
    r.description as role_description
FROM users u
JOIN roles r ON u.role_id = r.id;

-- Grant necessary permissions
DO $$
BEGIN
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %I', current_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %I', current_user);
    RAISE NOTICE 'Granted permissions to user: %', current_user;
END $$;

-- Create default admin user if not exists
DO $$
DECLARE
    admin_role_id UUID;
BEGIN
    -- Отримуємо ID ролі admin
    SELECT id INTO admin_role_id FROM roles WHERE name = 'admin' LIMIT 1;
    
    -- Перевіряємо чи існує користувач admin
    IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'cooprin@gmail.com') THEN
        -- Створюємо адміністратора
        INSERT INTO users (
            role_id,
            email,
            password,
            first_name,
            last_name,
            is_active
        ) VALUES (
            admin_role_id,
            'cooprin@gmail.com',
            '$2b$10$/8mFF08rYqKd20byMvGwquNb4JrxJ9eDjf8T8WAj1QQifWU6L0q0a', -- хешований пароль '112233'
            'Roman',
            'Tsyupryk',
            true
        );
        RAISE NOTICE 'Default admin user created';
    ELSE
        RAISE NOTICE 'Admin user already exists';
    END IF;
END
$$ language 'plpgsql';
