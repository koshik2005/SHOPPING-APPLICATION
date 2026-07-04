-- ==============================================================================
-- V16__seed_dynamic_data.sql
-- HyperLocal Platform — Seed All Dynamic Configuration Data
--
-- Populates:
--   1. platform_services      — Initial service catalog
--   2. navigation_menus       — Enterprise Portal sidebar
--   3. feature_flags          — All major feature toggles
--   4. workflow_step_defs     — Order workflows per service type
--   5. pricing_rules          — Default platform pricing
--   6. banners                — Placeholder banners (branch-independent)
--   7. localisation_strings   — English (en) base strings
--   8. product_attribute_schemas — Schemas per service type
--   9. system_configuration   — Scoped platform-wide settings
-- ==============================================================================

-- ============================================================
-- 1. PLATFORM SERVICES — Service Registry
-- ============================================================
INSERT INTO platform_services
    (service_key, display_name, icon_url, color_hex, route_path, is_active, display_order, feature_flag_key, metadata)
VALUES
  ('food',        'Restaurants',      'restaurant',           '#FF6D00', '/shop/food',       TRUE,  1, 'feature.food',       '{"appRoute": "/shop/food"}'),
  ('grocery',     'Grocery',          'local_grocery_store',  '#2E7D32', '/shop/grocery',    TRUE,  2, 'feature.grocery',    '{"appRoute": "/shop/grocery"}'),
  ('medicine',    'Pharmacy',         'local_pharmacy',       '#1565C0', '/shop/medicine',   TRUE,  3, 'feature.medicine',   '{"appRoute": "/shop/medicine"}'),
  ('rides',       'Ride Booking',     'directions_car',       '#4A148C', '/rides',           TRUE,  4, 'feature.rides',      '{"appRoute": "/rides"}'),
  ('courier',     'Courier / Parcel', 'inventory_2',          '#E65100', '/parcel',          TRUE,  5, 'feature.courier',    '{"appRoute": "/parcel"}'),
  ('marketplace', 'Marketplace',      'storefront',           '#00695C', '/shop/marketplace',TRUE,  6, 'feature.marketplace','{"appRoute": "/shop/marketplace"}'),
  ('agriculture', 'FarmFresh',        '🌾',                   '#558B2F', '/shop/agriculture',FALSE, 7, 'feature.agriculture','{"appRoute": "/shop/agriculture"}'),
  ('hotel',       'Hotels',           '🏨',                   '#B71C1C', '/hotels',          FALSE, 8, 'feature.hotel',      '{"appRoute": "/hotels"}'),
  ('laundry',     'Laundry',          '👕',                   '#0277BD', '/laundry',         FALSE, 9, 'feature.laundry',    '{"appRoute": "/laundry"}'),
  ('doctor',      'Doctor Consult',   '🏥',                   '#AD1457', '/doctor',          FALSE,10, 'feature.doctor',     '{"appRoute": "/doctor"}');

-- ============================================================
-- 2. NAVIGATION MENUS — Enterprise Portal Sidebar
--    Replaces the hardcoded SIDEBAR_ITEMS in Layout.tsx
-- ============================================================
INSERT INTO navigation_menus
    (menu_key, portal_target, display_label, icon_key, route_path, permission_key, display_order, is_active, section_label)
VALUES
  -- Main
  ('nav.dashboard',        'ENTERPRISE', 'Dashboard',         'Dashboard',          '/',                'dashboard:view',        1,  TRUE, 'MAIN'),
  -- Operations
  ('nav.branches',         'ENTERPRISE', 'Branches',          'Room',               '/branches',        'branches:view',         10, TRUE, 'OPERATIONS'),
  ('nav.shops',            'ENTERPRISE', 'Shops',             'Store',              '/shops',           'shops:view',            11, TRUE, 'OPERATIONS'),
  ('nav.service-registry', 'ENTERPRISE', 'Service Registry',  'AppRegistration',    '/service-registry','service-registry:view', 12, TRUE, 'OPERATIONS'),
  -- Inventory
  ('nav.products',         'ENTERPRISE', 'Products',          'Inventory',          '/products',        'products:view',         20, TRUE, 'INVENTORY'),
  ('nav.inventory',        'ENTERPRISE', 'Inventory',         'Assessment',         '/inventory',       'inventory:view',        21, TRUE, 'INVENTORY'),
  ('nav.form-builder',     'ENTERPRISE', 'Product Schemas',   'DynamicForm',        '/form-builder',    'products:write',        22, TRUE, 'INVENTORY'),
  -- Commerce
  ('nav.orders',           'ENTERPRISE', 'Orders',            'ShoppingCart',       '/orders',          'orders:view',           30, TRUE, 'COMMERCE'),
  ('nav.delivery',         'ENTERPRISE', 'Delivery Tracking', 'LocalShipping',      '/delivery',        'delivery:view',         31, TRUE, 'COMMERCE'),
  ('nav.payments',         'ENTERPRISE', 'Payments',          'ReceiptLong',        '/payments',        'payments:view',         32, TRUE, 'COMMERCE'),
  ('nav.wallet',           'ENTERPRISE', 'Wallet Ledger',     'AccountBalanceWallet','/wallet',         'wallet:view',           33, TRUE, 'COMMERCE'),
  ('nav.pricing',          'ENTERPRISE', 'Pricing Engine',    'PriceChange',        '/pricing',         'pricing:view',          34, TRUE, 'COMMERCE'),
  ('nav.workflow',         'ENTERPRISE', 'Workflow Designer', 'AccountTree',        '/workflow',        'workflow:view',         35, TRUE, 'COMMERCE'),
  -- Users
  ('nav.customers',        'ENTERPRISE', 'Customers',         'People',             '/customers',       'customers:view',        40, TRUE, 'USERS'),
  ('nav.users',            'ENTERPRISE', 'User Management',   'AdminPanelSettings', '/users',           'users:view',            41, TRUE, 'USERS'),
  ('nav.rbac',             'ENTERPRISE', 'RBAC Settings',     'Security',           '/rbac',            'rbac:view',             42, TRUE, 'USERS'),
  ('nav.notifications',    'ENTERPRISE', 'Notifications',     'Notifications',      '/notifications',   'notifications:view',    43, TRUE, 'USERS'),
  -- Content
  ('nav.banners',          'ENTERPRISE', 'Banner Manager',    'Image',              '/banners',         'banners:view',          50, TRUE, 'CONTENT'),
  ('nav.localisation',     'ENTERPRISE', 'Localisation',      'Translate',          '/localisation',    'localisation:view',     51, TRUE, 'CONTENT'),
  -- Platform
  ('nav.feature-flags',    'ENTERPRISE', 'Feature Flags',     'ToggleOn',           '/feature-flags',   'feature-flags:view',    60, TRUE, 'PLATFORM'),
  ('nav.security',         'ENTERPRISE', 'Security Center',   'Shield',             '/security-center', 'security:view',         61, TRUE, 'PLATFORM'),
  ('nav.audit-logs',       'ENTERPRISE', 'Audit Logs',        'ManageSearch',       '/audit-logs',      'audit-logs:view',       62, TRUE, 'PLATFORM'),
  ('nav.system-settings',  'ENTERPRISE', 'System Settings',   'Settings',           '/system-settings', 'system-settings:view',  63, TRUE, 'PLATFORM'),
  ('nav.support',          'ENTERPRISE', 'Resolution Center', 'Help',               '/support',         'customers:view',        64, TRUE, 'PLATFORM'),
  ('nav.testing',          'ENTERPRISE', 'Testing Tools',     'BugReport',          '/testing-tools',   'testing-tools:view',    99, TRUE, 'DEVOPS');

-- ============================================================
-- 3. FEATURE FLAGS — All Major Features
-- ============================================================
INSERT INTO feature_flags (flag_key, is_enabled, scope, description) VALUES
  ('feature.food',          TRUE,  'GLOBAL', 'Food/Restaurant ordering service'),
  ('feature.grocery',       TRUE,  'GLOBAL', 'Grocery ordering service'),
  ('feature.medicine',      TRUE,  'GLOBAL', 'Pharmacy/medicine ordering service'),
  ('feature.rides',         TRUE,  'GLOBAL', 'Ride booking service'),
  ('feature.courier',       TRUE,  'GLOBAL', 'Courier/parcel delivery service'),
  ('feature.marketplace',   TRUE,  'GLOBAL', 'General marketplace service'),
  ('feature.agriculture',   FALSE, 'GLOBAL', 'Agriculture/farm-fresh service'),
  ('feature.hotel',         FALSE, 'GLOBAL', 'Hotel booking service'),
  ('feature.laundry',       FALSE, 'GLOBAL', 'Laundry service'),
  ('feature.doctor',        FALSE, 'GLOBAL', 'Doctor consultation service'),
  ('feature.wallet',        TRUE,  'GLOBAL', 'In-app wallet feature'),
  ('feature.notifications', TRUE,  'GLOBAL', 'Push notification feature'),
  ('feature.analytics',     TRUE,  'GLOBAL', 'Analytics and reporting'),
  ('feature.maps',          TRUE,  'GLOBAL', 'Delivery tracking maps'),
  ('feature.otp_login',     TRUE,  'GLOBAL', 'OTP login method'),
  ('feature.google_login',  TRUE,  'GLOBAL', 'Google OAuth login'),
  ('feature.mfa',           FALSE, 'GLOBAL', 'Multi-factor authentication enforcement'),
  ('feature.maintenance',   FALSE, 'GLOBAL', 'Platform maintenance mode');

-- ============================================================
-- 4. WORKFLOW STEP DEFINITIONS — Per Service Type
-- ============================================================

-- Food/Grocery/Medicine Order Workflow
INSERT INTO workflow_step_definitions
    (service_key, step_key, display_label, is_initial, is_terminal, allowed_next_steps, allowed_roles, display_order, color_hex)
VALUES
  ('food', 'PENDING',    'Order Placed',      TRUE,  FALSE, '["ACCEPTED","CANCELLED"]',                    '["ROLE_SHOP_OWNER","ROLE_SHOP_MANAGER"]', 1, '#FF9800'),
  ('food', 'ACCEPTED',   'Accepted',          FALSE, FALSE, '["PREPARING","CANCELLED"]',                   '["ROLE_SHOP_OWNER","ROLE_SHOP_MANAGER"]', 2, '#2196F3'),
  ('food', 'PREPARING',  'Preparing',         FALSE, FALSE, '["READY"]',                                   '["ROLE_SHOP_OWNER","ROLE_SHOP_MANAGER"]', 3, '#9C27B0'),
  ('food', 'READY',      'Ready for Pickup',  FALSE, FALSE, '["PICKED_UP"]',                               '["ROLE_DELIVERY_AGENT"]',                 4, '#00BCD4'),
  ('food', 'PICKED_UP',  'Picked Up',         FALSE, FALSE, '["DELIVERED","FAILED"]',                      '["ROLE_DELIVERY_AGENT"]',                 5, '#FF5722'),
  ('food', 'DELIVERED',  'Delivered',         FALSE, TRUE,  '[]',                                          '["ROLE_DELIVERY_AGENT"]',                 6, '#4CAF50'),
  ('food', 'CANCELLED',  'Cancelled',         FALSE, TRUE,  '[]',                                          '["ROLE_SHOP_OWNER","ROLE_SUPPORT_AGENT"]', 7, '#F44336'),
  ('food', 'FAILED',     'Delivery Failed',   FALSE, TRUE,  '["PENDING"]',                                 '["ROLE_DELIVERY_AGENT","ROLE_SUPPORT_AGENT"]', 8, '#795548');

-- Ride Booking Workflow
INSERT INTO workflow_step_definitions
    (service_key, step_key, display_label, is_initial, is_terminal, allowed_next_steps, allowed_roles, display_order, color_hex)
VALUES
  ('rides', 'REQUESTED',   'Ride Requested',    TRUE,  FALSE, '["DRIVER_ASSIGNED","CANCELLED"]',             '[]',                                      1, '#FF9800'),
  ('rides', 'DRIVER_ASSIGNED','Driver Assigned', FALSE, FALSE, '["DRIVER_EN_ROUTE","CANCELLED"]',             '["ROLE_DELIVERY_AGENT"]',                 2, '#2196F3'),
  ('rides', 'DRIVER_EN_ROUTE','Driver En Route', FALSE, FALSE, '["ARRIVED"]',                                 '["ROLE_DELIVERY_AGENT"]',                 3, '#9C27B0'),
  ('rides', 'ARRIVED',     'Driver Arrived',    FALSE, FALSE, '["IN_PROGRESS"]',                             '["ROLE_DELIVERY_AGENT"]',                 4, '#00BCD4'),
  ('rides', 'IN_PROGRESS', 'Ride In Progress',  FALSE, FALSE, '["COMPLETED"]',                               '["ROLE_DELIVERY_AGENT"]',                 5, '#FF5722'),
  ('rides', 'COMPLETED',   'Completed',         FALSE, TRUE,  '[]',                                          '["ROLE_DELIVERY_AGENT"]',                 6, '#4CAF50'),
  ('rides', 'CANCELLED',   'Cancelled',         FALSE, TRUE,  '[]',                                          '["ROLE_DELIVERY_AGENT","ROLE_SUPPORT_AGENT"]', 7, '#F44336');

-- Courier Workflow
INSERT INTO workflow_step_definitions
    (service_key, step_key, display_label, is_initial, is_terminal, allowed_next_steps, allowed_roles, display_order, color_hex)
VALUES
  ('courier', 'PENDING',        'Pickup Requested', TRUE,  FALSE, '["PICKED_UP","CANCELLED"]',                '[]',                                      1, '#FF9800'),
  ('courier', 'PICKED_UP',      'Package Picked Up',FALSE, FALSE, '["IN_TRANSIT"]',                          '["ROLE_DELIVERY_AGENT"]',                 2, '#2196F3'),
  ('courier', 'IN_TRANSIT',     'In Transit',       FALSE, FALSE, '["OUT_FOR_DELIVERY","FAILED"]',            '["ROLE_DELIVERY_AGENT"]',                 3, '#9C27B0'),
  ('courier', 'OUT_FOR_DELIVERY','Out for Delivery', FALSE, FALSE, '["DELIVERED","FAILED"]',                  '["ROLE_DELIVERY_AGENT"]',                 4, '#FF5722'),
  ('courier', 'DELIVERED',      'Delivered',        FALSE, TRUE,  '[]',                                      '["ROLE_DELIVERY_AGENT"]',                 5, '#4CAF50'),
  ('courier', 'CANCELLED',      'Cancelled',        FALSE, TRUE,  '[]',                                      '["ROLE_SUPPORT_AGENT"]',                  6, '#F44336'),
  ('courier', 'FAILED',         'Failed',           FALSE, TRUE,  '["PENDING"]',                             '["ROLE_DELIVERY_AGENT","ROLE_SUPPORT_AGENT"]', 7, '#795548');

-- Generic (Grocery, Medicine, Marketplace)
INSERT INTO workflow_step_definitions
    (service_key, step_key, display_label, is_initial, is_terminal, allowed_next_steps, allowed_roles, display_order, color_hex)
SELECT
  s.service_key, w.step_key, w.display_label, w.is_initial, w.is_terminal,
  w.allowed_next_steps, w.allowed_roles, w.display_order, w.color_hex
FROM
  (VALUES ('grocery'), ('medicine'), ('marketplace')) AS s(service_key),
  (SELECT step_key, display_label, is_initial, is_terminal, allowed_next_steps, allowed_roles, display_order, color_hex
   FROM workflow_step_definitions WHERE service_key = 'food') AS w
ON CONFLICT (service_key, step_key) DO NOTHING;

-- ============================================================
-- 5. PRICING RULES — Default Platform Pricing
-- ============================================================
INSERT INTO pricing_rules (rule_key, service_key, branch_id, value, value_type, priority, description) VALUES
  ('base_delivery_fee',    'food',        NULL, 2.50, 'FLAT',    10, 'Base delivery fee for food orders'),
  ('base_delivery_fee',    'grocery',     NULL, 1.99, 'FLAT',    10, 'Base delivery fee for grocery orders'),
  ('base_delivery_fee',    'medicine',    NULL, 0.00, 'FLAT',    10, 'Free delivery for medicine orders'),
  ('base_delivery_fee',    'courier',     NULL, 5.00, 'FLAT',    10, 'Base pickup + delivery fee for courier'),
  ('delivery_fee_per_km',  NULL,          NULL, 0.50, 'FLAT',     5, 'Per kilometer charge added to base delivery fee'),
  ('platform_fee',         NULL,          NULL, 0.50, 'FLAT',    10, 'Platform service fee per order'),
  ('tax_rate',             NULL,          NULL, 8.00, 'PERCENT', 10, 'GST/Tax rate applied to order total'),
  ('surge_multiplier_max', 'rides',       NULL, 2.50, 'FLAT',     5, 'Maximum surge multiplier for rides'),
  ('commission_rate',      'food',        NULL,15.00, 'PERCENT', 10, 'Platform commission charged to shop'),
  ('commission_rate',      'grocery',     NULL,12.00, 'PERCENT', 10, 'Platform commission charged to shop'),
  ('commission_rate',      'rides',       NULL,20.00, 'PERCENT', 10, 'Platform commission on ride fare'),
  ('min_order_value',      'food',        NULL,99.00, 'FLAT',    10, 'Minimum order value for food delivery');

-- ============================================================
-- 6. BANNERS — Platform-Wide Default Banners
-- ============================================================
INSERT INTO banners
    (branch_id, title, subtitle, action_route, background_colors, icon_key, display_order, is_active)
VALUES
  (NULL, 'Welcome to HyperLocal', 'Your neighbourhood, delivered',
   '/home', '["#1565C0","#0D47A1"]', 'local_mall', 1, TRUE),
  (NULL, 'Fast Delivery',         'Orders delivered in 30 minutes',
   '/shop/food', '["#E65100","#BF360C"]', 'delivery_dining', 2, TRUE),
  (NULL, 'Fresh Grocery',         'Farm-fresh produce at your door',
   '/shop/grocery', '["#2E7D32","#1B5E20"]', 'eco', 3, TRUE);

-- ============================================================
-- 7. LOCALISATION STRINGS — English (en) Base Set
-- ============================================================
INSERT INTO localisation_strings (string_key, locale, value) VALUES
  ('home.search.placeholder',        'en', 'Search food, groceries, services...'),
  ('home.section.explore_services',  'en', 'Explore Services'),
  ('home.section.popular_near_you',  'en', 'Popular Near You'),
  ('home.section.recommended',       'en', 'Recommended for You'),
  ('home.greeting.morning',          'en', 'Good morning'),
  ('home.greeting.afternoon',        'en', 'Good afternoon'),
  ('home.greeting.evening',          'en', 'Good evening'),
  ('home.delivering_to',             'en', 'DELIVERING TO'),
  ('home.select_branch',             'en', 'Select Delivery Branch'),
  ('order.status.PENDING',           'en', 'Order Placed'),
  ('order.status.ACCEPTED',          'en', 'Accepted'),
  ('order.status.PREPARING',         'en', 'Preparing'),
  ('order.status.READY',             'en', 'Ready for Pickup'),
  ('order.status.PICKED_UP',         'en', 'Picked Up'),
  ('order.status.DELIVERED',         'en', 'Delivered'),
  ('order.status.CANCELLED',         'en', 'Cancelled'),
  ('order.status.FAILED',            'en', 'Delivery Failed'),
  ('ride.status.REQUESTED',          'en', 'Looking for driver'),
  ('ride.status.DRIVER_ASSIGNED',    'en', 'Driver assigned'),
  ('ride.status.DRIVER_EN_ROUTE',    'en', 'Driver on the way'),
  ('ride.status.ARRIVED',            'en', 'Driver arrived'),
  ('ride.status.IN_PROGRESS',        'en', 'Ride in progress'),
  ('ride.status.COMPLETED',          'en', 'Ride completed'),
  ('ride.status.CANCELLED',          'en', 'Ride cancelled'),
  ('common.service.food',            'en', 'Restaurants'),
  ('common.service.grocery',         'en', 'Grocery'),
  ('common.service.medicine',        'en', 'Pharmacy'),
  ('common.service.rides',           'en', 'Ride Booking'),
  ('common.service.courier',         'en', 'Courier'),
  ('common.service.marketplace',     'en', 'Marketplace'),
  ('cart.empty',                     'en', 'Your cart is empty'),
  ('auth.login.title',               'en', 'Welcome Back'),
  ('auth.login.subtitle',            'en', 'Sign in to continue'),
  ('error.no_service_area',          'en', 'We are not serving this area yet'),
  ('error.no_products',              'en', 'No products available'),
  ('error.network',                  'en', 'Network error. Please try again.');

-- ============================================================
-- 8. PRODUCT ATTRIBUTE SCHEMAS — Per Service Type
-- ============================================================

-- Food service attributes
INSERT INTO product_attribute_schemas
    (service_key, attribute_key, display_label, field_type, is_required, is_filterable, dropdown_options, display_order)
VALUES
  ('food', 'cuisine_type',    'Cuisine Type',      'DROPDOWN',   TRUE,  TRUE,  '["Indian","Chinese","Italian","Continental","Mexican","Thai","American","Japanese"]', 1),
  ('food', 'is_vegetarian',   'Vegetarian',        'BOOLEAN',    TRUE,  TRUE,  '[]',                                                                                  2),
  ('food', 'is_vegan',        'Vegan',             'BOOLEAN',    FALSE, TRUE,  '[]',                                                                                  3),
  ('food', 'spice_level',     'Spice Level',       'DROPDOWN',   FALSE, TRUE,  '["Mild","Medium","Hot","Extra Hot"]',                                                 4),
  ('food', 'allergens',       'Allergens',         'MULTISELECT',FALSE, FALSE, '["Nuts","Dairy","Gluten","Soy","Eggs","Shellfish"]',                                  5),
  ('food', 'prep_time_mins',  'Prep Time (mins)',  'NUMBER',     TRUE,  FALSE, '[]',                                                                                  6),
  ('food', 'calories',        'Calories (kcal)',   'NUMBER',     FALSE, FALSE, '[]',                                                                                  7),
  ('food', 'portion_size',    'Portion Size',      'TEXT',       FALSE, FALSE, '[]',                                                                                  8);

-- Grocery attributes
INSERT INTO product_attribute_schemas
    (service_key, attribute_key, display_label, field_type, is_required, is_filterable, dropdown_options, display_order)
VALUES
  ('grocery', 'brand',          'Brand',           'TEXT',       FALSE, TRUE,  '[]',                                          1),
  ('grocery', 'weight_grams',   'Weight (grams)',  'NUMBER',     TRUE,  FALSE, '[]',                                          2),
  ('grocery', 'unit_type',      'Unit Type',       'DROPDOWN',   TRUE,  TRUE,  '["kg","g","L","ml","pcs","dozen","pack"]',    3),
  ('grocery', 'is_organic',     'Organic',         'BOOLEAN',    FALSE, TRUE,  '[]',                                          4),
  ('grocery', 'expiry_days',    'Shelf Life (days)','NUMBER',    FALSE, FALSE, '[]',                                          5),
  ('grocery', 'storage_temp',   'Storage Temp',    'DROPDOWN',   FALSE, FALSE, '["Room Temp","Refrigerated","Frozen"]',       6),
  ('grocery', 'country_origin', 'Country of Origin','TEXT',      FALSE, TRUE,  '[]',                                          7);

-- Medicine attributes
INSERT INTO product_attribute_schemas
    (service_key, attribute_key, display_label, field_type, is_required, is_filterable, dropdown_options, display_order)
VALUES
  ('medicine', 'generic_name',   'Generic Name',    'TEXT',       TRUE,  TRUE,  '[]',                                          1),
  ('medicine', 'manufacturer',   'Manufacturer',    'TEXT',       TRUE,  FALSE, '[]',                                          2),
  ('medicine', 'dosage_form',    'Dosage Form',     'DROPDOWN',   TRUE,  TRUE,  '["Tablet","Capsule","Syrup","Injection","Cream","Drops","Inhaler"]', 3),
  ('medicine', 'strength',       'Strength',        'TEXT',       TRUE,  FALSE, '[]',                                          4),
  ('medicine', 'requires_rx',    'Prescription Required','BOOLEAN',TRUE, TRUE,  '[]',                                          5),
  ('medicine', 'pack_size',      'Pack Size',       'TEXT',       TRUE,  FALSE, '[]',                                          6),
  ('medicine', 'storage_instr',  'Storage Instructions','TEXTAREA',FALSE,FALSE,  '[]',                                          7);

-- Marketplace (general)
INSERT INTO product_attribute_schemas
    (service_key, attribute_key, display_label, field_type, is_required, is_filterable, dropdown_options, display_order)
VALUES
  ('marketplace', 'brand',        'Brand',          'TEXT',       FALSE, TRUE,  '[]',                                          1),
  ('marketplace', 'condition',    'Condition',      'DROPDOWN',   TRUE,  TRUE,  '["New","Like New","Good","Fair"]',             2),
  ('marketplace', 'warranty',     'Warranty',       'TEXT',       FALSE, FALSE, '[]',                                          3),
  ('marketplace', 'color',        'Color',          'TEXT',       FALSE, TRUE,  '[]',                                          4),
  ('marketplace', 'material',     'Material',       'TEXT',       FALSE, TRUE,  '[]',                                          5),
  ('marketplace', 'dimensions',   'Dimensions',     'TEXT',       FALSE, FALSE, '[]',                                          6),
  ('marketplace', 'weight_kg',    'Weight (kg)',    'DECIMAL',    FALSE, FALSE, '[]',                                          7);

-- ============================================================
-- 9. SYSTEM CONFIGURATION — Scoped Platform Settings
--    Replaces hardcoded values in SystemConfig.tsx
-- ============================================================
INSERT INTO system_configuration (config_key, config_value, category, scope, data_type, description) VALUES
  ('platform.name',              'HyperLocal',          'BRAND',    'GLOBAL', 'STRING',  'Platform display name'),
  ('platform.tagline',           'Your Neighbourhood, Delivered', 'BRAND', 'GLOBAL', 'STRING', 'Platform tagline'),
  ('platform.currency.default',  'INR',                 'FINANCE',  'GLOBAL', 'STRING',  'Default currency code'),
  ('platform.currency.symbol',   '₹',                   'FINANCE',  'GLOBAL', 'STRING',  'Default currency symbol'),
  ('platform.currency.supported',
   '["INR","USD","EUR","GBP","SGD","AED","SAR"]',       'FINANCE',  'GLOBAL', 'JSON',    'Supported currency codes'),
  ('platform.tax.gst_rate',      '18.00',               'FINANCE',  'GLOBAL', 'DECIMAL', 'Default GST rate (%)'),
  ('platform.locale.default',    'en',                  'I18N',     'GLOBAL', 'STRING',  'Default locale'),
  ('platform.locale.supported',  '["en","hi","ta","te","ml","kn","bn"]', 'I18N', 'GLOBAL', 'JSON', 'Supported locales'),
  ('platform.version',           '2.5.0',               'SYSTEM',   'GLOBAL', 'STRING',  'Platform version'),
  ('platform.maintenance_mode',  'false',               'SYSTEM',   'GLOBAL', 'BOOLEAN', 'Maintenance mode flag'),
  ('platform.otp.length',        '6',                   'AUTH',     'GLOBAL', 'INTEGER', 'OTP digit count'),
  ('platform.otp.expiry_seconds','120',                  'AUTH',     'GLOBAL', 'INTEGER', 'OTP validity in seconds'),
  ('platform.otp.max_attempts',  '5',                   'AUTH',     'GLOBAL', 'INTEGER', 'Max OTP verification attempts'),
  ('platform.session.timeout',   '3600',                'AUTH',     'GLOBAL', 'INTEGER', 'Session timeout in seconds'),
  ('platform.session.max_devices','3',                  'AUTH',     'GLOBAL', 'INTEGER', 'Max concurrent devices per user'),
  ('platform.login.max_attempts','5',                   'AUTH',     'GLOBAL', 'INTEGER', 'Max failed login attempts before lockout'),
  ('platform.login.lockout_minutes','30',               'AUTH',     'GLOBAL', 'INTEGER', 'Account lockout duration in minutes'),
  ('platform.delivery.radius_km','10',                  'DELIVERY', 'GLOBAL', 'DECIMAL', 'Default max delivery radius in km'),
  ('platform.geofence.enabled',  'true',                'DELIVERY', 'GLOBAL', 'BOOLEAN', 'Enable geofence restriction'),
  ('smtp.host',                  'mailhog',             'SMTP',     'GLOBAL', 'STRING',  'SMTP server host', TRUE, FALSE),
  ('smtp.port',                  '1025',                'SMTP',     'GLOBAL', 'INTEGER', 'SMTP server port'),
  ('smtp.from',                  'noreply@hyperlocal.app','SMTP',   'GLOBAL', 'STRING',  'SMTP sender address'),
  ('platform.terms_url',         '/legal/terms',        'LEGAL',    'GLOBAL', 'URL',     'Terms and conditions URL'),
  ('platform.privacy_url',       '/legal/privacy',      'LEGAL',    'GLOBAL', 'URL',     'Privacy policy URL')
ON CONFLICT ON CONSTRAINT uq_config_key_scope DO NOTHING;
