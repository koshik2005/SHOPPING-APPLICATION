package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Runtime feature flag — every major platform feature is togglable
 * at GLOBAL, BRANCH, USER, or ROLE scope without code deployment.
 */
@Getter
@Setter
@Entity
@Table(
    name = "feature_flags",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_flag_key_scope",
        columnNames = {"flag_key", "scope", "scope_id"}
    )
)
public class FeatureFlagEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "flag_key", nullable = false, length = 100)
    private String flagKey;

    @Column(name = "is_enabled", nullable = false)
    private boolean enabled = false;

    /** GLOBAL | BRANCH | USER | ROLE */
    @Column(nullable = false, length = 20)
    private String scope = "GLOBAL";

    /** The branch/user/role UUID this flag applies to (null = whole scope) */
    @Column(name = "scope_id")
    private UUID scopeId;

    @Column
    private String description;

    /** Arbitrary extension JSON (rollout percentage, A/B group, etc.) */
    @Column(columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
