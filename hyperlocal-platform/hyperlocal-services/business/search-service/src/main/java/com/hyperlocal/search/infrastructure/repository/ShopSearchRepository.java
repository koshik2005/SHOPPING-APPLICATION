package com.hyperlocal.search.infrastructure.repository;

import com.hyperlocal.search.infrastructure.entity.ShopSearchProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ShopSearchRepository extends JpaRepository<ShopSearchProjection, UUID> {

    @Query("""
           SELECT s FROM ShopSearchProjection s
           WHERE s.deleted = false
             AND s.status = 'ACTIVE'
             AND (LOWER(s.name) LIKE LOWER(CONCAT('%', :query, '%'))
                  OR LOWER(s.description) LIKE LOWER(CONCAT('%', :query, '%')))
           ORDER BY s.name
           """)
    List<ShopSearchProjection> fullTextSearch(@Param("query") String query);
}
