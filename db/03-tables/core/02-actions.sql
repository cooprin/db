-- Create actions related tables
DO $$
BEGIN
    -- Actions table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'core' 
        AND tablename = 'actions'
    ) THEN
        CREATE TABLE core.actions (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Додаємо унікальний індекс для code
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'core' 
            AND tablename = 'actions' 
            AND indexname = 'actions_code_unique'
        ) THEN
            CREATE UNIQUE INDEX actions_code_unique ON core.actions(code);
        END IF;

        COMMENT ON TABLE core.actions IS 'Available actions that can be performed on resources';
        COMMENT ON COLUMN core.actions.code IS 'Unique identifier code for the action';
    END IF;

    -- Resource actions table
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'core' 
        AND tablename = 'resource_actions'
    ) THEN
        CREATE TABLE core.resource_actions (
            resource_id UUID REFERENCES core.resources(id) ON DELETE CASCADE,
            action_id UUID REFERENCES core.actions(id) ON DELETE CASCADE,
            is_default BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (resource_id, action_id)
        );

        -- Додаємо індекси для швидкого пошуку
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'core' 
            AND tablename = 'resource_actions' 
            AND indexname = 'resource_actions_resource_id_idx'
        ) THEN
            CREATE INDEX resource_actions_resource_id_idx ON core.resource_actions(resource_id);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'core' 
            AND tablename = 'resource_actions' 
            AND indexname = 'resource_actions_action_id_idx'
        ) THEN
            CREATE INDEX resource_actions_action_id_idx ON core.resource_actions(action_id);
        END IF;

        COMMENT ON TABLE core.resource_actions IS 'Junction table defining which actions are available for each resource';
        COMMENT ON COLUMN core.resource_actions.is_default IS 'Flag indicating if this action is enabled by default for the resource';
    END IF;
END $$;