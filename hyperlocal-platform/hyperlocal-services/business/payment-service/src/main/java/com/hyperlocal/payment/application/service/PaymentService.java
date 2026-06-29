package com.hyperlocal.payment.application.service;

import com.hyperlocal.payment.infrastructure.entity.*;
import com.hyperlocal.payment.infrastructure.repository.*;
import com.hyperlocal.payment.infrastructure.dto.*;
import com.hyperlocal.payment.infrastructure.gateway.PaymentGatewayProvider;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PaymentService {
    private final PaymentRepository paymentRepository;
    private final PaymentAttemptRepository attemptRepository;
    private final ApplicationContext context;

    @Transactional
    public PaymentResponseDto processPayment(PaymentRequestDto request) {
        PaymentGatewayProvider provider = context.getBean(request.getGatewayName().toUpperCase(), PaymentGatewayProvider.class);
        PaymentResponseDto providerResponse = provider.initiatePayment(request);

        PaymentEntity payment = new PaymentEntity();
        payment.setOrderId(request.getOrderId());
        payment.setAmount(request.getAmount());
        payment.setStatus("PENDING");
        payment.setGatewayReference(providerResponse.getGatewayRef());
        PaymentEntity saved = paymentRepository.save(payment);

        PaymentAttemptEntity attempt = new PaymentAttemptEntity();
        attempt.setOrderId(request.getOrderId());
        attempt.setAmount(request.getAmount());
        attempt.setGatewayName(request.getGatewayName());
        attempt.setGatewayRef(providerResponse.getGatewayRef());
        attempt.setMethod(request.getMethod());
        attempt.setStatus("IN_PROGRESS");
        attemptRepository.save(attempt);

        providerResponse.setPaymentId(saved.getId());
        return providerResponse;
    }

    @Transactional
    public void processWebhook(WebhookRequestDto webhook) {
        PaymentAttemptEntity attempt = attemptRepository.findByGatewayRef(webhook.getGatewayRef())
            .orElseThrow(() -> new ResourceNotFoundException("Payment attempt reference not found: " + webhook.getGatewayRef(), "ATTEMPT_NOT_FOUND"));

        attempt.setStatus(webhook.getStatus());
        attemptRepository.save(attempt);

        paymentRepository.findByGatewayReference(webhook.getGatewayRef()).ifPresent(p -> {
            p.setStatus(webhook.getStatus());
            paymentRepository.save(p);
        });
    }
}
