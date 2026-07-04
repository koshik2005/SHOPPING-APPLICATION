package com.hyperlocal.inventory.infrastructure.repository;

import com.hyperlocal.inventory.infrastructure.entity.CategoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<CategoryEntity, UUID> {
    List<CategoryEntity> findByDeletedFalse();
    List<CategoryEntity> findByServiceKeyAndDeletedFalseOrderByDisplayOrderAsc(String serviceKey);
    List<CategoryEntity> findByActiveTrueAndDeletedFalseOrderByDisplayOrderAsc();
}
