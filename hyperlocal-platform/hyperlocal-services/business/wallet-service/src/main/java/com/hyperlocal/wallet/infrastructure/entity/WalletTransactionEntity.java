package com.hyperlocal.wallet.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "wallet_transactions")
public class WalletTransactionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "wallet_id", nullable = false)
    private UUID walletId;

    @Column(nullable = false)
    private double amount;

    @Column(nullable = false)
    private String type; // e.g. CREDIT, DEBIT

    @Column(name = "reference_id")
    private UUID referenceId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
