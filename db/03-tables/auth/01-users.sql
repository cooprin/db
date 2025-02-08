-- Create users table if not exists
DO $$
BEGIN
    -- Перевіряємо чи існує таблиця users в схемі auth
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'auth' 
        AND tablename = 'users'
    ) THEN
        CREATE TABLE auth.users (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            email VARCHAR(255) NOT NULL,
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

        -- Додаємо унікальний індекс для email
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'auth' 
            AND tablename = 'users' 
            AND indexname = 'users_email_unique'
        ) THEN
            CREATE UNIQUE INDEX users_email_unique ON auth.users(email);
        END IF;

        -- Додаємо коментар до таблиці
        COMMENT ON TABLE auth.users IS 'Users table for storing user accounts and profile information';
        COMMENT ON COLUMN auth.users.email IS 'User email address, must be unique';
        COMMENT ON COLUMN auth.users.password IS 'Hashed user password';
        COMMENT ON COLUMN auth.users.is_active IS 'Flag indicating if the user account is active';
        COMMENT ON COLUMN auth.users.last_login IS 'Timestamp of the last user login';
    END IF;
END $$;