package com.hyperlocal.payment.infrastructure.adapter.inbound;

import com.hyperlocal.payment.application.service.PaymentService;
import com.hyperlocal.payment.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class PaymentController {
    private final PaymentService paymentService;

    @PostMapping("/charge")
    public ResponseEntity<ApiResponse<PaymentResponseDto>> charge(@Valid @RequestBody PaymentRequestDto request) {
        PaymentResponseDto response = paymentService.processPayment(request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping("/webhook")
    public ResponseEntity<ApiResponse<String>> webhook(
            @RequestHeader(value = "X-Webhook-Signature", required = false) String signature,
            @RequestBody WebhookRequestDto request) {
        paymentService.processWebhook(request);
        return ResponseEntity.ok(ApiResponse.ok("Webhook processed successfully", UUID.randomUUID().toString()));
    }
}
