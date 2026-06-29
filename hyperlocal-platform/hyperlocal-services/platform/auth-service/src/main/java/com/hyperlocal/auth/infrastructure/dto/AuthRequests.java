package com.hyperlocal.auth.infrastructure.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

public class AuthRequests {

    @Data
    public static class RegisterRequest {
        @NotBlank
        private String name;

        @NotBlank
        @Email
        private String email;

        @NotBlank
        private String mobileNumber;

        @NotBlank
        private String countryCode;

        @NotBlank
        private String language;

        @NotNull
        private Boolean acceptTerms;
    }

    @Data
    public static class SendOtpRequest {
        @NotBlank
        private String emailOrPhone;

        @NotBlank
        private String type; // MOBILE, EMAIL
    }

    @Data
    public static class VerifyOtpRequest {
        @NotBlank
        private String emailOrPhone;

        @NotBlank
        private String otpCode;
    }

    @Data
    public static class VerifyPasswordRequest {
        @NotBlank
        @Email
        private String email;

        @NotBlank
        private String password;
    }

    @Data
    public static class RefreshTokenRequest {
        @NotBlank
        private String refreshToken;
    }

    @Data
    public static class ForgotPasswordRequest {
        @NotBlank
        @Email
        private String email;
    }

    @Data
    public static class ResetPasswordRequest {
        @NotBlank
        @Email
        private String email;

        @NotBlank
        private String otpCode;

        @NotBlank
        private String newPassword;
    }
}
