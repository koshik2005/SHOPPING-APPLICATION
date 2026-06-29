package com.hyperlocal.wallet.infrastructure.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

@Data
public class CreditDebitRequest {
    @NotNull(message = "Amount is required")
    private Double amount;

    private UUID referenceId;
}
