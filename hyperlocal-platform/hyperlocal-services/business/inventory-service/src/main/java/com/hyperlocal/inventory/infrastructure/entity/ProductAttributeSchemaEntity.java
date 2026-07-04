package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Dynamic Product Attribute Schema — defines what attributes a product
 * of a given service type has.
 *
 * Example: For service_key = "food":
 *   - cuisine_type (DROPDOWN)
 *   - is_vegetarian (BOOLEAN)
 *   - spice_level (DROPDOWN)
 *   - calories (NUMBER)
 *
 * These schemas are configured from the Enterprise Portal's
 * Product Schema Builder page — no code changes needed.
 */
@Getter
@Setter
@Entity
@Table(
    name = "product_attribute_schemas",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_attr_schema_service_key",
        columnNames = {"service_key", "attribute_key"}
    )
)
public class ProductAttributeSchemaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "service_key", nullable = false, length = 80)
    private String serviceKey;

    @Column(name = "attribute_key", nullable = false, length = 100)
    private String attributeKey;

    @Column(name = "display_label", nullable = false, length = 150)
    private String displayLabel;

    /**
     * Field type: TEXT | NUMBER | DECIMAL | BOOLEAN | DROPDOWN |
     *             MULTISELECT | DATE | URL | COLOR | TEXTAREA
     */
    @Column(name = "field_type", nullable = false, length = 30)
    private String fieldType;

    @Column(name = "is_required", nullable = false)
    private boolean required = false;

    @Column(name = "is_searchable", nullable = false)
    private boolean searchable = false;

    @Column(name = "is_filterable", nullable = false)
    private boolean filterable = false;

    /** JSON object with validation rules: {min, max, pattern, etc.} */
    @Column(name = "validation_rules", columnDefinition = "jsonb")
    private String validationRules = "{}";

    /** JSON array of option strings for DROPDOWN/MULTISELECT types */
    @Column(name = "dropdown_options", columnDefinition = "jsonb")
    private String dropdownOptions = "[]";

    @Column(name = "default_value")
    private String defaultValue;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "help_text")
    private String helpText;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
