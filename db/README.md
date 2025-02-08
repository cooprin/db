# Database Initialization Structure

## Overview
This directory contains PostgreSQL initialization scripts that create the database structure with authentication, authorization, resource management and audit logging functionality.

## File Structure
```
db/
└── init/
    ├── 00-extensions.sql       # PostgreSQL extensions (uuid-ossp, ltree, etc.)
    ├── 01-schemas.sql         # Database schemas (auth, core, audit)
    ├── 02-functions.sql       # Helper functions for constraints and triggers
    ├── 03-tables/            # Tables organized by schema
    │   ├── auth/             # Authentication & authorization tables
    │   │   ├── 01-users.sql
    │   │   ├── 02-roles.sql
    │   │   ├── 03-permissions.sql
    │   │   └── 04-user_roles.sql
    │   ├── core/             # Core functionality tables
    │   │   ├── 01-resources.sql
    │   │   ├── 02-actions.sql
    │   │   └── 03-resource_actions.sql
    │   └── audit/            # Audit logging tables
    │       └── 01-audit_logs.sql
    ├── 04-triggers.sql       # Database triggers for timestamps
    ├── 05-views.sql         # Views for common data access patterns
    ├── 06-indexes.sql       # Database indexes and constraints
    └── 07-seeds/           # Initial data and admin user
        ├── 01-default-data.sql
        └── 02-admin-user.sql
```

## Execution Order
Files are executed in alphanumeric order:
1. Extensions (00) - Required PostgreSQL extensions
2. Schemas (01) - Database schema creation
3. Functions (02) - Helper functions used by other scripts
4. Tables (03) - Table creation grouped by schema
5. Triggers (04) - Timestamp update triggers
6. Views (05) - Database views creation
7. Indexes (06) - Index creation and optimization
8. Seeds (07) - Initial data population

## Schema Structure

### Auth Schema
Tables related to authentication and authorization:
- `users` - User accounts and profile information
- `roles` - Role definitions
- `permissions` - System permissions
- `permission_groups` - Logical groups of permissions
- `role_permissions` - Mapping between roles and permissions
- `user_roles` - Mapping between users and roles

### Core Schema
Core system functionality:
- `resources` - System resources (tables, modules, functions)
- `actions` - Available actions (create, read, update, delete)
- `resource_actions` - Available actions for each resource

### Audit Schema
Audit logging functionality:
- `audit_logs` - System activity logging

## Database Features
- UUID primary keys
- Timestamp tracking (created_at, updated_at)
- Automatic timestamp updates via triggers
- JSONB for flexible metadata storage
- Foreign key constraints for referential integrity
- Indexes for performance optimization

## Default Admin User
The system creates a default administrator:
- Email: cooprin@gmail.com
- Password: [stored as bcrypt hash]
- Role: admin
- All system permissions granted

## Safety Features
- All scripts include existence checks before creation
- Idempotent operations (safe to run multiple times)
- Schema-based organization for better security
- Proper permission management

## Usage
The initialization happens automatically when the Docker container starts. The process is idempotent and can be safely rerun.

To rebuild the database:
```bash
docker-compose down -v
docker-compose up -d
```