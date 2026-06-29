package com.hyperlocal.search.infrastructure.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.util.UUID;

/**
 * Read-only projection of the shared `products` table.
 * Managed by inventory-service migrations — search-service only reads.
 */
@Getter
@Setter
@Entity
@Table(name = "products")
public class ProductSearchProjection {

    @Id
    private UUID id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "status")
    private String status;

    @Column(name = "deleted", nullable = false)
    private boolean deleted;
}
