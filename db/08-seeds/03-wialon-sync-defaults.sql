-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert default wialon_sync data
DO $$
BEGIN
-- Insert default sync rules with CORRECTED SQL queries
    INSERT INTO wialon_sync.sync_rules (name, description, rule_type, sql_query, parameters, execution_order)
    SELECT * FROM (VALUES
        (
            'New Clients Detection',
            'Detect new clients from Wialon that don''t exist in system',
            'client_mapping',
            'INSERT INTO wialon_sync.sync_discrepancies 
            (session_id, discrepancy_type, entity_type, wialon_entity_data, status)
            SELECT 
                $1,
                ''new_client'',
                ''client'',
                jsonb_build_object(
                    ''wialon_id'', twc.wialon_id,
                    ''name'', twc.name,
                    ''full_name'', twc.full_name,
                    ''description'', twc.description,
                    ''wialon_username'', twc.wialon_username
                ),
                ''pending''
            FROM wialon_sync.temp_wialon_clients twc
            WHERE twc.session_id = $1
            AND NOT EXISTS (
                SELECT 1 FROM clients.clients c 
                WHERE c.wialon_id = twc.wialon_id
            )',
            '{"sessionId": "parameter"}'::jsonb,
            10
        ),
        (
            'New Objects Detection',
            'Detect new objects from Wialon that don''t exist in system',
            'object_mapping',
            'INSERT INTO wialon_sync.sync_discrepancies 
            (session_id, discrepancy_type, entity_type, wialon_entity_data, status)
            SELECT 
                $1,
                ''new_object'',
                ''object'',
                jsonb_build_object(
                    ''wialon_id'', two.wialon_id,
                    ''name'', two.name,
                    ''description'', two.description,
                    ''tracker_id'', two.tracker_id,
                    ''phone_numbers'', two.phone_numbers
                ),
                ''pending''
            FROM wialon_sync.temp_wialon_objects two
            WHERE two.session_id = $1
            AND NOT EXISTS (
                SELECT 1 FROM wialon.objects o 
                WHERE o.wialon_id = two.wialon_id
            )',
            '{"sessionId": "parameter"}'::jsonb,
            20
        ),
        (
            'Client Name Changes Detection',
            'Detect client name changes between Wialon and system',
            'name_comparison',
            'INSERT INTO wialon_sync.sync_discrepancies 
            (session_id, discrepancy_type, entity_type, system_client_id, wialon_entity_data, system_entity_data, status)
            SELECT 
                $1,
                ''client_name_changed'',
                ''client'',
                c.id,
                jsonb_build_object(
                    ''wialon_id'', twc.wialon_id,
                    ''name'', twc.name
                ),
                jsonb_build_object(
                    ''id'', c.id,
                    ''name'', c.name,
                    ''wialon_id'', c.wialon_id
                ),
                ''pending''
            FROM wialon_sync.temp_wialon_clients twc
            JOIN clients.clients c ON twc.wialon_id = c.wialon_id
            WHERE twc.session_id = $1
            AND LOWER(TRIM(twc.name)) != LOWER(TRIM(c.name))',
            '{"sessionId": "parameter"}'::jsonb,
            30
        ),
        (
            'Client Username Changes Detection',
            'Detect client username changes between Wialon and system',
            'name_comparison',
            'INSERT INTO wialon_sync.sync_discrepancies 
            (session_id, discrepancy_type, entity_type, system_client_id, wialon_entity_data, system_entity_data, status)
            SELECT 
                $1,
                ''client_username_changed'',
                ''client'',
                c.id,
                jsonb_build_object(
                    ''wialon_id'', twc.wialon_id,
                    ''name'', twc.name,
                    ''wialon_username'', twc.wialon_username
                ),
                jsonb_build_object(
                    ''id'', c.id,
                    ''name'', c.name,
                    ''wialon_id'', c.wialon_id,
                    ''wialon_username'', c.wialon_username
                ),
                ''pending''
            FROM wialon_sync.temp_wialon_clients twc
            JOIN clients.clients c ON twc.wialon_id = c.wialon_id
            WHERE twc.session_id = $1
            AND (
                COALESCE(LOWER(TRIM(twc.wialon_username)), '''') != COALESCE(LOWER(TRIM(c.wialon_username)), '''')
            )',
            '{"sessionId": "parameter"}'::jsonb,
            40
        ),
        (
            'Object Name Changes Detection',
            'Detect object name changes between Wialon and system',
            'name_comparison',
            'INSERT INTO wialon_sync.sync_discrepancies 
            (session_id, discrepancy_type, entity_type, system_object_id, wialon_entity_data, system_entity_data, status)
            SELECT 
                $1,
                ''object_name_changed'',
                ''object'',
                o.id,
                jsonb_build_object(
                    ''wialon_id'', two.wialon_id,
                    ''name'', two.name
                ),
                jsonb_build_object(
                    ''id'', o.id,
                    ''name'', o.name,
                    ''wialon_id'', o.wialon_id
                ),
                ''pending''
            FROM wialon_sync.temp_wialon_objects two
            JOIN wialon.objects o ON two.wialon_id = o.wialon_id
            WHERE two.session_id = $1
            AND LOWER(TRIM(two.name)) != LOWER(TRIM(o.name))',
            '{"sessionId": "parameter"}'::jsonb,
            50
        )
    ) AS v (name, description, rule_type, sql_query, parameters, execution_order)
    WHERE NOT EXISTS (
        SELECT 1 FROM wialon_sync.sync_rules
        WHERE name = v.name
    );


    RAISE NOTICE 'Default wialon_sync data inserted';

END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';