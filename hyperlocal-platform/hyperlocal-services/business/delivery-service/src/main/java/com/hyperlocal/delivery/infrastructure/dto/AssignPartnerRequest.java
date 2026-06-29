package com.hyperlocal.delivery.infrastructure.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

@Data
public class AssignPartnerRequest {
    @NotNull(message = "Order ID is required")
    private UUID orderId;

    @NotNull(message = "Partner ID is required")
    private UUID partnerId;
}
