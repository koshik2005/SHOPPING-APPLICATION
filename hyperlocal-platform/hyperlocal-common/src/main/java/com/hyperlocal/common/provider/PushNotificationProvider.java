package com.hyperlocal.common.provider;

public interface PushNotificationProvider {
    void sendPush(String token, String title, String body);
}
