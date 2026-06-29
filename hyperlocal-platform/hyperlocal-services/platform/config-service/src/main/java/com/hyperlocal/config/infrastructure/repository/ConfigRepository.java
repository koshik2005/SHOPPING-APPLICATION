package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.ConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ConfigRepository extends JpaRepository<ConfigEntity, UUID> {
    Optional<ConfigEntity> findByConfigKey(String key);
}
