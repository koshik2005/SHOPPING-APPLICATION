package com.hyperlocal.inventory.infrastructure.repository;

import com.hyperlocal.inventory.infrastructure.entity.ProductEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProductRepository extends JpaRepository<ProductEntity, UUID> {
    List<ProductEntity> findByShopIdAndDeletedFalse(UUID shopId);
    List<ProductEntity> findByShopIdAndServiceKeyAndDeletedFalse(UUID shopId, String serviceKey);
    List<ProductEntity> findByShopIdAndActiveTrueAndDeletedFalse(UUID shopId);
}
