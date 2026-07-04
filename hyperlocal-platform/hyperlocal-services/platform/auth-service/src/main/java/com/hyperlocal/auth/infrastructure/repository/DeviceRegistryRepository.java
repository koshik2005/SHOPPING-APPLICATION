package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.DeviceRegistryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceRegistryRepository extends JpaRepository<DeviceRegistryEntity, UUID> {
    List<DeviceRegistryEntity> findByUserId(UUID userId);
    Optional<DeviceRegistryEntity> findByUserIdAndDeviceId(UUID userId, String deviceId);
    void deleteByUserIdAndDeviceId(UUID userId, String deviceId);
}
