package com.hyperlocal.payment.infrastructure.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.util.UUID;

@Getter
@Setter
public class PaymentRequestDto {
    @NotNull(message = "Order ID is required")
    private UUID orderId;

    @NotBlank(message = "Payment method is required")
    private String method;

    @NotNull(message = "Amount is required")
    private Double amount;

    @NotBlank(message = "Gateway name is required")
    private String gatewayName;

    /**
     * DEV/TEST ONLY: Controls simulated payment outcome.
     * Values: SUCCESS | FAILURE | PENDING | CANCELLED | TIMEOUT | REFUND
     * Ignored by production gateway providers.
     */
    private String simulatedOutcome;

    public String getSimulatedOutcome() {
        return this.simulatedOutcome;
    }

    public void setSimulatedOutcome(String simulatedOutcome) {
        this.simulatedOutcome = simulatedOutcome;
    }
}

