package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Maps roles to permissions.
 * Replaces the hardcoded ROLE_PERMISSIONS map in AuthContext.tsx.
 *
 * Adding a new role and its permissions here is all that's needed —
 * no code changes required in Portal, Flutter, or any backend service.
 */
@Getter
@Setter
@Entity
@Table(
    name = "role_permission_mappings",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_role_permission",
        columnNames = {"role_name", "permission_key"}
    )
)
public class RolePermissionMappingEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "role_name", nullable = false, length = 100)
    private String roleName;

    @Column(name = "permission_key", nullable = false, length = 150)
    private String permissionKey;

    @Column(name = "granted_at", nullable = false)
    private Instant grantedAt = Instant.now();

    @Column(name = "granted_by")
    private UUID grantedBy;
}
