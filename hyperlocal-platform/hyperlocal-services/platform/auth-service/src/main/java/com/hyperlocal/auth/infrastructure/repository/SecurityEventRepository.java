package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.AuthEntities.SecurityEventEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
import java.util.List;

@Repository
public interface SecurityEventRepository extends JpaRepository<SecurityEventEntity, UUID> {
    List<SecurityEventEntity> findByUserId(UUID userId);
}
