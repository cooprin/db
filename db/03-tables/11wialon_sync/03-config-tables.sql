DO $$
BEGIN
    -- Sync rules table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'sync_rules'
    ) THEN
        CREATE TABLE wialon_sync.sync_rules (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            rule_type VARCHAR(100) NOT NULL,
            sql_query TEXT NOT NULL,
            parameters JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            execution_order INTEGER DEFAULT 0,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_sync_rules_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_rule_type CHECK (rule_type IN (
                'client_mapping', 'object_mapping', 'equipment_check', 
                'name_comparison', 'owner_validation', 'custom'
            ))
        );
        
        CREATE INDEX idx_sync_rules_type ON wialon_sync.sync_rules(rule_type);
        CREATE INDEX idx_sync_rules_active ON wialon_sync.sync_rules(is_active);
        CREATE INDEX idx_sync_rules_order ON wialon_sync.sync_rules(execution_order);
        
        COMMENT ON TABLE wialon_sync.sync_rules IS 'Configurable rules for synchronization process';
        COMMENT ON COLUMN wialon_sync.sync_rules.rule_type IS 'Type of synchronization rule';
        COMMENT ON COLUMN wialon_sync.sync_rules.sql_query IS 'Editable SQL query for rule execution';
        COMMENT ON COLUMN wialon_sync.sync_rules.parameters IS 'Rule parameters in JSON format';
        COMMENT ON COLUMN wialon_sync.sync_rules.execution_order IS 'Order of rule execution (lower numbers first)';
        RAISE NOTICE 'Sync rules table created';
    END IF;

    -- Equipment mapping table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'equipment_mapping'
    ) THEN
        CREATE TABLE wialon_sync.equipment_mapping (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            product_type_id UUID,
            equipment_name VARCHAR(255) NOT NULL,
            wialon_field_name VARCHAR(100) NOT NULL,
            system_field_mapping JSONB NOT NULL,
            validation_rules JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_equipment_mapping_product_type FOREIGN KEY (product_type_id) 
                REFERENCES products.product_types(id) ON DELETE SET NULL,
            CONSTRAINT fk_equipment_mapping_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL
        );
        
        CREATE INDEX idx_equipment_mapping_product_type ON wialon_sync.equipment_mapping(product_type_id);
        CREATE INDEX idx_equipment_mapping_wialon_field ON wialon_sync.equipment_mapping(wialon_field_name);
        CREATE INDEX idx_equipment_mapping_active ON wialon_sync.equipment_mapping(is_active);
        
        COMMENT ON TABLE wialon_sync.equipment_mapping IS 'Mapping between product types and Wialon fields';
        COMMENT ON COLUMN wialon_sync.equipment_mapping.equipment_name IS 'Human-readable equipment type name';
        COMMENT ON COLUMN wialon_sync.equipment_mapping.wialon_field_name IS 'Field name in Wialon API response';
        COMMENT ON COLUMN wialon_sync.equipment_mapping.system_field_mapping IS 'Mapping to system fields in JSON format';
        COMMENT ON COLUMN wialon_sync.equipment_mapping.validation_rules IS 'Validation rules for field values in JSON format';
        RAISE NOTICE 'Equipment mapping table created';
    END IF;

    -- Sync rule execution history
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'wialon_sync' AND table_name = 'sync_rule_executions'
    ) THEN
        CREATE TABLE wialon_sync.sync_rule_executions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id UUID NOT NULL,
            rule_id UUID NOT NULL,
            execution_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            execution_end TIMESTAMP WITH TIME ZONE,
            status VARCHAR(50) DEFAULT 'running',
            records_processed INTEGER DEFAULT 0,
            discrepancies_found INTEGER DEFAULT 0,
            error_message TEXT,
            execution_details JSONB,
            CONSTRAINT fk_rule_executions_session FOREIGN KEY (session_id) 
                REFERENCES wialon_sync.sync_sessions(id) ON DELETE CASCADE,
            CONSTRAINT fk_rule_executions_rule FOREIGN KEY (rule_id) 
                REFERENCES wialon_sync.sync_rules(id) ON DELETE CASCADE,
            CONSTRAINT chk_execution_status CHECK (status IN ('running', 'completed', 'failed', 'skipped'))
        );
        
        CREATE INDEX idx_rule_executions_session ON wialon_sync.sync_rule_executions(session_id);
        CREATE INDEX idx_rule_executions_rule ON wialon_sync.sync_rule_executions(rule_id);
        CREATE INDEX idx_rule_executions_status ON wialon_sync.sync_rule_executions(status);
        
        COMMENT ON TABLE wialon_sync.sync_rule_executions IS 'History of sync rule executions';
        RAISE NOTICE 'Sync rule executions table created';
    END IF;
END $$;