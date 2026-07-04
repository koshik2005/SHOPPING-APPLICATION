package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.UserLockHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserLockHistoryRepository extends JpaRepository<UserLockHistoryEntity, UUID> {
    Optional<UserLockHistoryEntity> findFirstByUserIdAndUnlockedAtIsNullOrderByLockedAtDesc(UUID userId);
}
