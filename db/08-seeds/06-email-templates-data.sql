-- Disable triggers temporarily for initial data load
SET session_replication_role = 'replica';

-- Insert default email templates
DO $$
BEGIN
    -- Створення базового шаблону для нового рахунку
    INSERT INTO company.email_templates (
        name, 
        code, 
        subject, 
        body_html, 
        body_text, 
        description, 
        variables, 
        is_active
    ) 
    SELECT * FROM (VALUES
        (
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
            }',
            true
        )
    ) AS v (name, code, subject, body_html, body_text, description, variables, is_active)
    WHERE NOT EXISTS (
        SELECT 1 FROM company.email_templates 
        WHERE code = v.code
    );

    RAISE NOTICE 'Default email templates inserted';
END $$;

-- Re-enable triggers after data load
SET session_replication_role = 'origin';