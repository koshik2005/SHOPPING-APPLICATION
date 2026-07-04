package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Internationalisation string entity.
 * Key-locale pair maps to a translated display value.
 * Replaces all hardcoded UI strings across Flutter and Portal.
 */
@Getter
@Setter
@Entity
@Table(
    name = "localisation_strings",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_i18n_key_locale",
        columnNames = {"string_key", "locale"}
    )
)
public class LocalisationEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** Hierarchical dot-notation key (e.g., "home.search.placeholder") */
    @Column(name = "string_key", nullable = false, length = 250)
    private String stringKey;

    /** BCP-47 locale code (e.g., "en", "hi", "ta", "fr") */
    @Column(nullable = false, length = 10)
    private String locale = "en";

    /** The translated string value */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String value;

    /** Contextual description for translators */
    @Column
    private String description;

    @Column(name = "last_updated", nullable = false)
    private Instant lastUpdated = Instant.now();

    @Column(name = "updated_by")
    private UUID updatedBy;
}
