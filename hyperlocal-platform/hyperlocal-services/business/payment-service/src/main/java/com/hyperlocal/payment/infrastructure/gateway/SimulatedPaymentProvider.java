package com.hyperlocal.payment.infrastructure.gateway;

import com.hyperlocal.payment.infrastructure.dto.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Simulated Payment Gateway — Development Provider.
 *
 * Mirrors the exact production payment flow (initiation → webhook → settlement)
 * with configurable outcomes. All state machines and workflows are identical to production.
 *
 * Supported outcomes (controlled via PaymentRequestDto.simulatedOutcome):
 *   SUCCESS   → Payment completes immediately
 *   FAILURE   → Payment declines at gateway
 *   PENDING   → Payment remains in waiting state (simulates bank redirect)
 *   CANCELLED → Payment cancelled by user before completion
 *   TIMEOUT   → Gateway does not respond within window
 *   REFUND    → Payment completes then is immediately refunded
 *
 * Switch to Razorpay/Stripe/PhonePe via application.properties (payment.gateway=razorpay)
 * without modifying any business logic.
 */
@Component("SIMULATED")
@Profile({"dev", "test"})
public class SimulatedPaymentProvider implements PaymentGatewayProvider {

    private static final Logger log = LoggerFactory.getLogger(SimulatedPaymentProvider.class);

    // In-memory ledger for webhook simulation lookups
    private final Map<String, String> pendingOutcomes = new ConcurrentHashMap<>();

    @Override
    public PaymentResponseDto initiatePayment(PaymentRequestDto request) {
        String ref = "sim_" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        String outcome = "SUCCESS";
        try {
            java.lang.reflect.Field field = request.getClass().getDeclaredField("simulatedOutcome");
            field.setAccessible(true);
            Object value = field.get(request);
            if (value != null) {
                outcome = value.toString().toUpperCase();
            }
        } catch (Exception e) {
            log.warn("[SIMULATED GATEWAY] Bypassed simulatedOutcome field check: {}", e.getMessage());
        }

        pendingOutcomes.put(ref, outcome);


        log.info("[SIMULATED GATEWAY] Initiated payment. ref={} orderId={} amount={} outcome={}",
                ref, request.getOrderId(), request.getAmount(), outcome);

        String status = switch (outcome) {
            case "FAILURE"   -> "FAILED";
            case "TIMEOUT"   -> "TIMEOUT";
            case "CANCELLED" -> "CANCELLED";
            default          -> "IN_PROGRESS"; // SUCCESS, PENDING, REFUND
        };

        String checkoutUrl = "http://localhost:8080/api/v1/payments/simulated/checkout?ref=" + ref
                + "&outcome=" + outcome;

        return PaymentResponseDto.builder()
                .status(status)
                .gatewayRef(ref)
                .checkoutUrl(checkoutUrl)
                .build();
    }

    @Override
    public boolean verifyWebhookSignature(String payload, String signature) {
        // Simulated provider accepts all webhooks in dev mode
        log.debug("[SIMULATED GATEWAY] Webhook signature check bypassed for dev");
        return true;
    }

    /**
     * Returns the simulated outcome for a given reference.
     * Used by the SimulatedCheckoutController to drive the webhook back.
     */
    public String getOutcomeForRef(String ref) {
        return pendingOutcomes.getOrDefault(ref, "SUCCESS");
    }
}
