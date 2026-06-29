package com.hyperlocal.cart.infrastructure.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.util.UUID;

/**
 * Read-only projection of product_variants table used by cart-service
 * to resolve the current unit price of each cart item.
 * Managed by the inventory-service migrations — cart-service only reads.
 */
@Getter
@Setter
@Entity
@Table(name = "product_variants")
public class ProductVariantPriceProjection {

    @Id
    private UUID id;

    @Column(name = "price", nullable = false)
    private double price;

    @Column(name = "deleted", nullable = false)
    private boolean deleted;
}
