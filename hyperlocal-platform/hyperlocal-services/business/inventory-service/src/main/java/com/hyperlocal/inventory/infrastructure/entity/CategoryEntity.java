package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Enhanced CategoryEntity — now includes service_key for dynamic category
 * assignment per service type, display ordering, theming, and nesting support.
 *
 * No category names or service types are hardcoded anywhere.
 * Admin adds categories via the Enterprise Portal → Inventory → Categories.
 */
@Getter
@Setter
@Entity
@Table(name = "categories")
public class CategoryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(nullable = false, length = 100)
    private String name;

    /** Icon identifier: Material icon name, emoji, or remote URL */
    @Column(name = "icon_url")
    private String iconUrl;

    /**
     * Which service this category belongs to (e.g., "food", "grocery", "medicine").
     * Null = applicable across all services.
     */
    @Column(name = "service_key", length = 80)
    private String serviceKey;

    /** For nested categories (sub-categories) */
    @Column(name = "parent_category_id")
    private UUID parentCategoryId;

    /** Rendering order within the service's category list */
    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    /** Primary color hex for theming (e.g., "#FF6D00") */
    @Column(name = "color_hex", length = 10)
    private String colorHex;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /** JSON extensibility slot for future metadata */
    @Column(columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(nullable = false)
    private boolean deleted = false;
}
