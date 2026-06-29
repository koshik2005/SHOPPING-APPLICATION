package com.hyperlocal.auth.application.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.hyperlocal.auth.infrastructure.dto.*;
import com.hyperlocal.auth.infrastructure.dto.GoogleLoginRequest.DeviceDetails;
import com.hyperlocal.auth.infrastructure.dto.AuthRequests.*;
import com.hyperlocal.auth.infrastructure.entity.UserEntity;
import com.hyperlocal.auth.infrastructure.entity.UserSessionEntity;
import com.hyperlocal.auth.infrastructure.entity.OtpEntity;
import com.hyperlocal.auth.infrastructure.entity.AuthEntities.*;
import com.hyperlocal.auth.infrastructure.repository.*;
import com.hyperlocal.auth.infrastructure.config.JwtProvider;
import com.hyperlocal.auth.infrastructure.config.GoogleIdTokenVerifierService;
import com.hyperlocal.common.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.security.SecureRandom;
import java.util.UUID;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Level;

@Service
@RequiredArgsConstructor
public class AuthService {
    private static final Logger logger = Logger.getLogger(AuthService.class.getName());
    private static final SecureRandom secureRandom = new SecureRandom();

    private final UserRepository userRepository;
    private final UserSessionRepository sessionRepository;
    private final UserIdentityRepository identityRepository;
    private final UserDeviceRepository deviceRepository;
    private final LoginHistoryRepository loginHistoryRepository;
    private final SecurityEventRepository securityEventRepository;
    private final OtpRepository otpRepository;

    private final JwtProvider jwtProvider;
    private final GoogleIdTokenVerifierService googleIdTokenVerifierService;
    private final PasswordEncoder passwordEncoder;
    private final HttpServletRequest httpServletRequest;

    @Transactional
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        GoogleIdToken.Payload payload = googleIdTokenVerifierService.verify(request.getIdToken());
        String email = payload.getEmail();
        String name = (String) payload.get("name");
        String pictureUrl = (String) payload.get("picture");
        String googleSubId = payload.getSubject();

        // Audit check: query user identity provider table
        var identityOpt = identityRepository.findByProviderAndProviderUserId("GOOGLE", googleSubId);

        if (identityOpt.isEmpty()) {
            // Check if user already exists by email to perform account linking
            var userOpt = userRepository.findByEmailAndDeletedFalse(email);
            if (userOpt.isEmpty()) {
                logger.log(Level.INFO, "Google login: Registration required for new user: {0}", email);
                return AuthResponse.builder()
                    .authenticationState("REGISTRATION_REQUIRED")
                    .googleProfile(AuthResponse.GoogleProfileDetails.builder()
                        .displayName(name)
                        .email(email)
                        .profilePhotoUrl(pictureUrl)
                        .build())
                    .build();
            }

            // Link existing account with Google Identity Provider
            UserEntity existingUser = userOpt.get();
            UserIdentityEntity newIdentity = new UserIdentityEntity();
            newIdentity.setUser(existingUser);
            newIdentity.setProvider("GOOGLE");
            newIdentity.setProviderUserId(googleSubId);
            newIdentity.setEmail(email);
            newIdentity.setVerified(true);
            identityRepository.save(newIdentity);
            identityOpt = java.util.Optional.of(newIdentity);
            logger.log(Level.INFO, "Linked Google Identity to existing user: {0}", email);
        }

        UserEntity user = identityOpt.get().getUser();

        // Account status locks
        if ("DISABLED".equals(user.getStatus())) {
            recordLoginAttempt(user, request.getDevice(), getClientIp(), "FAILED", "ACCOUNT_DISABLED");
            return AuthResponse.builder().authenticationState("ACCOUNT_DISABLED").build();
        } else if ("BLOCKED".equals(user.getStatus())) {
            recordLoginAttempt(user, request.getDevice(), getClientIp(), "FAILED", "ACCOUNT_BLOCKED");
            return AuthResponse.builder().authenticationState("ACCOUNT_BLOCKED").build();
        }

        // If Multi-Factor Authentication is enabled, require second-factor challenge
        if (user.isMfaEnabled()) {
            logger.log(Level.INFO, "MFA Challenge required for user: {0}", user.getEmail());
            return AuthResponse.builder()
                .authenticationState("PASSWORD_REQUIRED")
                .existingProfile(AuthResponse.ExistingProfileDetails.builder()
                    .displayName(name != null ? name : user.getEmail().split("@")[0])
                    .email(user.getEmail())
                    .maskedMobileNumber(maskContact(user.getEmail()))
                    .availableVerificationMethods(List.of("MOBILE_OTP", "EMAIL_OTP", "PASSWORD"))
                    .build())
                .build();
        }

        // Otherwise complete login session immediately
        return completeLoginSession(user, request.getDevice(), getClientIp(), getUserAgent());
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        var existingUser = userRepository.findByEmailAndDeletedFalse(request.getEmail());
        if (existingUser.isPresent()) {
            throw new BusinessException("User already exists", "USER_ALREADY_EXISTS");
        }

        // Create new user profile in Database
        UserEntity user = new UserEntity();
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode("OAUTH_FEDERATED_KEY_" + UUID.randomUUID())); // Secure initial credentials
        user.setStatus("ACTIVE");
        user = userRepository.save(user);

        // Associate identity
        UserIdentityEntity identity = new UserIdentityEntity();
        identity.setUser(user);
        identity.setProvider("GOOGLE");
        identity.setProviderUserId(UUID.randomUUID().toString());
        identity.setEmail(request.getEmail());
        identity.setVerified(true);
        identityRepository.save(identity);

        logger.log(Level.INFO, "Successfully registered new customer: {0}", request.getEmail());
        return completeLoginSession(user, resolveDeviceDetails(), getClientIp(), getUserAgent());
    }

    @Transactional
    public void sendOtp(SendOtpRequest request) {
        // Enforce Rate Limiting check
        enforceRateLimit(request.getEmailOrPhone());

        // Generate a cryptographically secure 6-digit OTP
        String otpCode = String.format("%06d", secureRandom.nextInt(1000000));
        Instant expiryTime = Instant.now().plus(5, ChronoUnit.MINUTES);

        // Save OTP
        OtpEntity otp = new OtpEntity();
        otp.setEmailOrPhone(request.getEmailOrPhone());
        otp.setOtpCode(otpCode);
        otp.setExpiryTime(expiryTime);
        otpRepository.save(otp);

        // Audit log dispatch event
        logger.log(Level.INFO, "[OTP DISPATCH] Dispatched OTP code {0} to {1} (Type: {2})",
            new Object[]{otpCode, request.getEmailOrPhone(), request.getType()});
    }

    @Transactional
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        // Enforce Rate Limiting
        enforceRateLimit(request.getEmailOrPhone());

        // Validate OTP from database
        OtpEntity otp = otpRepository.findFirstByEmailOrPhoneAndOtpCodeAndUsedFalseOrderByCreatedAtDesc(
                request.getEmailOrPhone(), request.getOtpCode())
            .orElseThrow(() -> {
                recordFailedAttempt(request.getEmailOrPhone());
                return new BusinessException("Invalid OTP code", "INVALID_OTP");
            });

        if (otp.getExpiryTime().isBefore(Instant.now())) {
            throw new BusinessException("OTP has expired", "OTP_EXPIRED");
        }

        // Mark OTP as used
        otp.setUsed(true);
        otpRepository.save(otp);

        // Find user by email
        UserEntity user = userRepository.findByEmailAndDeletedFalse(request.getEmailOrPhone())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        logger.log(Level.INFO, "OTP verification successful for user: {0}", user.getEmail());
        return completeLoginSession(user, resolveDeviceDetails(), getClientIp(), getUserAgent());
    }

    @Transactional
    public AuthResponse verifyPassword(VerifyPasswordRequest request) {
        // Enforce Rate Limiting
        enforceRateLimit(request.getEmail());

        UserEntity user = userRepository.findByEmailAndDeletedFalse(request.getEmail())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        // Match password hashes using BCrypt
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            recordFailedAttempt(request.getEmail());
            throw new BusinessException("Invalid password credentials", "INVALID_CREDENTIALS");
        }

        logger.log(Level.INFO, "Password verification successful for user: {0}", user.getEmail());
        return completeLoginSession(user, resolveDeviceDetails(), getClientIp(), getUserAgent());
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        UserEntity user = userRepository.findByEmailAndDeletedFalse(request.getEmail())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        // Generate and dispatch reset password OTP
        SendOtpRequest sendOtpRequest = new SendOtpRequest();
        sendOtpRequest.setEmailOrPhone(user.getEmail());
        sendOtpRequest.setType("EMAIL");
        sendOtp(sendOtpRequest);

        // Log security audit event
        SecurityEventEntity event = new SecurityEventEntity();
        event.setUser(user);
        event.setEventType("FORGOT_PASSWORD_REQUEST");
        event.setCorrelationId(UUID.randomUUID().toString());
        securityEventRepository.save(event);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        OtpEntity otp = otpRepository.findFirstByEmailOrPhoneAndOtpCodeAndUsedFalseOrderByCreatedAtDesc(
                request.getEmail(), request.getOtpCode())
            .orElseThrow(() -> new BusinessException("Invalid OTP code", "INVALID_OTP"));

        if (otp.getExpiryTime().isBefore(Instant.now())) {
            throw new BusinessException("OTP has expired", "OTP_EXPIRED");
        }

        otp.setUsed(true);
        otpRepository.save(otp);

        UserEntity user = userRepository.findByEmailAndDeletedFalse(request.getEmail())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Invalidate all active sessions (Force logout on password reset)
        sessionRepository.deleteByUserId(user.getId());

        SecurityEventEntity event = new SecurityEventEntity();
        event.setUser(user);
        event.setEventType("PASSWORD_RESET_SUCCESS");
        event.setCorrelationId(UUID.randomUUID().toString());
        securityEventRepository.save(event);

        logger.log(Level.INFO, "Password reset successful for user: {0}", user.getEmail());
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String inputToken = request.getRefreshToken();
        // Query all active sessions
        List<UserSessionEntity> sessions = sessionRepository.findAll();
        UserSessionEntity matchedSession = null;

        for (UserSessionEntity session : sessions) {
            if (passwordEncoder.matches(inputToken, session.getRefreshTokenHash())) {
                matchedSession = session;
                break;
            }
        }

        if (matchedSession == null) {
            throw new BusinessException("Invalid refresh token", "INVALID_REFRESH_TOKEN");
        }

        if (matchedSession.getExpiresAt().isBefore(Instant.now())) {
            sessionRepository.delete(matchedSession);
            throw new BusinessException("Refresh token has expired", "EXPIRED_REFRESH_TOKEN");
        }

        UserEntity user = userRepository.findById(matchedSession.getUserId())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        // Generate new token credentials (Token Rotation)
        String newAccessToken = jwtProvider.generateAccessToken(user.getId(), user.getEmail(), "ROLE_CUSTOMER");
        String newRefreshToken = UUID.randomUUID().toString();

        matchedSession.setRefreshTokenHash(passwordEncoder.encode(newRefreshToken));
        matchedSession.setExpiresAt(Instant.now().plus(7, ChronoUnit.DAYS)); // Extend session life
        sessionRepository.save(matchedSession);

        return AuthResponse.builder()
            .authenticationState("LOGIN_COMPLETED")
            .accessToken(newAccessToken)
            .refreshToken(newRefreshToken)
            .expiresIn(900)
            .build();
    }

    @Transactional
    public void logout(String sessionId) {
        UUID sessionUuid = UUID.fromString(sessionId);
        var sessionOpt = sessionRepository.findById(sessionUuid);
        if (sessionOpt.isPresent()) {
            UserSessionEntity session = sessionOpt.get();
            sessionRepository.delete(session);

            SecurityEventEntity logoutEvent = new SecurityEventEntity();
            UserEntity user = new UserEntity();
            user.setId(session.getUserId());
            logoutEvent.setUser(user);
            logoutEvent.setEventType("LOGOUT");
            logoutEvent.setCorrelationId(UUID.randomUUID().toString());
            securityEventRepository.save(logoutEvent);
        }
        logger.log(Level.INFO, "Session invalidated successfully: {0}", sessionId);
    }

    @Transactional
    public void logoutAll(String email) {
        UserEntity user = userRepository.findByEmailAndDeletedFalse(email)
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        sessionRepository.deleteByUserId(user.getId());

        SecurityEventEntity event = new SecurityEventEntity();
        event.setUser(user);
        event.setEventType("REMOTE_LOGOUT_ALL");
        event.setCorrelationId(UUID.randomUUID().toString());
        securityEventRepository.save(event);

        logger.log(Level.INFO, "Invalidated all active sessions for user: {0}", email);
    }

    private AuthResponse completeLoginSession(UserEntity user, DeviceDetails device, String ipAddress, String userAgent) {
        String accessToken = jwtProvider.generateAccessToken(user.getId(), user.getEmail(), "ROLE_CUSTOMER");
        String refreshToken = UUID.randomUUID().toString();

        // 1. Save session entry with secure hashed refresh token
        UserSessionEntity session = new UserSessionEntity();
        session.setUserId(user.getId());
        session.setDeviceId(device != null ? device.getDeviceId() : "unknown_device");
        session.setIpAddress(ipAddress);
        session.setUserAgent(userAgent);
        session.setExpiresAt(Instant.now().plus(7, ChronoUnit.DAYS));
        session.setRefreshTokenHash(passwordEncoder.encode(refreshToken));
        sessionRepository.save(session);

        // 2. Track & Register Device details
        if (device != null) {
            registerOrUpdateDevice(user, device);
        }

        // 3. Record Successful Login history
        recordLoginAttempt(user, device, ipAddress, "SUCCESS", "LOGIN_COMPLETED");

        return AuthResponse.builder()
            .authenticationState("LOGIN_COMPLETED")
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .expiresIn(900)
            .user(AuthResponse.UserDetails.builder()
                .id(user.getId().toString())
                .email(user.getEmail())
                .role("ROLE_CUSTOMER")
                .profile(AuthResponse.ProfileDetails.builder()
                    .displayName(user.getEmail().split("@")[0])
                    .profilePhotoUrl("https://cdn.hyperlocal.app/users/avatars/default.png")
                    .build())
                .build())
            .build();
    }

    private void registerOrUpdateDevice(UserEntity user, DeviceDetails details) {
        var deviceOpt = deviceRepository.findByUserIdAndDeviceId(user.getId(), details.getDeviceId());
        UserDeviceEntity device;
        if (deviceOpt.isPresent()) {
            device = deviceOpt.get();
            device.setLastActivity(Instant.now());
        } else {
            device = new UserDeviceEntity();
            device.setUser(user);
            device.setDeviceId(details.getDeviceId());
            device.setModel(details.getDeviceName() != null ? details.getDeviceName() : "Unknown Model");
            device.setManufacturer(details.getPlatform() != null ? details.getPlatform() : "Unknown Manufacturer");
            device.setOs(details.getOsVersion() != null ? details.getOsVersion() : "Unknown OS");
            device.setTrusted(true);
        }
        device.setPushToken(details.getFcmToken());
        deviceRepository.save(device);
    }

    private void recordLoginAttempt(UserEntity user, DeviceDetails device, String ipAddress, String result, String details) {
        LoginHistoryEntity history = new LoginHistoryEntity();
        history.setUser(user);
        history.setDevice(device != null ? device.getPlatform() + " " + device.getDeviceName() : "Unknown");
        history.setIpAddress(ipAddress);
        history.setCountry("IN");
        history.setRisk("LOW");
        history.setResult(result);
        loginHistoryRepository.save(history);
    }

    private void recordFailedAttempt(String emailOrPhone) {
        LoginHistoryEntity history = new LoginHistoryEntity();
        history.setDevice("Unknown");
        history.setIpAddress(getClientIp());
        history.setCountry("IN");
        history.setRisk("HIGH");
        history.setResult("FAILED");
        loginHistoryRepository.save(history);
    }

    private void enforceRateLimit(String emailOrPhone) {
        Instant limitTime = Instant.now().minus(15, ChronoUnit.MINUTES);
        long failedAttempts = loginHistoryRepository.countByResultAndCreatedAtAfter("FAILED", limitTime);
        if (failedAttempts >= 5) {
            throw new BusinessException("Too many failed requests. Account suspended for 15 minutes.", "TOO_MANY_REQUESTS");
        }
    }

    private String maskContact(String contact) {
        if (contact.contains("@")) {
            String[] parts = contact.split("@");
            return parts[0].charAt(0) + "****@" + parts[1];
        }
        return contact.substring(0, 3) + "****" + contact.substring(contact.length() - 3);
    }

    private String getClientIp() {
        String xff = httpServletRequest.getHeader("X-Forwarded-For");
        if (xff != null && !xff.trim().isEmpty()) {
            return xff.split(",")[0].trim();
        }
        return httpServletRequest.getRemoteAddr();
    }

    private String getUserAgent() {
        String ua = httpServletRequest.getHeader("User-Agent");
        return ua != null ? ua : "Unknown Client";
    }

    private DeviceDetails resolveDeviceDetails() {
        DeviceDetails details = new DeviceDetails();
        String xDeviceInfo = httpServletRequest.getHeader("X-Device-Info");
        if (xDeviceInfo != null && !xDeviceInfo.trim().isEmpty()) {
            try {
                String[] parts = xDeviceInfo.split(";");
                for (String part : parts) {
                    String[] kv = part.split("=");
                    if (kv.length == 2) {
                        String k = kv[0].trim();
                        String v = kv[1].trim();
                        if ("id".equalsIgnoreCase(k)) details.setDeviceId(v);
                        else if ("model".equalsIgnoreCase(k)) details.setDeviceName(v);
                        else if ("manufacturer".equalsIgnoreCase(k)) details.setPlatform(v);
                        else if ("os".equalsIgnoreCase(k)) details.setOsVersion(v);
                        else if ("fcm".equalsIgnoreCase(k)) details.setFcmToken(v);
                    }
                }
            } catch (Exception e) {
                // Ignore parse errors
            }
        }
        if (details.getDeviceId() == null) {
            String ua = getUserAgent();
            details.setDeviceId("device_" + Math.abs(ua.hashCode()));
            details.setDeviceName(ua.length() > 50 ? ua.substring(0, 50) : ua);
            details.setPlatform("Web/Mobile");
            details.setOsVersion("HTTP Client");
            details.setFcmToken("fcm_token_none");
        }
        return details;
    }
}
