package com.hyperlocal.delivery.infrastructure.adapter.inbound;

import com.hyperlocal.delivery.application.service.DeliveryService;
import com.hyperlocal.delivery.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/deliveries")
@RequiredArgsConstructor
public class DeliveryController {
    private final DeliveryService deliveryService;

    @PostMapping("/assign")
    public ResponseEntity<ApiResponse<String>> assign(@Valid @RequestBody AssignPartnerRequest request) {
        deliveryService.assignDeliveryPartner(request);
        return ResponseEntity.ok(ApiResponse.ok("Delivery partner assigned successfully", UUID.randomUUID().toString()));
    }

    @PostMapping("/partner/{partnerId}/location")
    public ResponseEntity<ApiResponse<String>> postLocation(
            @PathVariable("partnerId") String partnerId,
            @RequestBody PartnerLocationDto loc) {
        deliveryService.updatePartnerLocation(UUID.fromString(partnerId), loc);
        return ResponseEntity.ok(ApiResponse.ok("Location updated", UUID.randomUUID().toString()));
    }

    @GetMapping("/order/{orderId}/status")
    public ResponseEntity<ApiResponse<DeliveryStatusDto>> getStatus(@PathVariable("orderId") String orderId) {
        DeliveryStatusDto response = deliveryService.getDeliveryStatus(UUID.fromString(orderId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}
