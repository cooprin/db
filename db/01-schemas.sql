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

    -- Create clients schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'clients'
    ) THEN
        CREATE SCHEMA clients;
        RAISE NOTICE 'Clients schema created';
    END IF;

    -- Create services schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'services'
    ) THEN
        CREATE SCHEMA services;
        RAISE NOTICE 'Services schema created';
    END IF;

    -- Create billing schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'billing'
    ) THEN
        CREATE SCHEMA billing;
        RAISE NOTICE 'Billing schema created';
    END IF;

    -- Create wialon schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wialon'
    ) THEN
        CREATE SCHEMA wialon;
        RAISE NOTICE 'Wialon schema created';
    END IF;

    -- Create company schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'company'
    ) THEN
        CREATE SCHEMA company;
        RAISE NOTICE 'Company schema created';
    END IF;

    -- Grant usage to public
    GRANT USAGE ON SCHEMA auth TO PUBLIC;
    GRANT USAGE ON SCHEMA core TO PUBLIC;
    GRANT USAGE ON SCHEMA audit TO PUBLIC;
    GRANT USAGE ON SCHEMA products TO PUBLIC;
    GRANT USAGE ON SCHEMA warehouses TO PUBLIC;
    GRANT USAGE ON SCHEMA clients TO PUBLIC;
    GRANT USAGE ON SCHEMA services TO PUBLIC;
    GRANT USAGE ON SCHEMA billing TO PUBLIC;
    GRANT USAGE ON SCHEMA wialon TO PUBLIC;
    GRANT USAGE ON SCHEMA company TO PUBLIC;
END $$;