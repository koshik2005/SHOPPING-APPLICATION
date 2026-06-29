package com.hyperlocal.common.provider;

public interface OtpProvider {
    void sendOtp(String emailOrPhone, String code, String type);
}
