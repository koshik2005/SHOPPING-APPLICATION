package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.FeatureFlagEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FeatureFlagRepository extends JpaRepository<FeatureFlagEntity, UUID> {
    Optional<FeatureFlagEntity> findByFlagKeyAndScope(String flagKey, String scope);
    Optional<FeatureFlagEntity> findByFlagKeyAndScopeAndScopeId(String flagKey, String scope, UUID scopeId);
    List<FeatureFlagEntity> findAll();
}
