package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

public class AuthEntities {

    @Getter
    @Setter
    @Entity
    @Table(name = "user_identities")
    public static class UserIdentityEntity {
        @Id
        @GeneratedValue(strategy = GenerationType.AUTO)
        private UUID id;

        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "user_id", nullable = false)
        private UserEntity user;

        @Column(nullable = false)
        private String provider; // GOOGLE, PASSWORD, PHONE

        @Column(name = "provider_user_id", nullable = false)
        private String providerUserId; // provider unique identifier

        @Column(nullable = false)
        private String email;

        @Column(nullable = false)
        private boolean verified = false;

        @Column(name = "linked_at", nullable = false)
        private Instant linkedAt = Instant.now();
    }

    @Getter
    @Setter
    @Entity
    @Table(name = "user_devices")
    public static class UserDeviceEntity {
        @Id
        @GeneratedValue(strategy = GenerationType.AUTO)
        private UUID id;

        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "user_id", nullable = false)
        private UserEntity user;

        @Column(name = "device_id", nullable = false)
        private String deviceId;

        @Column(nullable = false)
        private String model;

        @Column(nullable = false)
        private String manufacturer;

        @Column(nullable = false)
        private String os;

        @Column(name = "push_token")
        private String pushToken;

        @Column(nullable = false)
        private boolean trusted = false;

        @Column(name = "last_login")
        private Instant lastLogin = Instant.now();

        @Column(name = "last_activity")
        private Instant lastActivity = Instant.now();
    }

    @Getter
    @Setter
    @Entity
    @Table(name = "login_history")
    public static class LoginHistoryEntity {
        @Id
        @GeneratedValue(strategy = GenerationType.AUTO)
        private UUID id;

        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "user_id")
        private UserEntity user;

        @Column(nullable = false)
        private String device;

        @Column(name = "ip_address", nullable = false)
        private String ipAddress;

        @Column(nullable = false)
        private String country;

        @Column(nullable = false)
        private String risk; // LOW, MEDIUM, HIGH

        @Column(nullable = false)
        private String result; // SUCCESS, FAILURE
    }

    @Getter
    @Setter
    @Entity
    @Table(name = "security_events")
    public static class SecurityEventEntity {
        @Id
        @GeneratedValue(strategy = GenerationType.AUTO)
        private UUID id;

        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "user_id")
        private UserEntity user;

        @Column(name = "event_type", nullable = false)
        private String eventType; // OTP_FAILED, PASSWORD_CHANGED, DEVICE_ADDED, REMOTE_LOGOUT

        @Column(name = "correlation_id", nullable = false)
        private String correlationId;

        @Column(nullable = false)
        private Instant timestamp = Instant.now();
    }
}
