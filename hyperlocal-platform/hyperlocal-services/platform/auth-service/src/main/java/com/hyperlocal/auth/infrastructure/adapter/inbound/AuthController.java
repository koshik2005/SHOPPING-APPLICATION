package com.hyperlocal.auth.infrastructure.adapter.inbound;

import com.hyperlocal.auth.application.service.AuthService;
import com.hyperlocal.auth.infrastructure.config.JwtProvider;
import com.hyperlocal.auth.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
import java.util.logging.Logger;
import java.util.logging.Level;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    private static final Logger logger = Logger.getLogger(AuthController.class.getName());
    private final AuthService authService;
    private final JwtProvider jwtProvider;

    @GetMapping("/jwks.json")
    public java.util.Map<String, Object> getJwks() {
        return jwtProvider.getJwks();
    }

    @PostMapping({"/google-login", "/google"})
    public ResponseEntity<ApiResponse<AuthResponse>> googleLogin(@Valid @RequestBody GoogleLoginRequest request) {
        String tokenPrefix = request.getIdToken() != null && request.getIdToken().length() > 20
            ? request.getIdToken().substring(0, 20) + "..."
            : String.valueOf(request.getIdToken());
        logger.log(Level.INFO, "[AUTH BACKEND] Received googleLogin request. idToken prefix: {0}, deviceId: {1}, platform: {2}",
            new Object[]{ tokenPrefix,
                request.getDevice() != null ? request.getDevice().getDeviceId() : "null",
                request.getDevice() != null ? request.getDevice().getPlatform() : "null"
            });
        logger.log(Level.INFO, "[AUTH BACKEND] idToken isNull={0}, isEmpty={1}",
            new Object[]{ request.getIdToken() == null, request.getIdToken() == null || request.getIdToken().isEmpty() });

        AuthResponse response = authService.loginWithGoogle(request);
        logger.log(Level.INFO, "[AUTH BACKEND] loginWithGoogle response state: {0}", response.getAuthenticationState());
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping({"/register", "/signup"})
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody AuthRequests.RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping({"/verify-password", "/password/verify"})
    public ResponseEntity<ApiResponse<AuthResponse>> verifyPassword(@Valid @RequestBody AuthRequests.VerifyPasswordRequest request) {
        AuthResponse response = authService.verifyPassword(request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping({"/verify-otp", "/otp/verify"})
    public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(@Valid @RequestBody AuthRequests.VerifyOtpRequest request) {
        AuthResponse response = authService.verifyOtp(request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping({"/send-otp", "/otp/send"})
    public ResponseEntity<ApiResponse<String>> sendOtp(@Valid @RequestBody AuthRequests.SendOtpRequest request) {
        authService.sendOtp(request);
        return ResponseEntity.ok(ApiResponse.ok("OTP dispatched successfully", UUID.randomUUID().toString()));
    }

    @PostMapping({"/forgot-password", "/password/forgot"})
    public ResponseEntity<ApiResponse<String>> forgotPassword(@Valid @RequestBody AuthRequests.ForgotPasswordRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.ok(ApiResponse.ok("Password reset OTP dispatched successfully", UUID.randomUUID().toString()));
    }

    @PostMapping({"/reset-password", "/password/reset"})
    public ResponseEntity<ApiResponse<String>> resetPassword(@Valid @RequestBody AuthRequests.ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.ok("Password reset successfully completed", UUID.randomUUID().toString()));
    }

    @PostMapping({"/refresh", "/token/refresh"})
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody AuthRequests.RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping({"/remote-logout", "/signout/remote"})
    public ResponseEntity<ApiResponse<String>> remoteLogout(@RequestParam("email") String email) {
        authService.logoutAll(email);
        return ResponseEntity.ok(ApiResponse.ok("All sessions successfully revoked", UUID.randomUUID().toString()));
    }

    @PostMapping({"/logout", "/signout"})
    public ResponseEntity<ApiResponse<String>> logout(@RequestHeader("X-Session-ID") String sessionId) {
        authService.logout(sessionId);
        return ResponseEntity.ok(ApiResponse.ok("Session successfully invalidated", UUID.randomUUID().toString()));
    }
}
