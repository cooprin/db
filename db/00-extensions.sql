-- Check and create required extensions
DO $$
BEGIN
    -- UUID generation
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp'
    ) THEN
        CREATE EXTENSION "uuid-ossp";
    END IF;

    -- LTREE for hierarchical data
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'ltree'
    ) THEN
        CREATE EXTENSION "ltree";
    END IF;

    -- PGCRYPTO for password hashing
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'
    ) THEN
        CREATE EXTENSION "pgcrypto";
    END IF;
END $$;