-- Workflow Configurations and Seed Initialization
CREATE TABLE workflow_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_name VARCHAR(50) NOT NULL UNIQUE,
    states JSONB NOT NULL,
    transitions JSONB NOT NULL
);

CREATE TABLE business_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(50) NOT NULL UNIQUE,
    conditions JSONB NOT NULL
);

-- Seed production configurations
INSERT INTO roles (id, name, description) VALUES 
    ('87ef769c-d021-4f11-ba32-aafe812bb31c', 'ROLE_SUPER_ADMIN', 'Super administrator credentials access role'),
    ('39cd7810-ff99-4c12-ab88-ffeeddaa2211', 'ROLE_CUSTOMER', 'Standard customer profile access role'),
    ('92ca1325-1ff2-4919-ab89-ffea210bb92c', 'ROLE_SHOP_OWNER', 'Shop merchant owner access role');
