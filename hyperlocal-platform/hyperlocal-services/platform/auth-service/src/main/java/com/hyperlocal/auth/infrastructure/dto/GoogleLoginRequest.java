package com.hyperlocal.auth.infrastructure.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GoogleLoginRequest {
    @NotBlank(message = "Google ID Token is required")
    private String idToken;
    
    @NotNull(message = "Device details must be provided")
    private DeviceDetails device;

    @Data
    public static class DeviceDetails {
        private String deviceId;
        private String deviceName;
        private String platform;
        private String osVersion;
        private String appVersion;
        private String fcmToken;
    }
}
