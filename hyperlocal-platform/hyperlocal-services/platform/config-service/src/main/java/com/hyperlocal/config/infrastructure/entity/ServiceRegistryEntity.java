package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Dynamic Service Registry — replaces ALL hardcoded service lists
 * in Flutter home screen and Enterprise Portal.
 *
 * Adding "Hotel Booking" to this table is the ONLY change needed
 * for it to appear in every client app.
 */
@Getter
@Setter
@Entity
@Table(name = "platform_services")
public class ServiceRegistryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** Unique machine-readable key (e.g., "food", "rides", "hotel_booking") */
    @Column(name = "service_key", nullable = false, unique = true, length = 80)
    private String serviceKey;

    /** Human-readable display name (e.g., "Restaurant", "Ride Booking") */
    @Column(name = "display_name", nullable = false, length = 150)
    private String displayName;

    /** Icon identifier: Material icon name, emoji, or remote URL */
    @Column(name = "icon_url")
    private String iconUrl;

    /** Primary color hex code for theming (e.g., "#FF6D00") */
    @Column(name = "color_hex", length = 10)
    private String colorHex;

    /** App deep-link route (e.g., "/shop/food", "/rides") */
    @Column(name = "route_path", length = 255)
    private String routePath;

    /** Global on/off switch for this service */
    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /** Rendering order in the Flutter home grid */
    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    /** Linked feature flag key for branch-level overrides */
    @Column(name = "feature_flag_key", length = 100)
    private String featureFlagKey;

    /** JSON blob for arbitrary extensible metadata */
    @Column(columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
