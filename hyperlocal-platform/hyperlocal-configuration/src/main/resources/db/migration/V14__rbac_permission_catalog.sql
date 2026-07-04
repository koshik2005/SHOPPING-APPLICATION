-- ==============================================================================
-- V14__rbac_permission_catalog.sql
-- HyperLocal Platform — Dynamic RBAC Permission Catalog
--
-- Creates tables that replace the hardcoded ROLE_PERMISSIONS map
-- in the Enterprise Portal's AuthContext.tsx.
--
-- Changes:
--   1. permission_definitions    — Master catalog of all system permissions
--   2. role_permission_mappings  — Which roles have which permissions (DB-driven RBAC)
--   3. Seed all existing permissions that were previously hardcoded in frontend
-- ==============================================================================

-- ============================================================
-- 1. PERMISSION DEFINITIONS CATALOG
-- ============================================================
CREATE TABLE permission_definitions (
    id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_key VARCHAR(150) NOT NULL UNIQUE,
    display_label  VARCHAR(200) NOT NULL,
    category       VARCHAR(100) NOT NULL,
    description    TEXT,
    is_sensitive   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_perm_defs_category ON permission_definitions(category);

-- ============================================================
-- 2. ROLE PERMISSION MAPPINGS
--    Replaces the entire ROLE_PERMISSIONS constant in AuthContext.tsx
-- ============================================================
CREATE TABLE role_permission_mappings (
    id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name      VARCHAR(100) NOT NULL,
    permission_key VARCHAR(150) NOT NULL,
    granted_at     TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by     UUID,
    UNIQUE (role_name, permission_key)
);

CREATE INDEX idx_role_perm_role ON role_permission_mappings(role_name);
CREATE INDEX idx_role_perm_key  ON role_permission_mappings(permission_key);

-- ============================================================
-- 3. SEED: PERMISSION CATALOG
--    All permissions that were previously hardcoded in frontend
-- ============================================================
INSERT INTO permission_definitions (permission_key, display_label, category) VALUES
  ('dashboard:view',       'View Dashboard',              'DASHBOARD'),
  ('branches:view',        'View Branches',               'BRANCH'),
  ('branches:write',       'Create/Edit Branches',        'BRANCH'),
  ('shops:view',           'View Shops',                  'SHOP'),
  ('shops:write',          'Create/Edit Shops',           'SHOP'),
  ('products:view',        'View Products',               'INVENTORY'),
  ('products:write',       'Create/Edit Products',        'INVENTORY'),
  ('categories:view',      'View Categories',             'INVENTORY'),
  ('categories:write',     'Create/Edit Categories',      'INVENTORY'),
  ('inventory:view',       'View Inventory',              'INVENTORY'),
  ('inventory:write',      'Adjust Inventory',            'INVENTORY'),
  ('orders:view',          'View Orders',                 'ORDERS'),
  ('orders:write',         'Update Order Status',         'ORDERS'),
  ('customers:view',       'View Customer Profiles',      'CUSTOMERS'),
  ('customers:write',      'Edit Customer Profiles',      'CUSTOMERS'),
  ('delivery:view',        'View Delivery Tracking',      'DELIVERY'),
  ('delivery:write',       'Assign/Update Deliveries',    'DELIVERY'),
  ('payments:view',        'View Payments',               'FINANCE'),
  ('payments:write',       'Process/Refund Payments',     'FINANCE'),
  ('wallet:view',          'View Wallet Ledger',          'FINANCE'),
  ('wallet:write',         'Credit/Debit Wallets',        'FINANCE'),
  ('reports:view',         'View Reports',                'ANALYTICS'),
  ('analytics:view',       'View Analytics',              'ANALYTICS'),
  ('notifications:view',   'View Notifications',          'NOTIFICATIONS'),
  ('notifications:write',  'Send/Manage Notifications',   'NOTIFICATIONS'),
  ('users:view',           'View Admin Users',            'IAM'),
  ('users:write',          'Create/Edit Admin Users',     'IAM'),
  ('rbac:view',            'View RBAC Configuration',     'IAM'),
  ('rbac:write',           'Modify Role Permissions',     'IAM'),
  ('audit-logs:view',      'View Audit Logs',             'AUDIT'),
  ('system-settings:view', 'View System Configuration',   'SYSTEM'),
  ('system-settings:write','Edit System Configuration',   'SYSTEM'),
  ('feature-flags:view',   'View Feature Flags',          'SYSTEM'),
  ('feature-flags:write',  'Toggle Feature Flags',        'SYSTEM'),
  ('pricing:view',         'View Pricing Rules',          'SYSTEM'),
  ('pricing:write',        'Edit Pricing Rules',          'SYSTEM'),
  ('service-registry:view','View Service Registry',       'SYSTEM'),
  ('service-registry:write','Edit Service Registry',      'SYSTEM'),
  ('workflow:view',        'View Workflow Definitions',    'SYSTEM'),
  ('workflow:write',       'Edit Workflow Definitions',   'SYSTEM'),
  ('banners:view',         'View Banners',                'CONTENT'),
  ('banners:write',        'Create/Edit Banners',         'CONTENT'),
  ('localisation:view',    'View Localisation Strings',   'CONTENT'),
  ('localisation:write',   'Edit Localisation Strings',   'CONTENT'),
  ('testing-tools:view',   'Access Testing Tools',        'DEVOPS'),
  ('security:view',        'View Security Center',        'SECURITY'),
  ('security:write',       'Manage Security Policies',    'SECURITY');

-- ============================================================
-- 4. SEED: ROLE → PERMISSION MAPPINGS
--    Migrates hardcoded ROLE_PERMISSIONS from AuthContext.tsx to DB
-- ============================================================

-- ROLE_SUPER_ADMIN — wildcard handled in code by checking if role='ROLE_SUPER_ADMIN'
-- No individual rows needed; code checks this role first.

-- ROLE_SYSTEM_ADMIN
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_SYSTEM_ADMIN', 'dashboard:view'),
  ('ROLE_SYSTEM_ADMIN', 'branches:view'),
  ('ROLE_SYSTEM_ADMIN', 'branches:write'),
  ('ROLE_SYSTEM_ADMIN', 'shops:view'),
  ('ROLE_SYSTEM_ADMIN', 'shops:write'),
  ('ROLE_SYSTEM_ADMIN', 'products:view'),
  ('ROLE_SYSTEM_ADMIN', 'products:write'),
  ('ROLE_SYSTEM_ADMIN', 'categories:view'),
  ('ROLE_SYSTEM_ADMIN', 'categories:write'),
  ('ROLE_SYSTEM_ADMIN', 'inventory:view'),
  ('ROLE_SYSTEM_ADMIN', 'orders:view'),
  ('ROLE_SYSTEM_ADMIN', 'orders:write'),
  ('ROLE_SYSTEM_ADMIN', 'customers:view'),
  ('ROLE_SYSTEM_ADMIN', 'customers:write'),
  ('ROLE_SYSTEM_ADMIN', 'delivery:view'),
  ('ROLE_SYSTEM_ADMIN', 'payments:view'),
  ('ROLE_SYSTEM_ADMIN', 'wallet:view'),
  ('ROLE_SYSTEM_ADMIN', 'reports:view'),
  ('ROLE_SYSTEM_ADMIN', 'analytics:view'),
  ('ROLE_SYSTEM_ADMIN', 'notifications:view'),
  ('ROLE_SYSTEM_ADMIN', 'users:view'),
  ('ROLE_SYSTEM_ADMIN', 'users:write'),
  ('ROLE_SYSTEM_ADMIN', 'rbac:view'),
  ('ROLE_SYSTEM_ADMIN', 'audit-logs:view'),
  ('ROLE_SYSTEM_ADMIN', 'system-settings:view'),
  ('ROLE_SYSTEM_ADMIN', 'system-settings:write'),
  ('ROLE_SYSTEM_ADMIN', 'feature-flags:view'),
  ('ROLE_SYSTEM_ADMIN', 'pricing:view'),
  ('ROLE_SYSTEM_ADMIN', 'service-registry:view'),
  ('ROLE_SYSTEM_ADMIN', 'workflow:view'),
  ('ROLE_SYSTEM_ADMIN', 'banners:view'),
  ('ROLE_SYSTEM_ADMIN', 'banners:write'),
  ('ROLE_SYSTEM_ADMIN', 'security:view');

-- ROLE_BRANCH_MANAGER
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_BRANCH_MANAGER', 'dashboard:view'),
  ('ROLE_BRANCH_MANAGER', 'branches:view'),
  ('ROLE_BRANCH_MANAGER', 'shops:view'),
  ('ROLE_BRANCH_MANAGER', 'shops:write'),
  ('ROLE_BRANCH_MANAGER', 'products:view'),
  ('ROLE_BRANCH_MANAGER', 'products:write'),
  ('ROLE_BRANCH_MANAGER', 'categories:view'),
  ('ROLE_BRANCH_MANAGER', 'inventory:view'),
  ('ROLE_BRANCH_MANAGER', 'orders:view'),
  ('ROLE_BRANCH_MANAGER', 'orders:write'),
  ('ROLE_BRANCH_MANAGER', 'delivery:view'),
  ('ROLE_BRANCH_MANAGER', 'reports:view'),
  ('ROLE_BRANCH_MANAGER', 'analytics:view'),
  ('ROLE_BRANCH_MANAGER', 'notifications:view'),
  ('ROLE_BRANCH_MANAGER', 'banners:view'),
  ('ROLE_BRANCH_MANAGER', 'pricing:view');

-- ROLE_SHOP_OWNER
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_SHOP_OWNER', 'dashboard:view'),
  ('ROLE_SHOP_OWNER', 'shops:view'),
  ('ROLE_SHOP_OWNER', 'products:view'),
  ('ROLE_SHOP_OWNER', 'products:write'),
  ('ROLE_SHOP_OWNER', 'categories:view'),
  ('ROLE_SHOP_OWNER', 'inventory:view'),
  ('ROLE_SHOP_OWNER', 'inventory:write'),
  ('ROLE_SHOP_OWNER', 'orders:view'),
  ('ROLE_SHOP_OWNER', 'orders:write'),
  ('ROLE_SHOP_OWNER', 'reports:view');

-- ROLE_SHOP_MANAGER
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_SHOP_MANAGER', 'dashboard:view'),
  ('ROLE_SHOP_MANAGER', 'shops:view'),
  ('ROLE_SHOP_MANAGER', 'products:view'),
  ('ROLE_SHOP_MANAGER', 'categories:view'),
  ('ROLE_SHOP_MANAGER', 'inventory:view'),
  ('ROLE_SHOP_MANAGER', 'orders:view'),
  ('ROLE_SHOP_MANAGER', 'orders:write');

-- ROLE_QA_ENGINEER
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_QA_ENGINEER', 'dashboard:view'),
  ('ROLE_QA_ENGINEER', 'branches:view'),
  ('ROLE_QA_ENGINEER', 'shops:view'),
  ('ROLE_QA_ENGINEER', 'products:view'),
  ('ROLE_QA_ENGINEER', 'orders:view'),
  ('ROLE_QA_ENGINEER', 'customers:view'),
  ('ROLE_QA_ENGINEER', 'delivery:view'),
  ('ROLE_QA_ENGINEER', 'payments:view'),
  ('ROLE_QA_ENGINEER', 'wallet:view'),
  ('ROLE_QA_ENGINEER', 'reports:view'),
  ('ROLE_QA_ENGINEER', 'audit-logs:view'),
  ('ROLE_QA_ENGINEER', 'testing-tools:view');

-- ROLE_SUPPORT_AGENT
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_SUPPORT_AGENT', 'dashboard:view'),
  ('ROLE_SUPPORT_AGENT', 'branches:view'),
  ('ROLE_SUPPORT_AGENT', 'shops:view'),
  ('ROLE_SUPPORT_AGENT', 'products:view'),
  ('ROLE_SUPPORT_AGENT', 'orders:view'),
  ('ROLE_SUPPORT_AGENT', 'orders:write'),
  ('ROLE_SUPPORT_AGENT', 'customers:view'),
  ('ROLE_SUPPORT_AGENT', 'customers:write'),
  ('ROLE_SUPPORT_AGENT', 'wallet:view'),
  ('ROLE_SUPPORT_AGENT', 'payments:view');

-- ROLE_FINANCE
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_FINANCE', 'dashboard:view'),
  ('ROLE_FINANCE', 'orders:view'),
  ('ROLE_FINANCE', 'payments:view'),
  ('ROLE_FINANCE', 'payments:write'),
  ('ROLE_FINANCE', 'wallet:view'),
  ('ROLE_FINANCE', 'wallet:write'),
  ('ROLE_FINANCE', 'reports:view'),
  ('ROLE_FINANCE', 'analytics:view'),
  ('ROLE_FINANCE', 'pricing:view');

-- ROLE_AUDITOR
INSERT INTO role_permission_mappings (role_name, permission_key) VALUES
  ('ROLE_AUDITOR', 'dashboard:view'),
  ('ROLE_AUDITOR', 'branches:view'),
  ('ROLE_AUDITOR', 'shops:view'),
  ('ROLE_AUDITOR', 'products:view'),
  ('ROLE_AUDITOR', 'orders:view'),
  ('ROLE_AUDITOR', 'customers:view'),
  ('ROLE_AUDITOR', 'delivery:view'),
  ('ROLE_AUDITOR', 'payments:view'),
  ('ROLE_AUDITOR', 'wallet:view'),
  ('ROLE_AUDITOR', 'reports:view'),
  ('ROLE_AUDITOR', 'audit-logs:view');
