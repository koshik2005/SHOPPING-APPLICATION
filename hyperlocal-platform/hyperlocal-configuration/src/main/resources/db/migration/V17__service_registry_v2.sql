-- V17__service_registry_v2.sql
-- HyperLocal Enterprise Platform v3.1 Architecture Review Corrections

-- 1. Extend platform_services Table to Service Registry v2
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS theme_config JSONB DEFAULT '{}';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS priority INT DEFAULT 1;
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS maintenance_mode BOOLEAN DEFAULT FALSE;
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_countries JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_cities JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_vehicle_types JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_delivery_types JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_product_schemas JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_payment_methods JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS supported_roles JSONB DEFAULT '[]';
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS api_gateway_route VARCHAR(255);
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS microservice_name VARCHAR(100);
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS audit_enabled BOOLEAN DEFAULT TRUE;
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS security_level INT DEFAULT 1;
ALTER TABLE platform_services ADD COLUMN IF NOT EXISTS version INT DEFAULT 1;

-- 2. Category Engine Hierarchy v2 support
ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_category_id UUID REFERENCES categories(id);

-- 3. Shop Types Table
CREATE TABLE IF NOT EXISTS shop_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_key VARCHAR(50) UNIQUE NOT NULL,
    display_label VARCHAR(150) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Shop Types Taxonomy
INSERT INTO shop_types (type_key, display_label) VALUES
('RESTAURANT', 'Restaurant'),
('BAKERY', 'Bakery'),
('CAFE', 'Cafe'),
('MEDICAL_SHOP', 'Medical Shop'),
('CLINIC', 'Clinic'),
('HOSPITAL_PHARMACY', 'Hospital Pharmacy'),
('SUPERMARKET', 'Supermarket'),
('ELECTRONICS', 'Electronics'),
('FURNITURE', 'Furniture'),
('BOOKS', 'Books'),
('STATIONERY', 'Stationery'),
('MARKETPLACE_SELLER', 'Marketplace Seller'),
('COURIER_OFFICE', 'Courier Office'),
('RIDE_OPERATOR', 'Ride Operator'),
('AGRICULTURE_DEALER', 'Agriculture Dealer'),
('WAREHOUSE', 'Warehouse'),
('DISTRIBUTOR', 'Distributor'),
('MANUFACTURER', 'Manufacturer'),
('WHOLESALER', 'Wholesaler'),
('RETAILER', 'Retailer')
ON CONFLICT (type_key) DO NOTHING;

-- 4. Dynamic Product Types Linked to Categories
CREATE TABLE IF NOT EXISTS product_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES categories(id) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    attribute_schema_keys JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Enterprise Vehicle Registry
CREATE TABLE IF NOT EXISTS vehicle_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_key VARCHAR(50) UNIQUE NOT NULL,
    display_label VARCHAR(100) NOT NULL,
    max_payload_kg DECIMAL(10,2),
    volumetric_capacity_m3 DECIMAL(10,2),
    base_cost_multiplier DECIMAL(5,2) DEFAULT 1.00
);

INSERT INTO vehicle_types (type_key, display_label, max_payload_kg, volumetric_capacity_m3, base_cost_multiplier) VALUES
('bicycle', 'Bicycle', 15.00, 0.10, 1.00),
('motorcycle', 'Motorcycle', 40.00, 0.25, 1.20),
('electric_car', 'Electric Car', 300.00, 1.50, 1.80),
('van', 'Logistics Van', 800.00, 5.00, 2.50)
ON CONFLICT (type_key) DO NOTHING;

CREATE TABLE IF NOT EXISTS vehicle_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_type_id UUID REFERENCES vehicle_types(id) NOT NULL,
    branch_id UUID NOT NULL,
    driver_id UUID,
    plate_number VARCHAR(30) UNIQUE,
    make VARCHAR(100),
    model VARCHAR(100),
    year INT,
    insurance_number VARCHAR(100),
    insurance_expiry DATE,
    fitness_certificate_expiry DATE,
    permit_details VARCHAR(255),
    registration_certificate_url VARCHAR(255),
    inspection_status VARCHAR(30) DEFAULT 'PENDING',
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Zero Trust Security & Device Identity History
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    device_fingerprint VARCHAR(150) NOT NULL,
    trust_score DECIMAL(5,2) DEFAULT 100.00,
    last_ip VARCHAR(45),
    last_location_lat DECIMAL(10,8),
    last_location_lng DECIMAL(11,8),
    last_used TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, device_fingerprint)
);

CREATE TABLE IF NOT EXISTS password_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Notification Templates expansion
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_key VARCHAR(100) UNIQUE NOT NULL,
    title_pattern VARCHAR(255) NOT NULL,
    body_pattern TEXT NOT NULL,
    channel VARCHAR(20) DEFAULT 'PUSH', -- PUSH, SMS, EMAIL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO notification_templates (template_key, title_pattern, body_pattern, channel) VALUES
('ORDER_PLACED', 'Order Placed #{{orderId}}', 'Your order from {{shopName}} has been placed successfully.', 'PUSH'),
('ORDER_ACCEPTED', 'Order Accepted', 'The shop has accepted your order and is preparing it.', 'PUSH'),
('ORDER_DELIVERED', 'Delivered Successfully', 'Rider {{riderName}} delivered your order. Total: {{price}}.', 'PUSH'),
('MFA_CHALLENGE', 'Security OTP Code', 'Your temporary verification code is {{otpCode}}.', 'SMS'),
('IMPOSSIBLE_TRAVEL_LOCKED', 'Account Temporarily Locked', 'We detected anomalous travel speed from your session. Please verify your identity.', 'EMAIL')
ON CONFLICT (template_key) DO NOTHING;
