package com.hyperlocal.notification.application.service;

import com.hyperlocal.notification.infrastructure.entity.NotificationEntity;
import com.hyperlocal.notification.infrastructure.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationService {
    private final NotificationRepository notificationRepository;

    @Transactional
    public void queueNotification(NotificationEntity notification) {
        notificationRepository.save(notification);
    }
}
