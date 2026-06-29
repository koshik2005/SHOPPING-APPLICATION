package com.hyperlocal.payment.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "payment_attempts")
public class PaymentAttemptEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "gateway_ref", unique = true)
    private String gatewayRef;

    @Column(name = "gateway_name", nullable = false)
    private String gatewayName;

    @Column(nullable = false)
    private String method;

    @Column(nullable = false)
    private String status = "IN_PROGRESS";

    @Column(nullable = false)
    private double amount;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
