-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert default notification settings for existing users
DO $$
DECLARE
    user_record RECORD;
    notification_types TEXT[] := ARRAY[
        'new_ticket', 'ticket_assigned', 'ticket_updated', 'ticket_resolved', 'ticket_comment',
        'new_chat_message', 'chat_assigned', 'chat_closed',
        'new_invoice', 'payment_received'
    ];
    notif_type TEXT; -- Перейменована змінна
BEGIN
    -- Для всіх існуючих користувачів (staff)
    FOR user_record IN 
        SELECT id FROM auth.users WHERE is_active = true
    LOOP
        FOREACH notif_type IN ARRAY notification_types
        LOOP
            INSERT INTO notifications.user_notification_settings (
                user_id, user_type, notification_type, enabled, delivery_method
            ) VALUES (
                user_record.id, 
                'staff', 
                notif_type, 
                true, 
                '{"web": true, "email": false}'
            ) ON CONFLICT (user_id, user_type, notification_type) DO NOTHING;
        END LOOP;
    END LOOP;

    -- Для всіх існуючих клієнтів
    FOR user_record IN 
        SELECT id FROM clients.clients WHERE is_active = true
    LOOP
        -- Клієнтам тільки релевантні сповіщення
        INSERT INTO notifications.user_notification_settings (
            user_id, user_type, notification_type, enabled, delivery_method
        ) 
        SELECT 
            user_record.id, 
            'client', 
            unnest(ARRAY['ticket_updated', 'ticket_resolved', 'ticket_comment', 'new_chat_message', 'new_invoice', 'payment_received']),
            true, 
            '{"web": true, "email": false}'
        ON CONFLICT (user_id, user_type, notification_type) DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Default notification settings created for existing users and clients';
END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';