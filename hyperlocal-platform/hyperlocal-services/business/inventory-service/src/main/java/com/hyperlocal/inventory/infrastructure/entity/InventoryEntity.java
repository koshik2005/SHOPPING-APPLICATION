package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "inventory")
public class InventoryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "product_variant_id", nullable = false, unique = true)
    private UUID productVariantId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "available_qty", nullable = false)
    private int availableQty = 0;

    @Column(name = "safety_stock_qty", nullable = false)
    private int safetyStockQty = 10;
}
