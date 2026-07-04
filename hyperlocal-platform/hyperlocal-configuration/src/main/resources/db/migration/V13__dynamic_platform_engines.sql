-- ==============================================================================
-- V13__dynamic_platform_engines.sql
-- HyperLocal Platform — Dynamic Engine Tables
--
-- Creates the foundational tables for zero-hardcoding architecture:
--   1. platform_services       — Dynamic Service Registry
--   2. navigation_menus        — Server-driven Portal Navigation
--   3. feature_flags           — Runtime Feature Toggles
--   4. banners                 — Dynamic Home Screen Banners
--   5. pricing_rules           — Configurable Pricing Engine
--   6. workflow_step_definitions — Configurable Workflow Engine
--   7. product_attribute_schemas — Dynamic Product Attribute Engine
--   8. product_attribute_values  — Per-product Dynamic Attribute Values
--   9. localisation_strings    — i18n Engine
-- ==============================================================================

-- ============================================================
-- 1. SERVICE REGISTRY
--    Replaces ALL hardcoded service lists in Flutter/Portal.
--    Admin adds "Hotel", "Laundry", etc. here and clients auto-display it.
-- ============================================================
CREATE TABLE platform_services (
    id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_key      VARCHAR(80)  NOT NULL UNIQUE,
    display_name     VARCHAR(150) NOT NULL,
    icon_url         TEXT,
    color_hex        VARCHAR(10),
    route_path       VARCHAR(255),
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    display_order    INT          NOT NULL DEFAULT 0,
    feature_flag_key VARCHAR(100),
    metadata         JSONB        NOT NULL DEFAULT '{}',
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_platform_services_active   ON platform_services(is_active);
CREATE INDEX idx_platform_services_order    ON platform_services(display_order);

-- Branch-level service overrides (enable/disable per branch)
CREATE TABLE branch_service_config (
    id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id    UUID        NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    service_key  VARCHAR(80) NOT NULL,
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
    override_order INT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_id, service_key)
);

-- ============================================================
-- 2. NAVIGATION MENUS
--    Portal sidebar, bottom nav, section headers — all DB-driven.
--    No SIDEBAR_ITEMS array in code ever again.
-- ============================================================
CREATE TABLE navigation_menus (
    id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_key       VARCHAR(100) NOT NULL UNIQUE,
    portal_target  VARCHAR(50)  NOT NULL DEFAULT 'ENTERPRISE',
    display_label  VARCHAR(150) NOT NULL,
    icon_key       VARCHAR(100),
    route_path     VARCHAR(255),
    permission_key VARCHAR(150),
    display_order  INT          NOT NULL DEFAULT 0,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    parent_id      UUID         REFERENCES navigation_menus(id) ON DELETE SET NULL,
    section_label  VARCHAR(100),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nav_menus_portal   ON navigation_menus(portal_target, is_active);
CREATE INDEX idx_nav_menus_order    ON navigation_menus(display_order);
CREATE INDEX idx_nav_menus_parent   ON navigation_menus(parent_id);

-- ============================================================
-- 3. FEATURE FLAGS
--    Every major feature can be toggled without a code deploy.
-- ============================================================
CREATE TABLE feature_flags (
    id         UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    flag_key   VARCHAR(100) NOT NULL,
    is_enabled BOOLEAN      NOT NULL DEFAULT FALSE,
    scope      VARCHAR(20)  NOT NULL DEFAULT 'GLOBAL'
                            CHECK (scope IN ('GLOBAL','BRANCH','USER','ROLE')),
    scope_id   UUID,
    description TEXT,
    metadata   JSONB        NOT NULL DEFAULT '{}',
    updated_by UUID,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (flag_key, scope, scope_id)
);

CREATE INDEX idx_feature_flags_key_scope ON feature_flags(flag_key, scope);
CREATE INDEX idx_feature_flags_scope_id  ON feature_flags(scope_id) WHERE scope_id IS NOT NULL;

-- ============================================================
-- 4. BANNERS
--    Flutter home screen banners & promotional carousels.
--    No hardcoded "50% OFF" or "FREE Delivery" in Dart ever again.
-- ============================================================
CREATE TABLE banners (
    id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id         UUID        REFERENCES branches(id) ON DELETE CASCADE,
    title             VARCHAR(200) NOT NULL,
    subtitle          TEXT,
    action_route      VARCHAR(255),
    background_colors JSONB       NOT NULL DEFAULT '[]',
    icon_key          VARCHAR(100),
    image_url         TEXT,
    display_order     INT         NOT NULL DEFAULT 0,
    is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
    valid_from        TIMESTAMPTZ,
    valid_to          TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_banners_branch_active ON banners(branch_id, is_active);
CREATE INDEX idx_banners_validity      ON banners(valid_from, valid_to) WHERE is_active = TRUE;

-- ============================================================
-- 5. PRICING RULES
--    Every fee, tax, commission, charge is configurable.
--    No hardcoded 2.50 delivery fee or 0.08 tax ever again.
-- ============================================================
CREATE TABLE pricing_rules (
    id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_key       VARCHAR(100) NOT NULL,
    service_key    VARCHAR(80),
    branch_id      UUID         REFERENCES branches(id) ON DELETE CASCADE,
    value          NUMERIC(14,4) NOT NULL,
    value_type     VARCHAR(20)   NOT NULL DEFAULT 'FLAT'
                                 CHECK (value_type IN ('FLAT','PERCENT','FORMULA')),
    formula        TEXT,
    conditions     JSONB         NOT NULL DEFAULT '{}',
    priority       INT           NOT NULL DEFAULT 0,
    effective_from TIMESTAMPTZ,
    effective_to   TIMESTAMPTZ,
    description    TEXT,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pricing_rules_key        ON pricing_rules(rule_key);
CREATE INDEX idx_pricing_rules_service    ON pricing_rules(service_key) WHERE service_key IS NOT NULL;
CREATE INDEX idx_pricing_rules_branch     ON pricing_rules(branch_id) WHERE branch_id IS NOT NULL;
CREATE INDEX idx_pricing_rules_priority   ON pricing_rules(priority DESC);

-- ============================================================
-- 6. WORKFLOW STEP DEFINITIONS
--    Replaces hardcoded "PENDING", "ACCEPTED", "DELIVERED" strings.
--    Each service type (food, ride, courier) has its own workflow.
-- ============================================================
CREATE TABLE workflow_step_definitions (
    id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_key   VARCHAR(80)  NOT NULL,
    step_key      VARCHAR(80)  NOT NULL,
    display_label VARCHAR(150) NOT NULL,
    description   TEXT,
    is_initial    BOOLEAN      NOT NULL DEFAULT FALSE,
    is_terminal   BOOLEAN      NOT NULL DEFAULT FALSE,
    allowed_next_steps JSONB   NOT NULL DEFAULT '[]',
    allowed_roles JSONB        NOT NULL DEFAULT '[]',
    display_order INT          NOT NULL DEFAULT 0,
    icon_key      VARCHAR(100),
    color_hex     VARCHAR(10),
    metadata      JSONB        NOT NULL DEFAULT '{}',
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (service_key, step_key)
);

CREATE INDEX idx_workflow_steps_service   ON workflow_step_definitions(service_key);
CREATE INDEX idx_workflow_steps_initial   ON workflow_step_definitions(service_key, is_initial);
CREATE INDEX idx_workflow_steps_order     ON workflow_step_definitions(service_key, display_order);

-- ============================================================
-- 7. PRODUCT ATTRIBUTE SCHEMAS
--    Dynamic Product Engine — eliminates FoodProduct, MedicineProduct, etc.
--    One Product entity + per-service-type attribute schema.
-- ============================================================
CREATE TABLE product_attribute_schemas (
    id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_key      VARCHAR(80)  NOT NULL,
    attribute_key    VARCHAR(100) NOT NULL,
    display_label    VARCHAR(150) NOT NULL,
    field_type       VARCHAR(30)  NOT NULL
                     CHECK (field_type IN ('TEXT','NUMBER','DECIMAL','BOOLEAN','DROPDOWN',
                                           'MULTISELECT','DATE','URL','COLOR','TEXTAREA')),
    is_required      BOOLEAN      NOT NULL DEFAULT FALSE,
    is_searchable    BOOLEAN      NOT NULL DEFAULT FALSE,
    is_filterable    BOOLEAN      NOT NULL DEFAULT FALSE,
    validation_rules JSONB        NOT NULL DEFAULT '{}',
    dropdown_options JSONB        NOT NULL DEFAULT '[]',
    default_value    TEXT,
    display_order    INT          NOT NULL DEFAULT 0,
    help_text        TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (service_key, attribute_key)
);

CREATE INDEX idx_attr_schemas_service ON product_attribute_schemas(service_key);
CREATE INDEX idx_attr_schemas_filter  ON product_attribute_schemas(service_key, is_filterable);

-- Product attribute values (per-product dynamic values)
CREATE TABLE product_attribute_values (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID        NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    attribute_key   VARCHAR(100) NOT NULL,
    attribute_value TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, attribute_key)
);

CREATE INDEX idx_attr_values_product ON product_attribute_values(product_id);
CREATE INDEX idx_attr_values_key     ON product_attribute_values(attribute_key);

-- ============================================================
-- 8. LOCALISATION STRINGS (i18n Engine)
--    All user-facing text loaded from DB.
--    "Search food, groceries..." → string_key='home.search.placeholder', locale='en'
-- ============================================================
CREATE TABLE localisation_strings (
    id           UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    string_key   VARCHAR(250) NOT NULL,
    locale       VARCHAR(10)  NOT NULL DEFAULT 'en',
    value        TEXT         NOT NULL,
    description  TEXT,
    last_updated TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   UUID,
    UNIQUE (string_key, locale)
);

CREATE INDEX idx_i18n_locale_key ON localisation_strings(locale, string_key);
