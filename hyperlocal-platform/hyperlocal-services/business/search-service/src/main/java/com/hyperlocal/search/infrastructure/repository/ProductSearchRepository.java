package com.hyperlocal.search.infrastructure.repository;

import com.hyperlocal.search.infrastructure.entity.ProductSearchProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProductSearchRepository extends JpaRepository<ProductSearchProjection, UUID> {

    /**
     * PostgreSQL full-text search across name and description.
     * Uses ILIKE for case-insensitive partial matching — suitable for
     * direct PostgreSQL without Elasticsearch.
     * Future migration path: replace with an Elasticsearch-backed repository.
     */
    @Query("""
           SELECT p FROM ProductSearchProjection p
           WHERE p.deleted = false
             AND p.status = 'ACTIVE'
             AND (LOWER(p.name) LIKE LOWER(CONCAT('%', :query, '%'))
                  OR LOWER(p.description) LIKE LOWER(CONCAT('%', :query, '%')))
           ORDER BY p.name
           """)
    List<ProductSearchProjection> fullTextSearch(@Param("query") String query);
}
