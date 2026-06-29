package com.hyperlocal.payment.infrastructure.dto;

import lombok.Data;

@Data
public class WebhookRequestDto {
    private String eventType;
    private String gatewayRef;
    private String status;
    private double amount;
}
