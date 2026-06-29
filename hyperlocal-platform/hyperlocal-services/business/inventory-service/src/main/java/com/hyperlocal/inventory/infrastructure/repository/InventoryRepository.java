package com.hyperlocal.inventory.infrastructure.repository;

import com.hyperlocal.inventory.infrastructure.entity.InventoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InventoryRepository extends JpaRepository<InventoryEntity, UUID> {
    Optional<InventoryEntity> findByProductVariantId(UUID productVariantId);
}
