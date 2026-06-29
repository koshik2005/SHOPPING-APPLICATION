package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "product_variants")
public class ProductVariantEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(nullable = false, unique = true)
    private String sku;

    @Column(nullable = false)
    private double price;

    @Column(nullable = false)
    private boolean deleted = false;
}
