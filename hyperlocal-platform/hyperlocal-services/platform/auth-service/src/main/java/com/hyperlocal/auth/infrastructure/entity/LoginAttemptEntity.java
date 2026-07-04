package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "login_attempts")
public class LoginAttemptEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(nullable = false)
    private String email;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(nullable = false)
    private String status; // SUCCESS, FAILED

    @Column(name = "attempt_time", nullable = false, updatable = false)
    private Instant attemptTime = Instant.now();

    @Column(name = "failure_reason")
    private String failureReason;
}
