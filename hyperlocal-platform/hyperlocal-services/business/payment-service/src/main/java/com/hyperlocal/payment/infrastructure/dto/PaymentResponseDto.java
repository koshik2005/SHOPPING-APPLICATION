package com.hyperlocal.payment.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class PaymentResponseDto {
    private UUID paymentId;
    private String status;
    private String gatewayRef;
    private String checkoutUrl;
}
