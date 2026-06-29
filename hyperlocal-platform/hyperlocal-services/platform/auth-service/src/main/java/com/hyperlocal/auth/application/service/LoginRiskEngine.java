package com.hyperlocal.auth.application.service;

import org.springframework.stereotype.Component;

@Component
public class LoginRiskEngine {
    public int calculateRiskScore(String deviceId, String ipAddress, String osVersion) {
        int score = 0;
        if (osVersion != null && osVersion.contains("root")) {
            score += 50;
        }
        if (ipAddress != null && ipAddress.startsWith("10.0.2")) {
            score += 10;
        }
        return score;
    }
}
