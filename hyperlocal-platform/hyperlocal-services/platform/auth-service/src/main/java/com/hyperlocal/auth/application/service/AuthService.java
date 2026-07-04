package com.hyperlocal.auth.application.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.hyperlocal.auth.infrastructure.dto.*;
import com.hyperlocal.auth.infrastructure.dto.GoogleLoginRequest.DeviceDetails;
import com.hyperlocal.auth.infrastructure.dto.AuthRequests.*;
import com.hyperlocal.auth.infrastructure.entity.UserEntity;
import com.hyperlocal.auth.infrastructure.entity.UserSessionEntity;
import com.hyperlocal.auth.infrastructure.entity.OtpEntity;
import com.hyperlocal.auth.infrastructure.entity.DeviceRegistryEntity;
import com.hyperlocal.auth.infrastructure.entity.OtpRequestEntity;
import com.hyperlocal.auth.infrastructure.entity.LoginAttemptEntity;
import com.hyperlocal.auth.infrastructure.entity.UserLockHistoryEntity;
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
    
    private final DeviceRegistryRepository deviceRegistryRepository;
    private final OtpRequestRepository otpRequestRepository;
    private final LoginAttemptRepository loginAttemptRepository;
    private final UserLockHistoryRepository userLockHistoryRepository;

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
        return completeLoginSession(user, request.getDevice(), getClientIp(), getUserAgent(), false);
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
        return completeLoginSession(user, resolveDeviceDetails(), getClientIp(), getUserAgent(), false);
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
        // Enforce rate limiting
        enforceRateLimit(request.getEmailOrPhone());

        // Validate OTP from database
        var otpOpt = otpRequestRepository.findFirstByEmailOrPhoneAndVerifiedFalseAndExpiresAtAfterOrderByCreatedAtDesc(
            request.getEmailOrPhone(), Instant.now()
        );

        if (otpOpt.isEmpty()) {
            throw new BusinessException("OTP has expired or is invalid", "INVALID_OTP");
        }

        OtpRequestEntity otp = otpOpt.get();
        if (!otp.getOtpCode().equals(request.getOtpCode())) {
            otp.setAttempts(otp.getAttempts() + 1);
            if (otp.getAttempts() >= 3) {
                otp.setVerified(true); // Invalidate after 3 failed inputs
            }
            otpRequestRepository.save(otp);
            throw new BusinessException("Invalid OTP code", "INVALID_OTP");
        }

        otp.setVerified(true);
        otpRequestRepository.save(otp);

        UserEntity user = userRepository.findByEmailAndDeletedFalse(request.getEmailOrPhone())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        logger.log(Level.INFO, "OTP verification successful for user: {0}", user.getEmail());
        return completeLoginSession(user, resolveDeviceDetails(), getClientIp(), getUserAgent(), request.isTakeover());
    }

    @Transactional
    public AuthResponse verifyPassword(VerifyPasswordRequest request) {
        // Enforce Rate Limiting
        enforceRateLimit(request.getEmail());

        UserEntity user = userRepository.findByEmailAndDeletedFalse(request.getEmail())
            .orElseThrow(() -> new BusinessException("User not found", "USER_NOT_FOUND"));

        // Match locks first
        checkAccountLockStatus(user);

        // Match password hashes using BCrypt
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            handleFailedAttempt(request.getEmail());
            throw new BusinessException("Invalid password credentials", "INVALID_CREDENTIALS");
        }

        // If Root / Admin initial credentials require force reset
        if ("PASSWORD_CHANGE_REQUIRED".equals(user.getStatus())) {
            return AuthResponse.builder()
                .authenticationState("PASSWORD_CHANGE_REQUIRED")
                .accessToken("FORCE_RESET_TEMP_TOKEN_" + user.getEmail())
                .build();
        }

        // Enforce 2FA OTP for all admin/manager accounts
        boolean isAdmin = user.getRoles().stream().anyMatch(role -> 
            !role.equals("ROLE_CUSTOMER") && !role.equals("ROLE_DELIVERY_PARTNER")
        );

        if (isAdmin) {
            String otpCode = String.format("%06d", secureRandom.nextInt(1000000));
            OtpRequestEntity otp = new OtpRequestEntity();
            otp.setEmailOrPhone(user.getEmail());
            otp.setOtpCode(otpCode);
            otp.setExpiresAt(Instant.now().plus(5, ChronoUnit.MINUTES));
            otpRequestRepository.save(otp);

            logger.log(Level.INFO, "[MFA OTP DISPATCH] Dispatched OTP code {0} to admin {1}",
                new Object[]{otpCode, user.getEmail()});

            return AuthResponse.builder()
                .authenticationState("OTP_REQUIRED")
                .existingProfile(AuthResponse.ExistingProfileDetails.builder()
                    .displayName(user.getEmail().split("@")[0])
                    .email(user.getEmail())
                    .maskedMobileNumber(maskContact(user.getEmail()))
                    .availableVerificationMethods(List.of("EMAIL_OTP"))
                    .build())
                .build();
        }

        logger.log(Level.INFO, "Password verification successful for user: {0}", user.getEmail());
        return completeLoginSession(user, resolveDeviceDetails(), getClientIp(), getUserAgent(), request.isTakeover());
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
        String newAccessToken = jwtProvider.generateAccessToken(
            user.getId(),
            user.getEmail(),
            user.getRoles(),
            user.getBranchId(),
            user.getShopId(),
            matchedSession.getId(),
            matchedSession.getDeviceId()
        );
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

    private AuthResponse completeLoginSession(UserEntity user, DeviceDetails device, String ipAddress, String userAgent, boolean takeover) {
        // Enforce Device Binding for Delivery Partners
        if (user.getRoles().contains("ROLE_DELIVERY_PARTNER")) {
            String incomingDeviceId = device != null ? device.getDeviceId() : "unknown_device";
            var registeredDevices = deviceRegistryRepository.findByUserId(user.getId());
            if (!registeredDevices.isEmpty()) {
                boolean matches = registeredDevices.stream()
                    .anyMatch(d -> d.getDeviceId().equals(incomingDeviceId));
                if (!matches) {
                    logger.warning("Device mismatch for delivery partner: " + user.getEmail() + ". Attempted: " + incomingDeviceId);
                    return AuthResponse.builder()
                        .authenticationState("DEVICE_MISMATCH")
                        .existingProfile(AuthResponse.ExistingProfileDetails.builder()
                            .email(user.getEmail())
                            .build())
                        .build();
                }
            } else {
                // Register initial device
                var reg = new DeviceRegistryEntity();
                reg.setUserId(user.getId());
                reg.setDeviceId(incomingDeviceId);
                reg.setOsName(device != null ? device.getPlatform() : "Mobile");
                reg.setOsVersion(device != null ? device.getOsVersion() : "Unknown");
                reg.setBrowserName("DeliveryApp");
                deviceRegistryRepository.save(reg);
            }
        }

        // Enforce Single Active Session Policy for admin roles
        boolean isAdmin = user.getRoles().stream().anyMatch(role -> 
            !role.equals("ROLE_CUSTOMER") && !role.equals("ROLE_DELIVERY_PARTNER")
        );

        if (isAdmin) {
            List<UserSessionEntity> activeSessions = sessionRepository.findByUserId(user.getId());
            if (!activeSessions.isEmpty()) {
                if (!takeover) {
                    return AuthResponse.builder()
                        .authenticationState("SESSION_CONFLICT")
                        .existingProfile(AuthResponse.ExistingProfileDetails.builder()
                            .email(user.getEmail())
                            .displayName(user.getEmail().split("@")[0])
                            .build())
                        .build();
                } else {
                    // Invalidate previous sessions
                    sessionRepository.deleteByUserId(user.getId());
                    logger.info("Session takeover complete for user: " + user.getEmail() + ". Previous sessions cleared.");
                }
            }
        }

        // 1. Save session entry with secure hashed refresh token first to get session ID
        UserSessionEntity session = new UserSessionEntity();
        session.setUserId(user.getId());
        session.setDeviceId(device != null ? device.getDeviceId() : "unknown_device");
        session.setIpAddress(ipAddress);
        session.setUserAgent(userAgent);
        session.setExpiresAt(Instant.now().plus(7, ChronoUnit.DAYS));
        session.setRefreshTokenHash(passwordEncoder.encode(UUID.randomUUID().toString())); // placeholder, set below
        session = sessionRepository.save(session);

        String refreshToken = UUID.randomUUID().toString();
        session.setRefreshTokenHash(passwordEncoder.encode(refreshToken));
        sessionRepository.save(session);

        String accessToken = jwtProvider.generateAccessToken(
            user.getId(),
            user.getEmail(),
            user.getRoles(),
            user.getBranchId(),
            user.getShopId(),
            session.getId(),
            device != null ? device.getDeviceId() : "unknown_device"
        );

        // 2. Track & Register Device details
        if (device != null) {
            registerOrUpdateDevice(user, device);
        }

        // 3. Record Successful Login history
        recordLoginAttempt(user, device, ipAddress, "SUCCESS", "LOGIN_COMPLETED");

        String primaryRole = user.getRoles().isEmpty() ? "ROLE_CUSTOMER" : user.getRoles().iterator().next();

        return AuthResponse.builder()
            .authenticationState("LOGIN_COMPLETED")
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .expiresIn(900)
            .user(AuthResponse.UserDetails.builder()
                .id(user.getId().toString())
                .email(user.getEmail())
                .role(primaryRole)
                .profile(AuthResponse.ProfileDetails.builder()
                    .displayName(user.getEmail().split("@")[0])
                    .profilePhotoUrl("https://cdn.hyperlocal.app/users/avatars/default.png")
                    .build())
                .build())
            .build();
    }

    private void checkAccountLockStatus(UserEntity user) {
        if ("TEMP_LOCKED".equals(user.getStatus())) {
            var lockOpt = userLockHistoryRepository.findFirstByUserIdAndUnlockedAtIsNullOrderByLockedAtDesc(user.getId());
            if (lockOpt.isPresent()) {
                var lock = lockOpt.get();
                if (lock.getLockedAt().plus(15, ChronoUnit.MINUTES).isAfter(Instant.now())) {
                    throw new BusinessException("Account is temporarily locked. Try again later.", "ACCOUNT_TEMP_LOCKED");
                } else {
                    user.setStatus("ACTIVE");
                    userRepository.save(user);
                    lock.setUnlockedAt(Instant.now());
                    userLockHistoryRepository.save(lock);
                }
            }
        } else if ("PERM_LOCKED".equals(user.getStatus())) {
            throw new BusinessException("Account is permanently locked. Contact administrator.", "ACCOUNT_PERM_LOCKED");
        }
    }

    private void handleFailedAttempt(String email) {
        LoginAttemptEntity attempt = new LoginAttemptEntity();
        attempt.setEmail(email);
        attempt.setIpAddress(getClientIp());
        attempt.setStatus("FAILED");
        attempt.setFailureReason("INVALID_PASSWORD");
        loginAttemptRepository.save(attempt);

        Instant threshold = Instant.now().minus(15, ChronoUnit.MINUTES);
        long fails = loginAttemptRepository.countByEmailAndStatusAndAttemptTimeAfter(email, "FAILED", threshold);

        var userOpt = userRepository.findByEmailAndDeletedFalse(email);
        if (userOpt.isPresent()) {
            UserEntity user = userOpt.get();
            if (fails >= 10) {
                user.setStatus("PERM_LOCKED");
                userRepository.save(user);

                var lock = new UserLockHistoryEntity();
                lock.setUserId(user.getId());
                lock.setLockType("PERMANENT");
                lock.setReason("10 failed attempts reached");
                userLockHistoryRepository.save(lock);
            } else if (fails >= 5 && !"TEMP_LOCKED".equals(user.getStatus())) {
                user.setStatus("TEMP_LOCKED");
                userRepository.save(user);

                var lock = new UserLockHistoryEntity();
                lock.setUserId(user.getId());
                lock.setLockType("TEMPORARY");
                lock.setReason("5 failed attempts reached");
                userLockHistoryRepository.save(lock);
            }
        }
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
