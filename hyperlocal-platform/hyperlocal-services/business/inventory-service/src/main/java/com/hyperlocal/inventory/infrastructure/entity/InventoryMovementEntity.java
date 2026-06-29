package com.hyperlocal.inventory.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "inventory_movements")
public class InventoryMovementEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "inventory_id", nullable = false)
    private UUID inventoryId;

    @Column(name = "qty_change", nullable = false)
    private int qtyChange;

    @Column(nullable = false)
    private String type; // e.g. SALE, PURCHASE, DAMAGE

    @Column(name = "reference_id")
    private UUID referenceId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
