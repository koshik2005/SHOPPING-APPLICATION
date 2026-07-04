package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Configurable pricing rule — replaces ALL hardcoded fee/tax/commission
 * values across the platform.
 *
 * value_type = FLAT    → value is the absolute amount
 * value_type = PERCENT → value is a percentage (e.g., 8.00 = 8%)
 * value_type = FORMULA → custom formula string (evaluated by PricingRuleService)
 */
@Getter
@Setter
@Entity
@Table(name = "pricing_rules")
public class PricingRuleEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** Logical rule identifier (e.g., "base_delivery_fee", "tax_rate") */
    @Column(name = "rule_key", nullable = false, length = 100)
    private String ruleKey;

    /** Scope to a service (food, rides, courier) — null means all services */
    @Column(name = "service_key", length = 80)
    private String serviceKey;

    /** Scope to a branch — null means all branches (global default) */
    @Column(name = "branch_id")
    private UUID branchId;

    @Column(nullable = false, precision = 14, scale = 4)
    private java.math.BigDecimal value;

    /** FLAT | PERCENT | FORMULA */
    @Column(name = "value_type", nullable = false, length = 20)
    private String valueType = "FLAT";

    /** Optional formula expression for FORMULA type */
    @Column
    private String formula;

    /** JSON conditions: minimum order value, time-of-day, etc. */
    @Column(columnDefinition = "jsonb")
    private String conditions = "{}";

    /** Higher priority wins when multiple rules match */
    @Column(nullable = false)
    private int priority = 0;

    @Column(name = "effective_from")
    private Instant effectiveFrom;

    @Column(name = "effective_to")
    private Instant effectiveTo;

    @Column
    private String description;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
