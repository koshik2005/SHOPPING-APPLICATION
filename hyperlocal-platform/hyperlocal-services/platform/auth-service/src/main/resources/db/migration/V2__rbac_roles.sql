-- ==============================================================================
-- V2__rbac_roles.sql
-- HyperLocal Auth Service — RBAC Migration
--
-- Changes:
--   1. Create user_roles junction table (multi-role per user)
--   2. Add branch_id / shop_id tenant scope columns to users
--   3. Add soft-delete audit columns (deleted_at, deleted_by)
--   4. Migrate all existing users to ROLE_CUSTOMER
-- ==============================================================================

-- 1. Add tenant scoping columns to users table
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS branch_id  UUID REFERENCES branches(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS shop_id    UUID ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- 2. Create user_roles junction table
CREATE TABLE IF NOT EXISTS user_roles (
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role        VARCHAR(50) NOT NULL,
    assigned_at TIMESTAMP   NOT NULL DEFAULT NOW(),
    assigned_by UUID        REFERENCES users(id) ON DELETE SET NULL,
    PRIMARY KEY (user_id, role)
);

-- 3. Migrate all existing non-deleted users to ROLE_CUSTOMER
INSERT INTO user_roles (user_id, role)
SELECT id, 'ROLE_CUSTOMER'
FROM   users
WHERE  deleted = false
ON CONFLICT (user_id, role) DO NOTHING;

-- 4. Performance indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id
    ON user_roles(user_id);

CREATE INDEX IF NOT EXISTS idx_user_roles_role
    ON user_roles(role);

CREATE INDEX IF NOT EXISTS idx_users_branch_id
    ON users(branch_id)
    WHERE branch_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_shop_id
    ON users(shop_id)
    WHERE shop_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_deleted_at
    ON users(deleted_at)
    WHERE deleted_at IS NOT NULL;
