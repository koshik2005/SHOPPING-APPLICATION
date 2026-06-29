package com.hyperlocal.delivery.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class DeliveryStatusDto {
    private UUID orderId;
    private UUID partnerId;
    private String status;
    private String etaMinutes;
}
