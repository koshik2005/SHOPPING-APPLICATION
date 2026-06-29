package com.hyperlocal.integration.sms;

import org.springframework.stereotype.Component;

@Component
public class SmsClient {
    public void sendSms(String phoneNumber, String message) {
        // Concrete Twilio / AWS SNS adapter integration
    }
}
