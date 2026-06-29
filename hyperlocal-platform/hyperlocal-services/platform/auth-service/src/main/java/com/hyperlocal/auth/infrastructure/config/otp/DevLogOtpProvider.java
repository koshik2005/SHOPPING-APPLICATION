package com.hyperlocal.auth.infrastructure.config.otp;

import com.hyperlocal.common.provider.OtpProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Development-only OTP Provider.
 * Prints the OTP code ONLY to the secure server log.
 * No SMS or email is sent. Activated on 'dev' profile.
 * Production profile uses a real SmsProvider or EmailProvider implementation.
 */
@Component
@Profile("dev")
public class DevLogOtpProvider implements OtpProvider {

    private static final Logger log = LoggerFactory.getLogger(DevLogOtpProvider.class);

    @Override
    public void sendOtp(String emailOrPhone, String code, String type) {
        // *** DEV ONLY: OTP printed to server log, never sent over network ***
        log.warn("====================================================");
        log.warn("[DEV OTP] Destination : {}", emailOrPhone);
        log.warn("[DEV OTP] Type        : {}", type);
        log.warn("[DEV OTP] Code        : {}", code);
        log.warn("[DEV OTP] Expires in  : 5 minutes");
        log.warn("====================================================");
    }
}
