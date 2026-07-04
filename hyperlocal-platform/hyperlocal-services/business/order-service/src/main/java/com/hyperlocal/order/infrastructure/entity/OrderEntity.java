package com.hyperlocal.order.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * OrderEntity — Zero Hardcoding Refactor
 *
 * REMOVED: status = "DRAFT" hardcoded default
 * ADDED:   service_key — routes the order to the correct workflow definition
 *
 * Initial status is now resolved dynamically from the workflow engine:
 *   GET /api/v1/config/workflow?serviceKey=food → first step with is_initial=TRUE
 */
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

    /**
     * Service domain: "food", "grocery", "rides", "courier", etc.
     * Determines which workflow_step_definitions apply to this order.
     */
    @Column(name = "service_key", length = 80)
    private String serviceKey;

    /**
     * Current workflow step key — resolved from workflow_step_definitions.
     * Never hardcoded; always comes from WorkflowService.resolveInitialStepKey().
     */
    @Column(nullable = true)
    private String status;

    @Column(name = "total_price", nullable = false)
    private double totalPrice;

    @Column(name = "delivery_fee", nullable = false)
    private double deliveryFee = 0.00;

    @Column(name = "tax_amount", nullable = false)
    private double taxAmount = 0.00;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
