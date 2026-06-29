package com.hyperlocal.notification.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "notification_queue")
public class NotificationEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "template_id")
    private UUID templateId;

    @Column(nullable = false)
    private String recipient;

    @Column(nullable = false)
    private String status = "QUEUED";

    @Column(name = "retry_count", nullable = false)
    private int retryCount = 0;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
