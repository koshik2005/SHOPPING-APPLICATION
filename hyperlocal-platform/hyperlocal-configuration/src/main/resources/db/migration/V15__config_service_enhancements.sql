-- ==============================================================================
-- V15__config_service_enhancements.sql
-- HyperLocal Platform — Enhanced system_configuration + Inventory Dynamic Columns
--
-- Changes:
--   1. Enhance system_configuration with scope, type, audit fields
--   2. Enhance categories table with service_key, display_order, color, etc.
--   3. Enhance products table with service_key, is_active
--   4. Enhance shops table with service_keys (which services this shop offers)
-- ==============================================================================

-- ============================================================
-- 1. ENHANCE system_configuration TABLE
--    Adds scope/tenant scoping, data typing, sensitivity flag
-- ============================================================
ALTER TABLE system_configuration
    ADD COLUMN IF NOT EXISTS scope       VARCHAR(20)  NOT NULL DEFAULT 'GLOBAL'
                                          CHECK (scope IN ('GLOBAL','BRANCH','SHOP','USER','ROLE')),
    ADD COLUMN IF NOT EXISTS scope_id    UUID,
    ADD COLUMN IF NOT EXISTS data_type   VARCHAR(20)  NOT NULL DEFAULT 'STRING'
                                          CHECK (data_type IN ('STRING','INTEGER','DECIMAL','BOOLEAN','JSON','URL')),
    ADD COLUMN IF NOT EXISTS is_sensitive BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS description  TEXT,
    ADD COLUMN IF NOT EXISTS updated_by   UUID,
    ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Drop the old unique constraint on config_key alone and re-add scoped uniqueness
ALTER TABLE system_configuration
    DROP CONSTRAINT IF EXISTS system_configuration_config_key_key;

ALTER TABLE system_configuration
    ADD CONSTRAINT uq_config_key_scope UNIQUE (config_key, scope, scope_id);

CREATE INDEX IF NOT EXISTS idx_sysconfig_scope    ON system_configuration(scope, scope_id);
CREATE INDEX IF NOT EXISTS idx_sysconfig_category ON system_configuration(category);

-- ============================================================
-- 2. ENHANCE categories TABLE
--    Adds service_key (which service this category belongs to),
--    display_order, color, parent, active flag
-- ============================================================
ALTER TABLE categories
    ADD COLUMN IF NOT EXISTS service_key        VARCHAR(80),
    ADD COLUMN IF NOT EXISTS display_order      INT         NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS color_hex          VARCHAR(10),
    ADD COLUMN IF NOT EXISTS parent_category_id UUID        REFERENCES categories(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS is_active          BOOLEAN     NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS metadata           JSONB       NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_categories_service   ON categories(service_key) WHERE service_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categories_active    ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_order     ON categories(display_order);
CREATE INDEX IF NOT EXISTS idx_categories_parent    ON categories(parent_category_id) WHERE parent_category_id IS NOT NULL;

-- ============================================================
-- 3. ENHANCE products TABLE
--    Adds service_key, is_active, status columns
-- ============================================================
ALTER TABLE products
    ADD COLUMN IF NOT EXISTS service_key VARCHAR(80),
    ADD COLUMN IF NOT EXISTS is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS status      VARCHAR(50)  NOT NULL DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS metadata    JSONB        NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_products_service_key ON products(service_key) WHERE service_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_status      ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_active      ON products(is_active);

-- ============================================================
-- 4. ENHANCE shops TABLE
--    Adds service_keys (array of services this shop provides),
--    display metadata, rating, working hours
-- ============================================================
ALTER TABLE shops
    ADD COLUMN IF NOT EXISTS service_keys      JSONB        NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS description       TEXT,
    ADD COLUMN IF NOT EXISTS logo_url          TEXT,
    ADD COLUMN IF NOT EXISTS banner_url        TEXT,
    ADD COLUMN IF NOT EXISTS rating            NUMERIC(3,2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS opening_time      VARCHAR(10),
    ADD COLUMN IF NOT EXISTS closing_time      VARCHAR(10),
    ADD COLUMN IF NOT EXISTS delivery_fee      NUMERIC(10,4) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS min_order_value   NUMERIC(10,4) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS avg_prep_minutes  INT          DEFAULT 15,
    ADD COLUMN IF NOT EXISTS latitude          NUMERIC(12,8),
    ADD COLUMN IF NOT EXISTS longitude         NUMERIC(12,8),
    ADD COLUMN IF NOT EXISTS metadata          JSONB        NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_shops_service_keys ON shops USING GIN(service_keys);

-- ============================================================
-- 5. ENHANCE orders TABLE
--    Remove hardcoded DRAFT default; add service_key for workflow routing
-- ============================================================
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS service_key VARCHAR(80);

-- Update default to NULL — initial status comes from workflow_step_definitions
ALTER TABLE orders ALTER COLUMN status SET DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_service_key ON orders(service_key) WHERE service_key IS NOT NULL;
