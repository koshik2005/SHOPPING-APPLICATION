package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.AuthEntities.UserDeviceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;
import java.util.List;

@Repository
public interface UserDeviceRepository extends JpaRepository<UserDeviceEntity, UUID> {
    Optional<UserDeviceEntity> findByUserIdAndDeviceId(UUID userId, String deviceId);
    List<UserDeviceEntity> findByUserId(UUID userId);
}
