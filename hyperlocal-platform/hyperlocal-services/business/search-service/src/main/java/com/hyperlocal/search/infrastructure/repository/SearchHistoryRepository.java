package com.hyperlocal.search.infrastructure.repository;

import com.hyperlocal.search.infrastructure.entity.SearchHistoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface SearchHistoryRepository extends JpaRepository<SearchHistoryEntity, UUID> {
    List<SearchHistoryEntity> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);
}
