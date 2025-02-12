-- Create schemas if they don't exist
DO $$
BEGIN
    -- Create auth schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
    ) THEN
        CREATE SCHEMA auth;
        RAISE NOTICE 'Auth schema created';
    END IF;

    -- Create core schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core'
    ) THEN
        CREATE SCHEMA core;
        RAISE NOTICE 'Core schema created';
    END IF;

    -- Create audit schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit'
    ) THEN
        CREATE SCHEMA audit;
        RAISE NOTICE 'Audit schema created';
    END IF;

    -- Create products schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'products'
    ) THEN
        CREATE SCHEMA products;
        RAISE NOTICE 'Products schema created';
    END IF;

    -- Create warehouses schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'warehouses'
    ) THEN
        CREATE SCHEMA warehouses;
        RAISE NOTICE 'Warehouses schema created';
    END IF;

    -- Grant usage to public
    GRANT USAGE ON SCHEMA auth TO PUBLIC;
    GRANT USAGE ON SCHEMA core TO PUBLIC;
    GRANT USAGE ON SCHEMA audit TO PUBLIC;
    GRANT USAGE ON SCHEMA products TO PUBLIC;
    GRANT USAGE ON SCHEMA warehouses TO PUBLIC;
END $$;