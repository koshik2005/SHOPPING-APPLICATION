-- Wallets and Pending Holds
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customer_profiles(id) UNIQUE,
    balance NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    version INT NOT NULL DEFAULT 0
);

CREATE TABLE wallet_transactions (
    id UUID NOT NULL,
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    amount NUMERIC(12, 4) NOT NULL,
    type VARCHAR(30) NOT NULL,
    reference_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE wallet_tx_y2026q1 PARTITION OF wallet_transactions FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');
CREATE TABLE wallet_tx_y2026q2 PARTITION OF wallet_transactions FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE wallet_holds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    hold_amount NUMERIC(12, 4) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'HELD',
    order_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
