-- Helper functions for the database
DO $$
BEGIN
    -- Add constraint if not exists function
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'add_constraint_if_not_exists'
    ) THEN
        CREATE OR REPLACE FUNCTION core.add_constraint_if_not_exists(
            t_name text, c_name text, c_sql text
        ) RETURNS void AS $func$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 
                FROM information_schema.constraint_column_usage 
                WHERE constraint_name = c_name
            ) THEN
                EXECUTE 'ALTER TABLE ' || t_name || ' ADD CONSTRAINT ' || c_name || ' ' || c_sql;
            END IF;
        END;
        $func$ LANGUAGE plpgsql;
    END IF;

    -- Update timestamp function
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'update_timestamp'
    ) THEN
        CREATE OR REPLACE FUNCTION core.update_timestamp()
        RETURNS TRIGGER AS $func$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql;
    END IF;
END $$;