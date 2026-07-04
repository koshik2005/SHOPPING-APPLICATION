package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Enhanced ProductEntity — now includes service_key enabling one unified
 * product entity to serve ALL service types (food, grocery, medicine, marketplace).
 *
 * Dynamic per-product attributes are stored in ProductAttributeValueEntity.
 * No separate FoodProduct, MedicineProduct, etc. entities are ever needed.
 */
@Getter
@Setter
@Entity
@Table(name = "products")
public class ProductEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "shop_id", nullable = false)
    private UUID shopId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    /**
     * Service domain this product belongs to.
     * Determines which attribute schema (ProductAttributeSchemaEntity) applies.
     * E.g., "food" → shows cuisine_type, is_vegetarian, spice_level attributes.
     */
    @Column(name = "service_key", length = 80)
    private String serviceKey;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    /** Soft status driven by workflow engine ("ACTIVE", "INACTIVE", "OUT_OF_STOCK") */
    @Column(nullable = false, length = 50)
    private String status = "ACTIVE";

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /** JSON extensibility slot */
    @Column(columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at")
    private Instant updatedAt = Instant.now();

    @Column(nullable = false)
    private boolean deleted = false;
}
