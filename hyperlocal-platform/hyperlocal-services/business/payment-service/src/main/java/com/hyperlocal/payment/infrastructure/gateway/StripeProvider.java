package com.hyperlocal.payment.infrastructure.gateway;

import com.hyperlocal.payment.infrastructure.dto.*;
import org.springframework.stereotype.Component;
import java.util.UUID;

@Component("STRIPE")
public class StripeProvider implements PaymentGatewayProvider {

    @Override
    public PaymentResponseDto initiatePayment(PaymentRequestDto request) {
        String ref = "st_ref_" + UUID.randomUUID().toString().substring(0, 8);
        return PaymentResponseDto.builder()
            .status("IN_PROGRESS")
            .gatewayRef(ref)
            .checkoutUrl("https://checkout.stripe.com/pay/" + ref)
            .build();
    }

    @Override
    public boolean verifyWebhookSignature(String payload, String signature) {
        return signature != null && !signature.trim().isEmpty();
    }
}
