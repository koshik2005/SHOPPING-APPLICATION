package com.hyperlocal.payment.infrastructure.gateway;

import com.hyperlocal.payment.infrastructure.dto.*;

public interface PaymentGatewayProvider {
    PaymentResponseDto initiatePayment(PaymentRequestDto request);
    boolean verifyWebhookSignature(String payload, String signature);
}
