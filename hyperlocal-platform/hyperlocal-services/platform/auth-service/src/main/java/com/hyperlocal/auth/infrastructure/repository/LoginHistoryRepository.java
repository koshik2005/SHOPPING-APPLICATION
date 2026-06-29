package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.AuthEntities.LoginHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
import java.util.List;
import java.time.Instant;

@Repository
public interface LoginHistoryRepository extends JpaRepository<LoginHistoryEntity, UUID> {
    List<LoginHistoryEntity> findByUserId(UUID userId);
    long countByResultAndCreatedAtAfter(String result, Instant date);
}
