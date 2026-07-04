package com.hyperlocal.auth.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "user_lock_history")
public class UserLockHistoryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "lock_type", nullable = false)
    private String lockType; // TEMPORARY, PERMANENT

    @Column(name = "locked_at", nullable = false, updatable = false)
    private Instant lockedAt = Instant.now();

    @Column(name = "unlocked_at")
    private Instant unlockedAt;

    @Column(name = "unlocked_by")
    private UUID unlockedBy;

    @Column(length = 255)
    private String reason;
}
