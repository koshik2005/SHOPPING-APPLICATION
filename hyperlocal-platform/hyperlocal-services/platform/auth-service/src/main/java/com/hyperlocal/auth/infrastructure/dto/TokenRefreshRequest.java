package com.hyperlocal.auth.infrastructure.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class TokenRefreshRequest {
    @NotBlank(message = "Refresh token is required")
    private String refreshToken;
    
    @NotBlank(message = "Device identifier is required")
    private String deviceId;
}
