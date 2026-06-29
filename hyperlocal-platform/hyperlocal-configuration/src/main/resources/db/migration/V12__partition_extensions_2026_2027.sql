-- V12: Add Q3 and Q4 2026 partitions for orders and wallet_transactions
-- These partitions must exist before the date range is reached.

-- Orders: Q3 2026 (July - September)
CREATE TABLE IF NOT EXISTS orders_2026q3
    PARTITION OF orders
    FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');

-- Orders: Q4 2026 (October - December)
CREATE TABLE IF NOT EXISTS orders_2026q4
    PARTITION OF orders
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');

-- Orders: Q1 2027 (January - March) — preemptive
CREATE TABLE IF NOT EXISTS orders_2027q1
    PARTITION OF orders
    FOR VALUES FROM ('2027-01-01') TO ('2027-04-01');

-- Orders: Q2 2027 (April - June) — preemptive
CREATE TABLE IF NOT EXISTS orders_2027q2
    PARTITION OF orders
    FOR VALUES FROM ('2027-04-01') TO ('2027-07-01');

-- Wallet Transactions: Q3 2026
CREATE TABLE IF NOT EXISTS wallet_transactions_2026q3
    PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');

-- Wallet Transactions: Q4 2026
CREATE TABLE IF NOT EXISTS wallet_transactions_2026q4
    PARTITION OF wallet_transactions
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');

-- Wallet Transactions: Q1 2027 — preemptive
CREATE TABLE IF NOT EXISTS wallet_transactions_2027q1
    PARTITION OF wallet_transactions
    FOR VALUES FROM ('2027-01-01') TO ('2027-04-01');

-- Wallet Transactions: Q2 2027 — preemptive
CREATE TABLE IF NOT EXISTS wallet_transactions_2027q2
    PARTITION OF wallet_transactions
    FOR VALUES FROM ('2027-04-01') TO ('2027-07-01');
