package com.hyperlocal.wallet.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class WalletTransactionDto {
    private UUID id;
    private double amount;
    private String type;
    private UUID referenceId;
    private Instant createdAt;
}
