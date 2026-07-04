package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "users")
public class UserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String status = "ACTIVE";

    @Column(name = "mfa_enabled", nullable = false)
    private boolean mfaEnabled = false;

    /**
     * RBAC: roles assigned to this user.
     * Backed by the user_roles junction table (V2 Flyway migration).
     * Default: ROLE_CUSTOMER for all newly registered customers.
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "user_roles",
        joinColumns = @JoinColumn(name = "user_id")
    )
    @Column(name = "role")
    private Set<String> roles = new HashSet<>(Set.of("ROLE_CUSTOMER"));

    /**
     * Tenant scoping: branch context for BRANCH_MANAGER / REGIONAL_MANAGER.
     * Null for customers and delivery partners.
     */
    @Column(name = "branch_id")
    private UUID branchId;

    /**
     * Tenant scoping: shop context for SHOP_OWNER / SHOP_MANAGER.
     * Null for all other roles.
     */
    @Column(name = "shop_id")
    private UUID shopId;

    @Version
    private Integer version = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at")
    private Instant updatedAt = Instant.now();

    /** Soft delete flag — records are never physically deleted */
    @Column(nullable = false)
    private boolean deleted = false;

    /** Soft delete timestamp — set when deleted = true */
    @Column(name = "deleted_at")
    private Instant deletedAt;

    /** User ID who performed the deletion */
    @Column(name = "deleted_by")
    private UUID deletedBy;
}
