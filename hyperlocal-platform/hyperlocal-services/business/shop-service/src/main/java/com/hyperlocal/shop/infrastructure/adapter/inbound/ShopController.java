package com.hyperlocal.shop.infrastructure.adapter.inbound;

import com.hyperlocal.shop.application.service.ShopService;
import com.hyperlocal.shop.infrastructure.dto.ShopDto;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shops")
@RequiredArgsConstructor
public class ShopController {
    private final ShopService shopService;

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<ShopDto>>> getShopsByBranch(@PathVariable("branchId") String branchId) {
        List<ShopDto> response = shopService.getShopsByBranch(UUID.fromString(branchId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<ShopDto>> registerShop(@RequestBody ShopDto request) {
        ShopDto response = shopService.registerShop(request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}
