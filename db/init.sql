-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Helper functions
CREATE OR REPLACE FUNCTION add_constraint_if_not_exists(
   t_name text, c_name text, c_sql text
) RETURNS void AS $$
BEGIN
   IF NOT EXISTS (
       SELECT 1 
       FROM information_schema.constraint_column_usage 
       WHERE constraint_name = c_name
   ) THEN
       EXECUTE 'ALTER TABLE ' || t_name || ' ADD CONSTRAINT ' || c_name || ' ' || c_sql;
   END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Main table creation function
CREATE OR REPLACE FUNCTION create_table_if_not_exists() RETURNS void AS $$
BEGIN
  -- Resources table
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'resources') THEN
      CREATE TABLE resources (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          name VARCHAR(255) NOT NULL,
          code VARCHAR(100) NOT NULL UNIQUE,
          type VARCHAR(50) NOT NULL,
          metadata JSONB DEFAULT '{}',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      INSERT INTO resources (name, code, type) VALUES
          ('Users', 'users', 'table'),
          ('Roles', 'roles', 'table'),
          ('Permissions', 'permissions', 'module'),
          ('Resources', 'resources', 'module'),
          ('Audit', 'audit', 'module'),
          ('System', 'system', 'module');
          
      PERFORM add_constraint_if_not_exists(
          'resources',
          'check_resource_type',
          'CHECK (type IN (''table'', ''module'', ''function''))'
      );
  END IF;

  -- Actions table
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'actions') THEN
      CREATE TABLE actions (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          name VARCHAR(255) NOT NULL,
          code VARCHAR(100) NOT NULL UNIQUE,
          description TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      
      INSERT INTO actions (name, code, description) VALUES 
          ('Create', 'create', 'Permission to create new records'),
          ('Read', 'read', 'Permission to read records'),
          ('Update', 'update', 'Permission to update records'),
          ('Delete', 'delete', 'Permission to delete records'),
          ('Manage', 'manage', 'Full management permission');
  END IF;

  -- Resource actions table
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'resource_actions') THEN
      CREATE TABLE resource_actions (
          resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
          action_id UUID REFERENCES actions(id),
          is_default BOOLEAN DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (resource_id, action_id)
      );

      INSERT INTO resource_actions (resource_id, action_id, is_default)
      SELECT r.id, a.id, true
      FROM resources r
      CROSS JOIN actions a;
  END IF;

  -- Permission groups
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'permission_groups') THEN
      CREATE TABLE permission_groups (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          name VARCHAR(255) NOT NULL,
          description TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      
      INSERT INTO permission_groups (name, description) VALUES 
          ('User Management', 'Permissions related to user management'),
          ('Role Management', 'Permissions related to role management'),
          ('Permission Management', 'Permissions related to permission management'),
          ('Resource Management', 'Permissions related to resource management'),
          ('System Management', 'System-level permissions');
  END IF;

  -- Permissions table
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'permissions') THEN
      CREATE TABLE permissions (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          group_id UUID REFERENCES permission_groups(id),
          resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
          name VARCHAR(255) NOT NULL,
          code VARCHAR(100) NOT NULL UNIQUE,
          conditions JSONB DEFAULT '{}',
          is_system BOOLEAN DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      WITH permission_data AS (
          SELECT 
              pg.id as group_id,
              r.id as resource_id,
              r.code as resource_code,
              a.code as action_code
          FROM permission_groups pg
          CROSS JOIN resources r
          CROSS JOIN actions a
          WHERE 
              (pg.name = 'User Management' AND r.code = 'users') OR
              (pg.name = 'Role Management' AND r.code = 'roles') OR
              (pg.name = 'Permission Management' AND r.code = 'permissions') OR
              (pg.name = 'Resource Management' AND r.code = 'resources') OR
              (pg.name = 'System Management' AND r.code IN ('audit', 'system'))
      )
      INSERT INTO permissions (group_id, resource_id, name, code, is_system)
      SELECT 
          pd.group_id,
          pd.resource_id,
          pd.resource_code || '.' || pd.action_code as name,
          pd.resource_code || '.' || pd.action_code as code,
          true
      FROM permission_data pd;
  END IF;

  -- Roles table
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'roles') THEN
      CREATE TABLE roles (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          name VARCHAR(50) NOT NULL UNIQUE,
          description TEXT,
          is_system BOOLEAN DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      
      INSERT INTO roles (name, description, is_system) VALUES
          ('admin', 'System administrator', true);
  END IF;

  -- Role permissions
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'role_permissions') THEN
      CREATE TABLE role_permissions (
          role_id UUID REFERENCES roles(id),
          permission_id UUID REFERENCES permissions(id),
          granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          granted_by UUID,
          PRIMARY KEY (role_id, permission_id)
      );

      INSERT INTO role_permissions (role_id, permission_id)
      SELECT r.id, p.id
      FROM roles r
      CROSS JOIN permissions p
      WHERE r.name = 'admin';
  END IF;

  -- Users table
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'users') THEN
      CREATE TABLE users (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          email VARCHAR(255) NOT NULL UNIQUE,
          password VARCHAR(255) NOT NULL,
          first_name VARCHAR(100),
          last_name VARCHAR(100),
          phone VARCHAR(20),
          avatar_url TEXT,
          is_active BOOLEAN DEFAULT true,
          last_login TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
  END IF;

  -- User roles
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_roles') THEN
      CREATE TABLE user_roles (
          user_id UUID REFERENCES users(id),
          role_id UUID REFERENCES roles(id),
          granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          granted_by UUID REFERENCES users(id),
          PRIMARY KEY (user_id, role_id)
      );
  END IF;

  -- Audit logs
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'audit_logs') THEN
      CREATE TABLE audit_logs (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id UUID REFERENCES users(id),
          action_type VARCHAR(50) NOT NULL,
          entity_type VARCHAR(50) NOT NULL,
          entity_id UUID,
          old_values JSONB,
          new_values JSONB,
          ip_address VARCHAR(45),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id);
      CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs(action_type);
      CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);
      CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Execute table creation
SELECT create_table_if_not_exists();

-- Create additional permissions for resources
DO $$
DECLARE
   resource_management_group_id UUID;
   resources_id UUID;
BEGIN
   SELECT id INTO resource_management_group_id 
   FROM permission_groups 
   WHERE name = 'Resource Management';
   
   SELECT id INTO resources_id
   FROM resources
   WHERE code = 'resources';
   
   -- Create permissions for resources
   INSERT INTO permissions (group_id, resource_id, name, code, is_system)
   SELECT 
       resource_management_group_id,
       resources_id,
       'resources.' || a.code,
       'resources.' || a.code,
       true
   FROM actions a
   WHERE NOT EXISTS (
       SELECT 1 FROM permissions 
       WHERE code = 'resources.' || a.code
   );
   
   -- Assign permissions to admin
   INSERT INTO role_permissions (role_id, permission_id)
   SELECT r.id, p.id
   FROM roles r
   CROSS JOIN permissions p
   WHERE r.name = 'admin'
   AND p.code LIKE 'resources.%'
   AND NOT EXISTS (
       SELECT 1 FROM role_permissions 
       WHERE role_id = r.id AND permission_id = p.id
   );
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_permissions_code ON permissions(code);
CREATE INDEX IF NOT EXISTS idx_resources_code ON resources(code);

-- Create triggers
DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_timestamp') THEN
       CREATE TRIGGER update_users_timestamp
           BEFORE UPDATE ON users
           FOR EACH ROW
           EXECUTE FUNCTION update_timestamp();
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_roles_timestamp') THEN
       CREATE TRIGGER update_roles_timestamp
           BEFORE UPDATE ON roles
           FOR EACH ROW
           EXECUTE FUNCTION update_timestamp();
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_resources_timestamp') THEN
       CREATE TRIGGER update_resources_timestamp
           BEFORE UPDATE ON resources
           FOR EACH ROW
           EXECUTE FUNCTION update_timestamp();
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_permission_groups_timestamp') THEN
       CREATE TRIGGER update_permission_groups_timestamp
           BEFORE UPDATE ON permission_groups
           FOR EACH ROW
           EXECUTE FUNCTION update_timestamp();
   END IF;
END $$;

-- Create views
CREATE OR REPLACE VIEW view_users_with_roles AS
SELECT 
   u.id, u.email, u.first_name, u.last_name,
   u.phone, u.avatar_url, u.is_active, u.last_login,
   array_agg(r.name) as role_names,
   array_agg(DISTINCT p.code) as permissions
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
LEFT JOIN role_permissions rp ON r.id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.id
GROUP BY u.id, u.email, u.first_name, u.last_name, 
        u.phone, u.avatar_url, u.is_active, u.last_login;

CREATE OR REPLACE VIEW view_resources_with_actions AS
SELECT 
   r.id, r.name, r.code, r.type, r.metadata,
   array_agg(DISTINCT a.code) as action_codes,
   array_agg(DISTINCT jsonb_build_object(
       'action_id', a.id,
       'action_code', a.code,
       'is_default', ra.is_default
   )) as actions
FROM resources r
LEFT JOIN resource_actions ra ON r.id = ra.resource_id
LEFT JOIN actions a ON ra.action_id = a.id
GROUP BY r.id, r.name, r.code, r.type, r.metadata;

-- Create default admin user
DO $$
DECLARE
   admin_role_id UUID;
   admin_user_id UUID;
BEGIN
   SELECT id INTO admin_role_id FROM roles WHERE name = 'admin' LIMIT 1;
   
   IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'cooprin@gmail.com') THEN
       INSERT INTO users (
           email,
           password,
           first_name,
           last_name,
           is_active
       ) VALUES (
           'cooprin@gmail.com',
           '$2b$10$/8mFF08rYqKd20byMvGwquNb4JrxJ9eDjf8T8WAj1QQifWU6L0q0a',
           'Roman',
           'Tsyupryk',
           true
       ) RETURNING id INTO admin_user_id;
       
       INSERT INTO user_roles (user_id, role_id) 
       VALUES (admin_user_id, admin_role_id);
   END IF;
END $$;

-- Grant privileges
DO $$
BEGIN
   EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %I', current_user);
   EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %I', current_user);
   EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO %I', current_user);
END $$;