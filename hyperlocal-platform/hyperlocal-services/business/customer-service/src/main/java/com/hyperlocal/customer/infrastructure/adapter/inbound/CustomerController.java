package com.hyperlocal.customer.infrastructure.adapter.inbound;

import com.hyperlocal.customer.application.service.CustomerService;
import com.hyperlocal.customer.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
public class CustomerController {
    private final CustomerService customerService;

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<CustomerProfileDto>> getProfile(@RequestHeader("X-User-ID") String userId) {
        CustomerProfileDto profile = customerService.getProfileByUserId(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(profile, UUID.randomUUID().toString()));
    }

    @GetMapping("/bootstrap")
    public ResponseEntity<ApiResponse<HomeBootstrapResponse>> bootstrapHome(@RequestHeader("X-User-ID") String userId) {
        HomeBootstrapResponse response = customerService.bootstrapHomeScreen(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}
