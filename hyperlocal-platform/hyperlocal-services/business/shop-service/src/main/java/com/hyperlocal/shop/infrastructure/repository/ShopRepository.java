package com.hyperlocal.shop.infrastructure.repository;

import com.hyperlocal.shop.infrastructure.entity.ShopEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ShopRepository extends JpaRepository<ShopEntity, UUID> {
    List<ShopEntity> findByBranchIdAndDeletedFalse(UUID branchId);
}
