package com.hyperlocal.common.provider;

public interface SmsProvider {
    void sendSms(String phoneNumber, String message);
}
