package com.hyperlocal.cart.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "cart_items")
public class CartItemEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "cart_id", nullable = false)
    private UUID cartId;

    @Column(name = "product_variant_id", nullable = false)
    private UUID productVariantId;

    @Column(nullable = false)
    private int quantity = 1;
}
