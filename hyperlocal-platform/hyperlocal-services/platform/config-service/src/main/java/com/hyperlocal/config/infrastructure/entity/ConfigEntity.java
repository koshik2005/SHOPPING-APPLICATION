package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Persists all configurable platform settings with scope, data-type,
 * and audit trail. Replaces the previous flat key-value-only design.
 *
 * scope:    GLOBAL | BRANCH | SHOP | USER | ROLE
 * scopeId:  The UUID of the specific branch / shop / user / role
 *           (null means the scope-root itself, e.g., global settings)
 * dataType: STRING | INTEGER | DECIMAL | BOOLEAN | JSON | URL
 */
@Getter
@Setter
@Entity
@Table(
    name = "system_configuration",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_config_key_scope",
        columnNames = {"config_key", "scope", "scope_id"}
    )
)
public class ConfigEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "config_key", nullable = false)
    private String configKey;

    @Column(name = "config_value", nullable = false)
    private String configValue;

    /** Logical grouping label (GLOBAL is the DB default) */
    @Column(nullable = false)
    private String category = "GLOBAL";

    /** Scope dimension: GLOBAL | BRANCH | SHOP | USER | ROLE */
    @Column(nullable = false, length = 20)
    private String scope = "GLOBAL";

    /** Nullable — null means the setting applies to the whole scope root */
    @Column(name = "scope_id")
    private UUID scopeId;

    /** Declared type for safe deserialization on clients */
    @Column(name = "data_type", nullable = false, length = 20)
    private String dataType = "STRING";

    /** If true, value is masked in Portal API responses */
    @Column(name = "is_sensitive", nullable = false)
    private boolean sensitive = false;

    @Column
    private String description;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
