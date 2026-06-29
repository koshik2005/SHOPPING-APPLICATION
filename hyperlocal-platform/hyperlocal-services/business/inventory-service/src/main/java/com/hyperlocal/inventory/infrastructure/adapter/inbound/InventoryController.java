package com.hyperlocal.inventory.infrastructure.adapter.inbound;

import com.hyperlocal.inventory.application.service.InventoryService;
import com.hyperlocal.inventory.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
public class InventoryController {
    private final InventoryService inventoryService;

    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<CategoryDto>>> getCategories() {
        List<CategoryDto> response = inventoryService.getCategories();
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @GetMapping("/products/shop/{shopId}")
    public ResponseEntity<ApiResponse<List<ProductDto>>> getProductsByShop(@PathVariable("shopId") String shopId) {
        List<ProductDto> response = inventoryService.getProductsByShop(UUID.fromString(shopId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @GetMapping("/stock/{variantId}")
    public ResponseEntity<ApiResponse<Integer>> getStock(@PathVariable("variantId") String variantId) {
        int stock = inventoryService.getAvailableStock(UUID.fromString(variantId));
        return ResponseEntity.ok(ApiResponse.ok(stock, UUID.randomUUID().toString()));
    }
}
