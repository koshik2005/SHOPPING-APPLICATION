-- Branches and Spatial Geofences
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    tax_rate NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ
);

-- PostGIS Boundary Geofencing
SELECT AddGeometryColumn('branches', 'boundary_geofence', 4326, 'POLYGON', 2);
CREATE INDEX idx_branches_geofence ON branches USING GIST(boundary_geofence);

CREATE TABLE geofences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

SELECT AddGeometryColumn('geofences', 'polygon_boundary', 4326, 'POLYGON', 2);
CREATE INDEX idx_geofences_boundary ON geofences USING GIST(polygon_boundary);
