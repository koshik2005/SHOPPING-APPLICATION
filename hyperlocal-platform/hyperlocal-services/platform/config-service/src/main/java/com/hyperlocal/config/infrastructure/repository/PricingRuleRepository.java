package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.PricingRuleEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface PricingRuleRepository extends JpaRepository<PricingRuleEntity, UUID> {

    /** Resolve: branch-scoped first, then service-scoped, then global */
    @Query("""
        SELECT p FROM PricingRuleEntity p
        WHERE p.ruleKey = :ruleKey
          AND (
            (p.branchId = :branchId AND (p.serviceKey = :serviceKey OR p.serviceKey IS NULL))
            OR
            (p.branchId IS NULL AND (p.serviceKey = :serviceKey OR p.serviceKey IS NULL))
          )
        ORDER BY
          CASE WHEN p.branchId IS NOT NULL THEN 0 ELSE 1 END,
          CASE WHEN p.serviceKey IS NOT NULL THEN 0 ELSE 1 END,
          p.priority DESC
    """)
    List<PricingRuleEntity> findByRuleKeyResolved(
            @Param("ruleKey") String ruleKey,
            @Param("serviceKey") String serviceKey,
            @Param("branchId") UUID branchId);

    List<PricingRuleEntity> findByBranchIdIsNullAndServiceKeyIsNullOrderByPriorityDesc();
    List<PricingRuleEntity> findByBranchIdOrderByPriorityDesc(UUID branchId);
}
