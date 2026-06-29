package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.UserSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSessionEntity, UUID> {
    List<UserSessionEntity> findByUserId(UUID userId);
    void deleteByUserId(UUID userId);
}
