DO $$
BEGIN
    -- Створюємо схему для сповіщень
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'notifications'
    ) THEN
        CREATE SCHEMA notifications;
        RAISE NOTICE 'Notifications schema created';
    END IF;

    -- Таблиця сповіщень
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'notifications' AND table_name = 'notifications'
    ) THEN
        CREATE TABLE notifications.notifications (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            recipient_id UUID NOT NULL,
            recipient_type VARCHAR(20) NOT NULL,
            notification_type VARCHAR(50) NOT NULL,
            title VARCHAR(255) NOT NULL,
            message TEXT,
            entity_type VARCHAR(50),
            entity_id UUID,
            data JSONB DEFAULT '{}',
            is_read BOOLEAN DEFAULT false,
            read_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP WITH TIME ZONE,
            
            CONSTRAINT chk_recipient_type CHECK (recipient_type IN ('staff', 'client')),
            CONSTRAINT chk_notification_type CHECK (notification_type IN (
                'new_ticket', 'ticket_assigned', 'ticket_updated', 'ticket_resolved', 'ticket_comment',
                'new_chat_message', 'chat_assigned', 'chat_closed',
                'new_invoice', 'payment_received'
            ))
        );

        -- Індекси для продуктивності
        CREATE INDEX idx_notifications_recipient ON notifications.notifications(recipient_id, recipient_type);
        CREATE INDEX idx_notifications_unread ON notifications.notifications(recipient_id, is_read, created_at DESC);
        CREATE INDEX idx_notifications_type ON notifications.notifications(notification_type, created_at DESC);
        CREATE INDEX idx_notifications_entity ON notifications.notifications(entity_type, entity_id);

        COMMENT ON TABLE notifications.notifications IS 'System notifications for users and clients';
        RAISE NOTICE 'Notifications table created';
    END IF;

    -- Таблиця налаштувань сповіщень користувачів
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'notifications' AND table_name = 'user_notification_settings'
    ) THEN
        CREATE TABLE notifications.user_notification_settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL,
            user_type VARCHAR(20) NOT NULL,
            notification_type VARCHAR(50) NOT NULL,
            enabled BOOLEAN DEFAULT true,
            delivery_method JSONB DEFAULT '{"web": true, "email": false}',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            
            UNIQUE(user_id, user_type, notification_type),
            CONSTRAINT chk_user_type CHECK (user_type IN ('staff', 'client')),
            CONSTRAINT chk_notification_type_settings CHECK (notification_type IN (
                'new_ticket', 'ticket_assigned', 'ticket_updated', 'ticket_resolved', 'ticket_comment',
                'new_chat_message', 'chat_assigned', 'chat_closed',
                'new_invoice', 'payment_received'
            ))
        );

        CREATE INDEX idx_user_notification_settings_user ON notifications.user_notification_settings(user_id, user_type);
        CREATE INDEX idx_user_notification_settings_type ON notifications.user_notification_settings(notification_type);

        COMMENT ON TABLE notifications.user_notification_settings IS 'User preferences for notifications';
        RAISE NOTICE 'User notification settings table created';
    END IF;

    -- Функції для роботи з сповіщеннями
    -- Функція для отримання користувачів з певним дозволом
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'get_users_with_permission'
    ) THEN
        CREATE OR REPLACE FUNCTION notifications.get_users_with_permission(
            p_permission_code TEXT
        )
        RETURNS TABLE(user_id UUID, user_email VARCHAR(255))
        LANGUAGE plpgsql
        AS $func$
        BEGIN
            RETURN QUERY
            SELECT DISTINCT u.id, u.email
            FROM auth.users u
            JOIN auth.user_roles ur ON u.id = ur.user_id
            JOIN auth.role_permissions rp ON ur.role_id = rp.role_id
            JOIN auth.permissions p ON rp.permission_id = p.id
            WHERE p.code = p_permission_code
            AND u.is_active = true;
        END;
        $func$;

        RAISE NOTICE 'Function get_users_with_permission created';
    END IF;

    -- Функція для створення одиночного сповіщення
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'create_notification'
    ) THEN
        CREATE OR REPLACE FUNCTION notifications.create_notification(
            p_recipient_id UUID,
            p_recipient_type VARCHAR(20),
            p_notification_type VARCHAR(50),
            p_title VARCHAR(255),
            p_message TEXT DEFAULT NULL,
            p_entity_type VARCHAR(50) DEFAULT NULL,
            p_entity_id UUID DEFAULT NULL,
            p_data JSONB DEFAULT '{}'
        )
        RETURNS UUID
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            notification_id UUID;
        BEGIN
            -- Перевіряємо чи користувач увімкнув цей тип сповіщень
            IF EXISTS (
                SELECT 1 FROM notifications.user_notification_settings
                WHERE user_id = p_recipient_id 
                AND user_type = p_recipient_type 
                AND notification_type = p_notification_type
                AND enabled = false
            ) THEN
                RETURN NULL;
            END IF;

            -- Створюємо сповіщення
            INSERT INTO notifications.notifications (
                recipient_id, recipient_type, notification_type, 
                title, message, entity_type, entity_id, data
            ) VALUES (
                p_recipient_id, p_recipient_type, p_notification_type,
                p_title, p_message, p_entity_type, p_entity_id, p_data
            ) RETURNING id INTO notification_id;

            RETURN notification_id;
        END;
        $func$;

        RAISE NOTICE 'Function create_notification created';
    END IF;

    -- Функція для створення групових сповіщень
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'create_group_notifications'
    ) THEN
        CREATE OR REPLACE FUNCTION notifications.create_group_notifications(
            p_permission_code TEXT,
            p_notification_type VARCHAR(50),
            p_title VARCHAR(255),
            p_message TEXT DEFAULT NULL,
            p_entity_type VARCHAR(50) DEFAULT NULL,
            p_entity_id UUID DEFAULT NULL,
            p_data JSONB DEFAULT '{}',
            p_exclude_user_id UUID DEFAULT NULL
        )
        RETURNS INTEGER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            user_record RECORD;
            notifications_created INTEGER := 0;
        BEGIN
            -- Створюємо сповіщення для всіх користувачів з дозволом
            FOR user_record IN 
                SELECT user_id, user_email 
                FROM notifications.get_users_with_permission(p_permission_code)
                WHERE (p_exclude_user_id IS NULL OR user_id != p_exclude_user_id)
            LOOP
                IF notifications.create_notification(
                    user_record.user_id,
                    'staff',
                    p_notification_type,
                    p_title,
                    p_message,
                    p_entity_type,
                    p_entity_id,
                    p_data
                ) IS NOT NULL THEN
                    notifications_created := notifications_created + 1;
                END IF;
            END LOOP;

            RETURN notifications_created;
        END;
        $func$;

        RAISE NOTICE 'Function create_group_notifications created';
    END IF;
END $$;