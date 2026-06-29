-- Transactional Core: Partitioned Orders and Order Items
CREATE TABLE orders (
    id UUID NOT NULL,
    customer_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    status VARCHAR(30) NOT NULL,
    total_price NUMERIC(12, 4) NOT NULL,
    delivery_fee NUMERIC(8, 2) NOT NULL,
    tax_amount NUMERIC(8, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Initial Range Partitions (Quarterly partitioning)
CREATE TABLE orders_y2026q1 PARTITION OF orders FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');
CREATE TABLE orders_y2026q2 PARTITION OF orders FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE order_items (
    id UUID NOT NULL,
    order_id UUID NOT NULL,
    product_variant_id UUID NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(12, 4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
);

CREATE TABLE order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    status VARCHAR(30) NOT NULL,
    changed_by UUID NOT NULL,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
