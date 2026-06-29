package com.hyperlocal.wallet.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class WalletDto {
    private UUID id;
    private UUID customerId;
    private double balance;
}
