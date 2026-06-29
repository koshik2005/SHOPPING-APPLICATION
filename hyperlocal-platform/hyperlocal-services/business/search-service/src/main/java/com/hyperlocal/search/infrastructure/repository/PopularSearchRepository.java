package com.hyperlocal.search.infrastructure.repository;

import com.hyperlocal.search.infrastructure.entity.PopularSearchEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface PopularSearchRepository extends JpaRepository<PopularSearchEntity, UUID> {
    @Query("SELECT p FROM PopularSearchEntity p ORDER BY p.searchCount DESC")
    List<PopularSearchEntity> findTopPopularSearches();
}
