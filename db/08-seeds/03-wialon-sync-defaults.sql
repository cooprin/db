-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert default wialon_sync data
DO $$
BEGIN
    -- Insert default sync rules
    INSERT INTO wialon_sync.sync_rules (name, description, rule_type, sql_query, parameters, execution_order)
    SELECT * FROM (VALUES
        (
            'Client Name Comparison',
            'Compare client names between Wialon and system',
            'name_comparison',
            'SELECT 
                twc.wialon_id,
                twc.name as wialon_name,
                c.id as system_client_id,
                c.name as system_name
            FROM wialon_sync.temp_wialon_clients twc
            JOIN clients.clients c ON twc.wialon_id = c.wialon_id
            WHERE LOWER(TRIM(twc.name)) != LOWER(TRIM(c.name))',
            '{"sensitivity": "case_insensitive", "trim_spaces": true}'::jsonb,
            10
        ),
        (
            'Object Name Comparison',
            'Compare object names between Wialon and system',
            'name_comparison',
            'SELECT 
                two.wialon_id,
                two.name as wialon_name,
                o.id as system_object_id,
                o.name as system_name
            FROM wialon_sync.temp_wialon_objects two
            JOIN wialon.objects o ON two.wialon_id = o.wialon_id
            WHERE LOWER(TRIM(two.name)) != LOWER(TRIM(o.name))',
            '{"sensitivity": "case_insensitive", "trim_spaces": true}'::jsonb,
            20
        ),
        (
            'New Clients Detection',
            'Detect new clients from Wialon that don''t exist in system',
            'client_mapping',
            'SELECT 
                twc.wialon_id,
                twc.name,
                twc.full_name,
                twc.description,
                twc.additional_data
            FROM wialon_sync.temp_wialon_clients twc
            LEFT JOIN clients.clients c ON twc.wialon_id = c.wialon_id
            WHERE c.id IS NULL',
            '{"auto_suggest": true}'::jsonb,
            30
        ),
            (
                'New Objects Detection',
                'Detect new objects from Wialon that don''t exist in system',
                'object_mapping',
                'SELECT 
                    two.wialon_id,
                    two.name,
                    two.description,
                    two.tracker_id,
                    two.phone_numbers
                FROM wialon_sync.temp_wialon_objects two
                LEFT JOIN wialon.objects o ON two.wialon_id = o.wialon_id
                WHERE o.id IS NULL',
                '{"auto_suggest": true}'::jsonb,
                40
            ),
         (
            'Tracker Equipment Check',
            'Check tracker equipment consistency with Wialon',
            'equipment_check',
            'SELECT 
                two.wialon_id,
                two.tracker_id as wialon_tracker_id,
                o.id as system_object_id,
                p.id as system_product_id,
                pcv.value as system_tracker_id
            FROM wialon_sync.temp_wialon_objects two
            JOIN wialon.objects o ON two.wialon_id = o.wialon_id
            LEFT JOIN products.products p ON o.id = p.current_object_id
            LEFT JOIN products.product_characteristic_values pcv ON p.id = pcv.product_id
            LEFT JOIN products.product_type_characteristics ptc ON pcv.characteristic_id = ptc.id
            WHERE ptc.code = ''imei'' 
            AND (pcv.value IS NULL OR pcv.value != two.tracker_id)',
            '{"characteristic_code": "imei", "product_types": ["tracker", "gps_device"]}'::jsonb,
            60
        )
    ) AS v (name, description, rule_type, sql_query, parameters, execution_order)
    WHERE NOT EXISTS (
        SELECT 1 FROM wialon_sync.sync_rules
        WHERE name = v.name
    );

    -- Insert default equipment mappings
    INSERT INTO wialon_sync.equipment_mapping (equipment_name, wialon_field_name, system_field_mapping, validation_rules)
    SELECT * FROM (VALUES
        (
            'GPS Tracker',
            'tracker_id',
            '{"characteristic_code": "imei", "product_type_codes": ["tracker", "gps_device"]}'::jsonb,
            '{"required": true, "format": "numeric", "min_length": 15, "max_length": 15}'::jsonb
        ),
        (
            'SIM Card Phone',
            'phone_numbers',
            '{"characteristic_code": "phone_number", "product_type_codes": ["sim_card"]}'::jsonb,
            '{"required": false, "format": "phone", "multiple": true}'::jsonb
        ),
        (
            'Device Name',
            'name',
            '{"object_field": "name"}'::jsonb,
            '{"required": true, "max_length": 255}'::jsonb
        ),
        (
            'Device Description',
            'description',
            '{"object_field": "description"}'::jsonb,
            '{"required": false, "max_length": 1000}'::jsonb
        )
    ) AS v (equipment_name, wialon_field_name, system_field_mapping, validation_rules)
    WHERE NOT EXISTS (
        SELECT 1 FROM wialon_sync.equipment_mapping
        WHERE equipment_name = v.equipment_name AND wialon_field_name = v.wialon_field_name
    );

    RAISE NOTICE 'Default wialon_sync data inserted';

END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';