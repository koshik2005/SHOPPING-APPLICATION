package com.hyperlocal.order.infrastructure.adapter.inbound;

import com.hyperlocal.order.application.service.OrderService;
import com.hyperlocal.order.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {
    private final OrderService orderService;

    @PostMapping("/create")
    public ResponseEntity<ApiResponse<OrderDto>> createOrder(
            @RequestHeader("X-User-ID") String userId,
            @Valid @RequestBody CreateOrderRequest request) {
        OrderDto response = orderService.createOrder(UUID.fromString(userId), request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PatchMapping("/{orderId}/status")
    public ResponseEntity<ApiResponse<String>> updateStatus(
            @PathVariable("orderId") String orderId,
            @RequestHeader("X-User-ID") String actorId,
            @RequestParam("status") String status,
            @RequestParam(value = "remarks", defaultValue = "") String remarks) {
        orderService.updateOrderStatus(UUID.fromString(orderId), status, UUID.fromString(actorId), remarks);
        return ResponseEntity.ok(ApiResponse.ok("Order status updated successfully", UUID.randomUUID().toString()));
    }

    @GetMapping("/{orderId}/timeline")
    public ResponseEntity<ApiResponse<OrderTimelineDto>> getTimeline(@PathVariable("orderId") String orderId) {
        OrderTimelineDto response = orderService.getTimeline(UUID.fromString(orderId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}
