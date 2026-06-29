package com.hyperlocal.cart.infrastructure.adapter.inbound;

import com.hyperlocal.cart.application.service.CartService;
import com.hyperlocal.cart.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
public class CartController {
    private final CartService cartService;

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<CartSummaryDto>> getSummary(@RequestHeader("X-User-ID") String userId) {
        CartSummaryDto response = cartService.getCartSummary(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping("/add")
    public ResponseEntity<ApiResponse<String>> addItem(
            @RequestHeader("X-User-ID") String userId,
            @RequestParam("variantId") String variantId,
            @RequestParam(value = "quantity", defaultValue = "1") int qty) {
        cartService.addItemToCart(UUID.fromString(userId), UUID.fromString(variantId), qty);
        return ResponseEntity.ok(ApiResponse.ok("Item added to cart", UUID.randomUUID().toString()));
    }

    @DeleteMapping("/clear")
    public ResponseEntity<ApiResponse<String>> clearCart(@RequestHeader("X-User-ID") String userId) {
        cartService.clearCart(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Cart cleared", UUID.randomUUID().toString()));
    }
}
