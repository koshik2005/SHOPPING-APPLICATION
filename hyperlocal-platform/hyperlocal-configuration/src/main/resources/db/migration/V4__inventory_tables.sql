-- Shops and Product Inventory Management
CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id),
    name VARCHAR(100) NOT NULL,
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    version INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    icon_url TEXT,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL REFERENCES shops(id),
    category_id UUID NOT NULL REFERENCES categories(id),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ
);

CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku VARCHAR(100) NOT NULL UNIQUE,
    price NUMERIC(12, 4) NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_variant_id UUID NOT NULL REFERENCES product_variants(id) UNIQUE,
    branch_id UUID NOT NULL REFERENCES branches(id),
    available_qty INT NOT NULL DEFAULT 0,
    safety_stock_qty INT NOT NULL DEFAULT 10
);

CREATE TABLE inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id UUID NOT NULL REFERENCES inventory(id),
    qty_change INT NOT NULL,
    type VARCHAR(30) NOT NULL,
    reference_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indices for Catalog Searching
CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_product_variants_prod ON product_variants(product_id);
CREATE INDEX idx_inventory_variant ON inventory(product_variant_id);
