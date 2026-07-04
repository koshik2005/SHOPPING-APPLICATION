package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Workflow step definitions — replaces ALL hardcoded order status strings
 * (e.g., "PENDING", "ACCEPTED", "DELIVERED") across the platform.
 *
 * Each (service_key, step_key) pair is unique.
 * allowedNextSteps and allowedRoles are JSON arrays.
 */
@Getter
@Setter
@Entity
@Table(
    name = "workflow_step_definitions",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_workflow_service_step",
        columnNames = {"service_key", "step_key"}
    )
)
public class WorkflowStepEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** The service this workflow belongs to: "food", "rides", "courier" */
    @Column(name = "service_key", nullable = false, length = 80)
    private String serviceKey;

    /** Machine-readable step identifier, e.g., "PENDING", "IN_TRANSIT" */
    @Column(name = "step_key", nullable = false, length = 80)
    private String stepKey;

    /** Human-readable label for display, e.g., "Order Placed" */
    @Column(name = "display_label", nullable = false, length = 150)
    private String displayLabel;

    @Column(columnDefinition = "TEXT")
    private String description;

    /** True for the starting step of this workflow */
    @Column(name = "is_initial", nullable = false)
    private boolean initial = false;

    /** True for steps that cannot transition further */
    @Column(name = "is_terminal", nullable = false)
    private boolean terminal = false;

    /** JSON array of step_key strings that are valid transitions from here */
    @Column(name = "allowed_next_steps", nullable = false, columnDefinition = "jsonb")
    private String allowedNextSteps = "[]";

    /** JSON array of role names that can trigger a transition TO this step */
    @Column(name = "allowed_roles", nullable = false, columnDefinition = "jsonb")
    private String allowedRoles = "[]";

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "icon_key", length = 100)
    private String iconKey;

    @Column(name = "color_hex", length = 10)
    private String colorHex;

    /** JSON extensibility blob */
    @Column(columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
