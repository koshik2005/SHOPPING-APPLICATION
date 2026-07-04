package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.BannerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface BannerRepository extends JpaRepository<BannerEntity, UUID> {

    @Query("""
        SELECT b FROM BannerEntity b
        WHERE b.active = TRUE
          AND (b.branchId = :branchId OR b.branchId IS NULL)
          AND (b.validFrom IS NULL OR b.validFrom <= :now)
          AND (b.validTo IS NULL OR b.validTo >= :now)
        ORDER BY
          CASE WHEN b.branchId IS NOT NULL THEN 0 ELSE 1 END,
          b.displayOrder ASC
    """)
    List<BannerEntity> findActiveBannersForBranch(
            @Param("branchId") UUID branchId,
            @Param("now") Instant now);
}
