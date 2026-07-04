package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Master catalog of all system permissions.
 * Any new permission is added here first, then mapped to roles.
 * Replaces hardcoded permission strings scattered across the codebase.
 */
@Getter
@Setter
@Entity
@Table(name = "permission_definitions")
public class PermissionDefinitionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "permission_key", nullable = false, unique = true, length = 150)
    private String permissionKey;

    @Column(name = "display_label", nullable = false, length = 200)
    private String displayLabel;

    @Column(nullable = false, length = 100)
    private String category;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_sensitive", nullable = false)
    private boolean sensitive = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
