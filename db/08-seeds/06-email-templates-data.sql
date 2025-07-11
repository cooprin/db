-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert default email templates
DO $$
BEGIN
    -- Створення базового шаблону для нового рахунку
    IF NOT EXISTS (
        SELECT 1 FROM company.email_templates 
        WHERE code = 'new_invoice_created'
    ) THEN
        INSERT INTO company.email_templates (
            name, 
            code, 
            subject, 
            body_html, 
            body_text, 
            description, 
            variables, 
            module_type,
            is_active
        ) VALUES (
            'Новий рахунок створено',
            'new_invoice_created',
            'Новий рахунок {{invoice_number}} від {{company_name}}',
            '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Новий рахунок</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #f8f9fa; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: white; }
        .footer { background-color: #f8f9fa; padding: 10px; text-align: center; font-size: 12px; }
        .button { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; }
        .invoice-details { background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{company_name}}</h1>
            <h2>Новий рахунок створено</h2>
        </div>
        
        <div class="content">
            <p>Шановний {{client_name}},</p>
            
            <p>Інформуємо Вас про створення нового рахунку для оплати послуг.</p>
            
            <div class="invoice-details">
                <h3>Деталі рахунку:</h3>
                <ul>
                    <li><strong>Номер рахунку:</strong> {{invoice_number}}</li>
                    <li><strong>Дата рахунку:</strong> {{invoice_date}}</li>
                    <li><strong>Період розрахунку:</strong> {{billing_period}}</li>
                    <li><strong>Сума до сплати:</strong> {{total_amount}} грн</li>
                </ul>
            </div>
            
            <p>Рахунок доступний для перегляду та завантаження в особистому кабінеті.</p>
            
            <p style="text-align: center; margin: 30px 0;">
                <a href="{{portal_url}}" class="button">Перейти до особистого кабінету</a>
            </p>
            
            <p>Просимо сплатити рахунок до {{due_date}}.</p>
            
            <p>З повагою,<br>
            Команда {{company_name}}</p>
        </div>
        
        <div class="footer">
            <p>Це автоматично згенерований лист. Будь ласка, не відповідайте на нього.</p>
            <p>{{company_address}} | {{company_phone}} | {{company_email}}</p>
        </div>
    </div>
</body>
</html>',
            'Шановний {{client_name}},

Інформуємо Вас про створення нового рахунку для оплати послуг.

Деталі рахунку:
- Номер рахунку: {{invoice_number}}
- Дата рахунку: {{invoice_date}}
- Період розрахунку: {{billing_period}}
- Сума до сплати: {{total_amount}} грн

Рахунок доступний для перегляду та завантаження в особистому кабінеті: {{portal_url}}

Просимо сплатити рахунок до {{due_date}}.

З повагою,
Команда {{company_name}}

{{company_address}} | {{company_phone}} | {{company_email}}',
            'Шаблон для сповіщення клієнтів про створення нового рахунку',
            '{
                "invoice_number": "Номер рахунку",
                "invoice_date": "Дата рахунку", 
                "client_name": "Ім''я клієнта",
                "company_name": "Назва компанії",
                "billing_period": "Період розрахунку",
                "total_amount": "Загальна сума",
                "due_date": "Дата оплати",
                "portal_url": "Посилання на портал",
                "company_address": "Адреса компанії",
                "company_phone": "Телефон компанії", 
                "company_email": "Email компанії"
            }'::jsonb,
            'invoice',
            true
        );
    END IF;

    -- Шаблон нагадування про оплату
    IF NOT EXISTS (
        SELECT 1 FROM company.email_templates 
        WHERE code = 'payment_reminder'
    ) THEN
        INSERT INTO company.email_templates (
            name, 
            code, 
            subject, 
            body_html, 
            body_text, 
            description, 
            variables, 
            module_type,
            is_active
        ) VALUES (
            'Нагадування про оплату рахунку',
            'payment_reminder',
            'Нагадування про оплату рахунку {{invoice_number}}',
            '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Нагадування про оплату</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #ffc107; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: white; }
        .footer { background-color: #f8f9fa; padding: 10px; text-align: center; font-size: 12px; }
        .button { display: inline-block; padding: 10px 20px; background-color: #ffc107; color: black; text-decoration: none; border-radius: 5px; }
        .invoice-details { background-color: #fff3cd; padding: 15px; margin: 20px 0; border-radius: 5px; border-left: 4px solid #ffc107; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{company_name}}</h1>
            <h2>Нагадування про оплату</h2>
        </div>
        
        <div class="content">
            <p>Шановний {{client_name}},</p>
            
            <p>Нагадуємо Вам про необхідність оплати рахунку.</p>
            
            <div class="invoice-details">
                <h3>Деталі рахунку:</h3>
                <ul>
                    <li><strong>Номер рахунку:</strong> {{invoice_number}}</li>
                    <li><strong>Дата рахунку:</strong> {{invoice_date}}</li>
                    <li><strong>Сума до сплати:</strong> {{total_amount}} грн</li>
                    <li><strong>Термін оплати:</strong> {{due_date}}</li>
                </ul>
            </div>
            
            <p style="text-align: center; margin: 30px 0;">
                <a href="{{portal_url}}" class="button">Оплатити рахунок</a>
            </p>
            
            <p>Якщо у Вас виникли питання, будь ласка, зв''яжіться з нами.</p>
            
            <p>З повагою,<br>
            Команда {{company_name}}</p>
        </div>
        
        <div class="footer">
            <p>{{company_address}} | {{company_phone}} | {{company_email}}</p>
        </div>
    </div>
</body>
</html>',
            'Шановний {{client_name}},

Нагадуємо Вам про необхідність оплати рахунку.

Деталі рахунку:
- Номер рахунку: {{invoice_number}}
- Дата рахунку: {{invoice_date}}
- Сума до сплати: {{total_amount}} грн
- Термін оплати: {{due_date}}

Рахунок доступний для оплати в особистому кабінеті: {{portal_url}}

Якщо у Вас виникли питання, будь ласка, зв''яжіться з нами.

З повагою,
Команда {{company_name}}

{{company_address}} | {{company_phone}} | {{company_email}}',
            'Шаблон для нагадування клієнтам про неоплачені рахунки',
            '{
                "invoice_number": "Номер рахунку",
                "invoice_date": "Дата рахунку", 
                "client_name": "Ім''я клієнта",
                "company_name": "Назва компанії",
                "total_amount": "Загальна сума",
                "due_date": "Дата оплати",
                "portal_url": "Посилання на портал",
                "company_address": "Адреса компанії",
                "company_phone": "Телефон компанії", 
                "company_email": "Email компанії"
            }'::jsonb,
            'invoice',
            true
        );
    END IF;

    -- Шаблон підтвердження оплати
    IF NOT EXISTS (
        SELECT 1 FROM company.email_templates 
        WHERE code = 'payment_received'
    ) THEN
        INSERT INTO company.email_templates (
            name, 
            code, 
            subject, 
            body_html, 
            body_text, 
            description, 
            variables, 
            module_type,
            is_active
        ) VALUES (
            'Підтвердження отримання платежу',
            'payment_received',
            'Платіж отримано - {{payment_amount}} грн',
            '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Платіж отримано</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #28a745; padding: 20px; text-align: center; color: white; }
        .content { padding: 20px; background-color: white; }
        .footer { background-color: #f8f9fa; padding: 10px; text-align: center; font-size: 12px; }
        .payment-details { background-color: #d4edda; padding: 15px; margin: 20px 0; border-radius: 5px; border-left: 4px solid #28a745; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{company_name}}</h1>
            <h2>✅ Платіж отримано</h2>
        </div>
        
        <div class="content">
            <p>Шановний {{client_name}},</p>
            
            <p>Дякуємо! Ваш платіж успішно отримано та зараховано.</p>
            
            <div class="payment-details">
                <h3>Деталі платежу:</h3>
                <ul>
                    <li><strong>Сума платежу:</strong> {{payment_amount}} грн</li>
                    <li><strong>Дата платежу:</strong> {{payment_date}}</li>
                </ul>
            </div>
            
            <p>Дякуємо за вчасну оплату послуг!</p>
            
            <p>З повагою,<br>
            Команда {{company_name}}</p>
        </div>
        
        <div class="footer">
            <p>{{company_address}} | {{company_phone}} | {{company_email}}</p>
        </div>
    </div>
</body>
</html>',
            'Шановний {{client_name}},

Дякуємо! Ваш платіж успішно отримано та зараховано.

Деталі платежу:
- Сума платежу: {{payment_amount}} грн
- Дата платежу: {{payment_date}}

Дякуємо за вчасну оплату послуг!

З повагою,
Команда {{company_name}}

{{company_address}} | {{company_phone}} | {{company_email}}',
            'Шаблон для підтвердження отримання платежу від клієнта',
            '{
                "client_name": "Ім''я клієнта",
                "company_name": "Назва компанії",
                "payment_amount": "Сума платежу",
                "payment_date": "Дата платежу",
                "company_address": "Адреса компанії",
                "company_phone": "Телефон компанії", 
                "company_email": "Email компанії"
            }'::jsonb,
            'payment',
            true
        );
    END IF;

    -- Шаблон привітання нового клієнта
    IF NOT EXISTS (
        SELECT 1 FROM company.email_templates 
        WHERE code = 'welcome_client'
    ) THEN
        INSERT INTO company.email_templates (
            name, 
            code, 
            subject, 
            body_html, 
            body_text, 
            description, 
            variables, 
            module_type,
            is_active
        ) VALUES (
            'Привітання нового клієнта',
            'welcome_client',
            'Вітаємо в {{company_name}}!',
            '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ласкаво просимо</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #007bff; padding: 20px; text-align: center; color: white; }
        .content { padding: 20px; background-color: white; }
        .footer { background-color: #f8f9fa; padding: 10px; text-align: center; font-size: 12px; }
        .button { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{company_name}}</h1>
            <h2>🎉 Ласкаво просимо!</h2>
        </div>
        
        <div class="content">
            <p>Вітаємо, {{client_name}}!</p>
            
            <p>Раді вітати Вас серед наших клієнтів! Дякуємо за довіру до нашої компанії.</p>
            
            <p>Ми надаємо якісні послуги та завжди готові допомогти з будь-якими питаннями.</p>
            
            <p style="text-align: center; margin: 30px 0;">
                <a href="{{portal_url}}" class="button">Перейти до особистого кабінету</a>
            </p>
            
            <p>Якщо у Вас виникнуть питання, не соромтеся звертатися до нас.</p>
            
            <p>З повагою,<br>
            Команда {{company_name}}</p>
        </div>
        
        <div class="footer">
            <p>{{company_address}} | {{company_phone}} | {{company_email}}</p>
        </div>
    </div>
</body>
</html>',
            'Вітаємо, {{client_name}}!

Раді вітати Вас серед наших клієнтів! Дякуємо за довіру до нашої компанії.

Ми надаємо якісні послуги та завжди готові допомогти з будь-якими питаннями.

Особистий кабінет: {{portal_url}}

Якщо у Вас виникнуть питання, не соромтеся звертатися до нас.

З повагою,
Команда {{company_name}}

{{company_address}} | {{company_phone}} | {{company_email}}',
            'Шаблон для привітання нових клієнтів',
            '{
                "client_name": "Ім''я клієнта",
                "company_name": "Назва компанії",
                "portal_url": "Посилання на портал",
                "company_address": "Адреса компанії",
                "company_phone": "Телефон компанії", 
                "company_email": "Email компанії"
            }'::jsonb,
            'client',
            true
        );
    END IF;

    RAISE NOTICE 'Default email templates inserted';
END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';