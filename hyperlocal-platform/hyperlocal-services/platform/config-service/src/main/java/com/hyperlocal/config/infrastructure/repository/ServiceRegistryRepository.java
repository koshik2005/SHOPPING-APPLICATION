package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.ServiceRegistryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServiceRegistryRepository extends JpaRepository<ServiceRegistryEntity, UUID> {
    List<ServiceRegistryEntity> findByActiveTrueOrderByDisplayOrderAsc();
    Optional<ServiceRegistryEntity> findByServiceKey(String serviceKey);
    boolean existsByServiceKey(String serviceKey);
}
