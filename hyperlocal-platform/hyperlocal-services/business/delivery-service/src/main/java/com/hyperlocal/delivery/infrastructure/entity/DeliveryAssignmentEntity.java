package com.hyperlocal.delivery.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "delivery_assignments")
public class DeliveryAssignmentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "partner_id", nullable = false)
    private UUID partnerId;

    @Column(name = "status", nullable = false)
    private String status = "ASSIGNED"; // e.g. ASSIGNED, ACCEPTED, PICKED_UP, DELIVERED

    @Column(name = "verification_otp")
    private String verificationOtp;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
