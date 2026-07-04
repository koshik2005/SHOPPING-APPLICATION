package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Navigation menu items for all portal targets (ENTERPRISE, DELIVERY, etc.).
 * Replaces the hardcoded SIDEBAR_ITEMS array in Layout.tsx.
 */
@Getter
@Setter
@Entity
@Table(name = "navigation_menus")
public class NavigationMenuEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "menu_key", nullable = false, unique = true, length = 100)
    private String menuKey;

    /** Which portal this menu belongs to: ENTERPRISE, DELIVERY, etc. */
    @Column(name = "portal_target", nullable = false, length = 50)
    private String portalTarget = "ENTERPRISE";

    @Column(name = "display_label", nullable = false, length = 150)
    private String displayLabel;

    /** MUI icon name or icon identifier string */
    @Column(name = "icon_key", length = 100)
    private String iconKey;

    @Column(name = "route_path", length = 255)
    private String routePath;

    /** Permission key required to see this menu item */
    @Column(name = "permission_key", length = 150)
    private String permissionKey;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /** Parent menu item (for nested/group navigation) */
    @Column(name = "parent_id")
    private UUID parentId;

    /** Visual section label shown above the group in sidebar */
    @Column(name = "section_label", length = 100)
    private String sectionLabel;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
