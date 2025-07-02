DO $$
BEGIN
    -- Report definitions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'reports' AND table_name = 'report_definitions'
    ) THEN
        CREATE TABLE reports.report_definitions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            code VARCHAR(100) NOT NULL UNIQUE,
            description TEXT,
            sql_query TEXT NOT NULL,
            parameters_schema JSONB DEFAULT '{}',
            output_format VARCHAR(50) DEFAULT 'table',
            chart_config JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            execution_timeout INTEGER DEFAULT 30,
            cache_duration INTEGER DEFAULT 0,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_report_definitions_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_output_format CHECK (output_format IN ('table', 'chart', 'export', 'both')),
            CONSTRAINT chk_execution_timeout CHECK (execution_timeout > 0 AND execution_timeout <= 300),
            CONSTRAINT chk_cache_duration CHECK (cache_duration >= 0)
        );

        CREATE INDEX idx_report_definitions_code ON reports.report_definitions(code);
        CREATE INDEX idx_report_definitions_active ON reports.report_definitions(is_active);
        
        COMMENT ON TABLE reports.report_definitions IS 'Report definitions with SQL queries and configuration';
        COMMENT ON COLUMN reports.report_definitions.code IS 'Unique code for report identification';
        COMMENT ON COLUMN reports.report_definitions.sql_query IS 'SQL query for report data';
        COMMENT ON COLUMN reports.report_definitions.parameters_schema IS 'JSON schema for report parameters';
        COMMENT ON COLUMN reports.report_definitions.execution_timeout IS 'Maximum execution time in seconds';
        COMMENT ON COLUMN reports.report_definitions.cache_duration IS 'Cache duration in minutes (0 = no cache)';
        RAISE NOTICE 'Report definitions table created';
    END IF;

    -- Report parameters table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'reports' AND table_name = 'report_parameters'
    ) THEN
        CREATE TABLE reports.report_parameters (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID NOT NULL,
            parameter_name VARCHAR(100) NOT NULL,
            parameter_type VARCHAR(50) NOT NULL,
            display_name VARCHAR(255) NOT NULL,
            description TEXT,
            is_required BOOLEAN DEFAULT false,
            default_value TEXT,
            validation_rules JSONB DEFAULT '{}',
            options JSONB DEFAULT '[]',
            ordering INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_report_parameters_report FOREIGN KEY (report_id) 
                REFERENCES reports.report_definitions(id) ON DELETE CASCADE,
            CONSTRAINT unique_report_parameter UNIQUE(report_id, parameter_name),
            CONSTRAINT chk_parameter_type CHECK (parameter_type IN ('text', 'number', 'date', 'datetime', 'select', 'multiselect', 'boolean', 'client_id', 'user_id'))
        );

        CREATE INDEX idx_report_parameters_report ON reports.report_parameters(report_id);
        CREATE INDEX idx_report_parameters_ordering ON reports.report_parameters(report_id, ordering);
        
        COMMENT ON TABLE reports.report_parameters IS 'Parameters configuration for reports';
        COMMENT ON COLUMN reports.report_parameters.parameter_type IS 'Type of parameter for UI rendering';
        COMMENT ON COLUMN reports.report_parameters.validation_rules IS 'JSON validation rules for parameter';
        COMMENT ON COLUMN reports.report_parameters.options IS 'Options for select/multiselect parameters';
        RAISE NOTICE 'Report parameters table created';
    END IF;

    -- Page report assignments table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'reports' AND table_name = 'page_report_assignments'
    ) THEN
        CREATE TABLE reports.page_report_assignments (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID NOT NULL,
            page_identifier VARCHAR(100) NOT NULL,
            page_title VARCHAR(255),
            display_order INTEGER DEFAULT 0,
            is_visible BOOLEAN DEFAULT true,
            auto_execute BOOLEAN DEFAULT false,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_page_assignments_report FOREIGN KEY (report_id) 
                REFERENCES reports.report_definitions(id) ON DELETE CASCADE,
            CONSTRAINT fk_page_assignments_user FOREIGN KEY (created_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT unique_page_report UNIQUE(report_id, page_identifier)
        );

        CREATE INDEX idx_page_assignments_page ON reports.page_report_assignments(page_identifier);
        CREATE INDEX idx_page_assignments_visible ON reports.page_report_assignments(page_identifier, is_visible, display_order);
        
        COMMENT ON TABLE reports.page_report_assignments IS 'Assignment of reports to specific pages';
        COMMENT ON COLUMN reports.page_report_assignments.page_identifier IS 'Unique identifier of the page (e.g., clients, objects, billing)';
        COMMENT ON COLUMN reports.page_report_assignments.auto_execute IS 'Whether to execute report automatically when page loads';
        RAISE NOTICE 'Page report assignments table created';
    END IF;

    -- Report execution history table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'reports' AND table_name = 'report_execution_history'
    ) THEN
        CREATE TABLE reports.report_execution_history (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID NOT NULL,
            executed_by UUID,
            executed_by_type VARCHAR(20) DEFAULT 'staff',
            page_identifier VARCHAR(100),
            parameters JSONB DEFAULT '{}',
            execution_time DECIMAL(10,3),
            rows_returned INTEGER,
            status VARCHAR(50) DEFAULT 'success',
            error_message TEXT,
            cache_hit BOOLEAN DEFAULT false,
            ip_address INET,
            user_agent TEXT,
            executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_execution_history_report FOREIGN KEY (report_id) 
                REFERENCES reports.report_definitions(id) ON DELETE CASCADE,
            CONSTRAINT fk_execution_history_user FOREIGN KEY (executed_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_executed_by_type CHECK (executed_by_type IN ('staff', 'client', 'system')),
            CONSTRAINT chk_execution_status CHECK (status IN ('success', 'error', 'timeout', 'cancelled'))
        );

        CREATE INDEX idx_execution_history_report ON reports.report_execution_history(report_id);
        CREATE INDEX idx_execution_history_executed_at ON reports.report_execution_history(executed_at DESC);
        CREATE INDEX idx_execution_history_status ON reports.report_execution_history(status);
        CREATE INDEX idx_execution_history_user ON reports.report_execution_history(executed_by, executed_at DESC);
        
        COMMENT ON TABLE reports.report_execution_history IS 'History of report executions with performance metrics';
        COMMENT ON COLUMN reports.report_execution_history.execution_time IS 'Execution time in seconds';
        COMMENT ON COLUMN reports.report_execution_history.cache_hit IS 'Whether result was served from cache';
        RAISE NOTICE 'Report execution history table created';
    END IF;

    -- Report permissions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'reports' AND table_name = 'report_permissions'
    ) THEN
        CREATE TABLE reports.report_permissions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID NOT NULL,
            role_id UUID,
            user_id UUID,
            client_id UUID,
            permission_type VARCHAR(50) NOT NULL,
            granted_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_report_permissions_report FOREIGN KEY (report_id) 
                REFERENCES reports.report_definitions(id) ON DELETE CASCADE,
            CONSTRAINT fk_report_permissions_role FOREIGN KEY (role_id) 
                REFERENCES auth.roles(id) ON DELETE CASCADE,
            CONSTRAINT fk_report_permissions_user FOREIGN KEY (user_id) 
                REFERENCES auth.users(id) ON DELETE CASCADE,
            CONSTRAINT fk_report_permissions_client FOREIGN KEY (client_id) 
                REFERENCES clients.clients(id) ON DELETE CASCADE,
            CONSTRAINT fk_report_permissions_granted_by FOREIGN KEY (granted_by) 
                REFERENCES auth.users(id) ON DELETE SET NULL,
            CONSTRAINT chk_permission_type CHECK (permission_type IN ('execute', 'view', 'export', 'manage')),
            CONSTRAINT chk_single_target CHECK (
                (role_id IS NOT NULL AND user_id IS NULL AND client_id IS NULL) OR
                (role_id IS NULL AND user_id IS NOT NULL AND client_id IS NULL) OR
                (role_id IS NULL AND user_id IS NULL AND client_id IS NOT NULL)
            )
        );

        CREATE INDEX idx_report_permissions_report ON reports.report_permissions(report_id);
        CREATE INDEX idx_report_permissions_role ON reports.report_permissions(role_id);
        CREATE INDEX idx_report_permissions_user ON reports.report_permissions(user_id);
        CREATE INDEX idx_report_permissions_client ON reports.report_permissions(client_id);
        
        COMMENT ON TABLE reports.report_permissions IS 'Fine-grained permissions for report access';
        COMMENT ON COLUMN reports.report_permissions.permission_type IS 'Type of permission: execute, view, export, manage';
        RAISE NOTICE 'Report permissions table created';
    END IF;

    -- Report cache table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'reports' AND table_name = 'report_cache'
    ) THEN
        CREATE TABLE reports.report_cache (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            report_id UUID NOT NULL,
            parameters_hash VARCHAR(64) NOT NULL,
            cache_data JSONB NOT NULL,
            execution_time DECIMAL(10,3),
            rows_count INTEGER,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
            CONSTRAINT fk_report_cache_report FOREIGN KEY (report_id) 
                REFERENCES reports.report_definitions(id) ON DELETE CASCADE,
            CONSTRAINT unique_cache_entry UNIQUE(report_id, parameters_hash)
        );

        CREATE INDEX idx_report_cache_expires ON reports.report_cache(expires_at);
        CREATE INDEX idx_report_cache_lookup ON reports.report_cache(report_id, parameters_hash);
        
        COMMENT ON TABLE reports.report_cache IS 'Cached report results for performance optimization';
        COMMENT ON COLUMN reports.report_cache.parameters_hash IS 'Hash of parameters for cache key';
        RAISE NOTICE 'Report cache table created';
    END IF;

END $$;