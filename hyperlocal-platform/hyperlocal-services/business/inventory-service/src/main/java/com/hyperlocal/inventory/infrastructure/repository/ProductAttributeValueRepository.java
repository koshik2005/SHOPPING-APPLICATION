package com.hyperlocal.inventory.infrastructure.repository;

import com.hyperlocal.inventory.infrastructure.entity.ProductAttributeValueEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductAttributeValueRepository extends JpaRepository<ProductAttributeValueEntity, UUID> {
    List<ProductAttributeValueEntity> findByProductId(UUID productId);
    Optional<ProductAttributeValueEntity> findByProductIdAndAttributeKey(UUID productId, String attributeKey);
}
