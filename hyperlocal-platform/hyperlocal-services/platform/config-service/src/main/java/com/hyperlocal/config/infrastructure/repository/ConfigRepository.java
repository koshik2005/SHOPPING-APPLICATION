package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.ConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ConfigRepository extends JpaRepository<ConfigEntity, UUID> {

    /** Global scope lookup */
    Optional<ConfigEntity> findByConfigKeyAndScope(String configKey, String scope);

    /** Legacy fallback — global key lookup (no scope filter) */
    Optional<ConfigEntity> findByConfigKey(String configKey);

    /** Scoped lookup with scope_id (branch / shop / user specific) */
    Optional<ConfigEntity> findByConfigKeyAndScopeAndScopeId(
            String configKey, String scope, UUID scopeId);

    /** Resolve with branch-level override, falling back to GLOBAL */
    @Query("""
        SELECT c FROM ConfigEntity c
        WHERE c.configKey = :key
          AND (
            (c.scope = 'BRANCH' AND c.scopeId = :branchId)
            OR
            (c.scope = 'GLOBAL' AND c.scopeId IS NULL)
          )
        ORDER BY CASE c.scope WHEN 'BRANCH' THEN 0 ELSE 1 END
    """)
    List<ConfigEntity> findByKeyWithBranchFallback(
            @Param("key") String key,
            @Param("branchId") UUID branchId);

    /** All settings for a logical category (for bulk-load in Portal) */
    List<ConfigEntity> findByCategoryAndScope(String category, String scope);

    /** All global settings in a category */
    List<ConfigEntity> findByCategoryAndScopeAndScopeIdIsNull(String category, String scope);

    /** Upsert helper — check existence before saving */
    Optional<ConfigEntity> findByConfigKeyAndScopeAndScopeIdIsNull(
            String configKey, String scope);
}
