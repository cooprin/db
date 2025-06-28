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
END $$;