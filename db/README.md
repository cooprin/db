# Database Initialization Structure

## Overview
This directory contains PostgreSQL initialization scripts that create the database structure with authentication, authorization, resource management, and audit logging functionality.

## File Structure
```
db/ ├── 00-extensions.sql # PostgreSQL extensions (uuid-ossp, ltree, etc.) 
    ├── 01-schemas.sql # Database schemas (auth, core, audit) 
    ├── 02-functions.sql # Helper functions for constraints and triggers 
    ├── 04-audit_function.sql # Audit logging function 
    ├── 05-triggers.sql # Database triggers for timestamps 
    ├── 06-indexes.sql # Database indexes and constraints 
    ├── 07-views.sql # Views for common data access patterns 
    ├── README.md 
    ├── 03-tables/ # Tables organized by schema 
    │ ├── 01auth/ # Authentication & authorization tables 
    │ │ ├── 01-users.sql 
    │ │ ├── 02-roles.sql 
    │ │ ├── 03-permissions.sql 
    │ │ └── 04-user_roles.sql 
    │ ├── 02core/ # Core functionality tables 
    │ │ ├── 01-resources.sql 
    │ │ ├── 02-actions.sql 
    │ ├── 03audit/ # Audit logging tables 
    │ │ └── 01-audit_logs.sql 
    │ ├── 04products/ # Products related tables 
    │ │ └── 01-products.sql 
    │ └── 05warehouses/ # Warehouses related tables 
    │ └── 01-warehouses.sql 
    ├── 08-seeds/ # Initial data and admin user 
    | ├── 01-default-data.sql 
    └└── 02-admin-user.sql
## Schema Structure

## Execution Order
Files are executed in alphanumeric order:
1. Extensions (00) - Required PostgreSQL extensions
2. Schemas (01) - Database schema creation
3. Functions (02) - Helper functions used by other scripts
4. Tables (03) - Table creation grouped by schema
5. Audit Function (04) - Audit logging function
6. Triggers (05) - Timestamp update triggers
7. Indexes (06) - Index creation and optimization
8. Views (07) - Database views creation
9. Seeds (08) - Initial data population

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

### Products Schema
Tables related to product management:
- `products` - Products catalog

### Warehouses Schema
Tables related to warehouse management:
- `warehouses` - Warehouses list

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