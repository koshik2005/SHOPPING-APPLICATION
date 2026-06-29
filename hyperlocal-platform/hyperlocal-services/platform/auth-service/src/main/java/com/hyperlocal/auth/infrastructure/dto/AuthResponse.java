package com.hyperlocal.auth.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class AuthResponse {
    private String authenticationState; // REGISTRATION_REQUIRED, GOOGLE_VERIFIED, PASSWORD_REQUIRED, PHONE_VERIFICATION_REQUIRED, EMAIL_VERIFICATION_REQUIRED, LOGIN_COMPLETED, ACCOUNT_DISABLED, ACCOUNT_BLOCKED
    private String accessToken;
    private String refreshToken;
    private long expiresIn;
    private UserDetails user;
    private GoogleProfileDetails googleProfile;
    private ExistingProfileDetails existingProfile;

    @Data
    @Builder
    public static class UserDetails {
        private String id;
        private String email;
        private String role;
        private ProfileDetails profile;
    }

    @Data
    @Builder
    public static class ProfileDetails {
        private String displayName;
        private String profilePhotoUrl;
    }

    @Data
    @Builder
    public static class GoogleProfileDetails {
        private String displayName;
        private String email;
        private String profilePhotoUrl;
    }

    @Data
    @Builder
    public static class ExistingProfileDetails {
        private String displayName;
        private String email;
        private String maskedMobileNumber;
        private List<String> availableVerificationMethods;
    }
}
