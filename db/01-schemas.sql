-- Create schemas if they don't exist
DO $$
BEGIN
    -- Create auth schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
    ) THEN
        CREATE SCHEMA auth;
    END IF;

    -- Create core schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core'
    ) THEN
        CREATE SCHEMA core;
    END IF;

    -- Create audit schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit'
    ) THEN
        CREATE SCHEMA audit;
    END IF;

    -- Grant usage to public
    GRANT USAGE ON SCHEMA auth TO PUBLIC;
    GRANT USAGE ON SCHEMA core TO PUBLIC;
    GRANT USAGE ON SCHEMA audit TO PUBLIC;
END $$;