-- Create schemas if they don't exist
DO $$
\echo 'Starting schema creation...'
BEGIN
    -- Create auth schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
    ) THEN
        CREATE SCHEMA auth;
        \echo 'Auth schema created or exists'
    END IF;

    -- Create core schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core'
    ) THEN
        CREATE SCHEMA core;
        \echo 'Core schema created or exists'
    END IF;

    -- Create audit schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit'
    ) THEN
        CREATE SCHEMA audit;
        \echo 'Audit schema created or exists'
    END IF;

    -- Grant usage to public
    GRANT USAGE ON SCHEMA auth TO PUBLIC;
    GRANT USAGE ON SCHEMA core TO PUBLIC;
    GRANT USAGE ON SCHEMA audit TO PUBLIC;
END $$;