package com.hyperlocal.order.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "orders")
public class OrderEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(nullable = false)
    private String status = "DRAFT";

    @Column(name = "total_price", nullable = false)
    private double totalPrice;

    @Column(name = "delivery_fee", nullable = false)
    private double deliveryFee = 0.00;

    @Column(name = "tax_amount", nullable = false)
    private double taxAmount = 0.00;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
