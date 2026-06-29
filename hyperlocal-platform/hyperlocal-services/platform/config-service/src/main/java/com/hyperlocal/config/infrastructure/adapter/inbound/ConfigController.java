package com.hyperlocal.config.infrastructure.adapter.inbound;

import com.hyperlocal.config.application.service.ConfigService;
import com.hyperlocal.core.domain.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/config")
@RequiredArgsConstructor
public class ConfigController {
    private final ConfigService configService;

    @GetMapping("/resolve")
    public ResponseEntity<ApiResponse<String>> resolveConfig(
            @RequestParam("key") String key, 
            @RequestParam(value = "fallback", defaultValue = "") String fallback) {
        String val = configService.resolveValue(key, fallback);
        return ResponseEntity.ok(ApiResponse.ok(val, UUID.randomUUID().toString()));
    }
}
