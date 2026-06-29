package com.hyperlocal.notification.infrastructure.repository;

import com.hyperlocal.notification.infrastructure.entity.NotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<NotificationEntity, UUID> {
}
