package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Dynamic home-screen banners for Flutter Customer App.
 * Replaces the hardcoded _banners list in home_screen.dart.
 */
@Getter
@Setter
@Entity
@Table(name = "banners")
public class BannerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** Branch scope — null means applies to all branches */
    @Column(name = "branch_id")
    private UUID branchId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String subtitle;

    /** Deep-link route when user taps the banner */
    @Column(name = "action_route", length = 255)
    private String actionRoute;

    /** JSON array of hex gradient colours: ["#FF6D00","#E65100"] */
    @Column(name = "background_colors", nullable = false, columnDefinition = "jsonb")
    private String backgroundColors = "[]";

    /** Material icon name or emoji */
    @Column(name = "icon_key", length = 100)
    private String iconKey;

    /** Optional remote image URL overriding the icon */
    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /** Banner shown only from this timestamp (inclusive) */
    @Column(name = "valid_from")
    private Instant validFrom;

    /** Banner expires at this timestamp */
    @Column(name = "valid_to")
    private Instant validTo;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
