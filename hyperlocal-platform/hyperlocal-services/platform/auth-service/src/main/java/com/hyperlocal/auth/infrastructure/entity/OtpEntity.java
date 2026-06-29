package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "one_time_passwords")
public class OtpEntity {

    @Id
    private UUID id = UUID.randomUUID();

    @Column(name = "email_or_phone", nullable = false)
    private String emailOrPhone;

    @Column(name = "otp_code", nullable = false, length = 6)
    private String otpCode;

    @Column(name = "expiry_time", nullable = false)
    private Instant expiryTime;

    @Column(nullable = false)
    private boolean used = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
