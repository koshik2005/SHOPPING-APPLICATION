package com.hyperlocal.audit.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "audit_logs")
public class AuditLogEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "correlation_id", nullable = false)
    private UUID correlationId;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "user_role")
    private String userRole;

    @Column(nullable = false)
    private String module;

    @Column(nullable = false)
    private String action;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
