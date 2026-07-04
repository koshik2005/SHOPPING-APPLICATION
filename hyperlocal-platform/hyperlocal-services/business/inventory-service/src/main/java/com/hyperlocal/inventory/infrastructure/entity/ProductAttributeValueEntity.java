package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Stores the actual dynamic attribute values for each product.
 * The attribute_key must match a key in ProductAttributeSchemaEntity
 * for the product's service_key.
 *
 * Example: product (service_key="food"):
 *   attribute_key="cuisine_type"  → attribute_value="Indian"
 *   attribute_key="is_vegetarian" → attribute_value="true"
 *   attribute_key="spice_level"   → attribute_value="Hot"
 */
@Getter
@Setter
@Entity
@Table(
    name = "product_attribute_values",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_attr_value_product_key",
        columnNames = {"product_id", "attribute_key"}
    )
)
public class ProductAttributeValueEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(name = "attribute_key", nullable = false, length = 100)
    private String attributeKey;

    /** Always stored as string; clients cast based on schema field_type */
    @Column(name = "attribute_value", columnDefinition = "TEXT")
    private String attributeValue;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
