package com.hyperlocal.common.provider;

public interface EmailProvider {
    void sendEmail(String toEmail, String subject, String body);
}
