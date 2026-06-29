-- Partitioned Audit Trails and Triggers
CREATE TABLE audit_logs (
    id UUID NOT NULL,
    correlation_id UUID NOT NULL,
    user_id UUID,
    user_role VARCHAR(50),
    device VARCHAR(100),
    ip_address VARCHAR(45),
    module VARCHAR(50) NOT NULL,
    action VARCHAR(100) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE audit_logs_y2026 PARTITION OF audit_logs FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');
