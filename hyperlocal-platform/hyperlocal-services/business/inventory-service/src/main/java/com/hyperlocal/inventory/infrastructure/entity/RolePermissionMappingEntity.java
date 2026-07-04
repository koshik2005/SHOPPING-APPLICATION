package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "role_permission_mappings")
public class RolePermissionMappingEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "role_name", nullable = false, length = 100)
    private String roleName;

    @Column(name = "permission_key", nullable = false, length = 150)
    private String permissionKey;
}
