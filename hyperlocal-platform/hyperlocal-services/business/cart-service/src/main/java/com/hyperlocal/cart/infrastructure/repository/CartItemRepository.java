package com.hyperlocal.cart.infrastructure.repository;

import com.hyperlocal.cart.infrastructure.entity.CartItemEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface CartItemRepository extends JpaRepository<CartItemEntity, UUID> {
    List<CartItemEntity> findByCartId(UUID cartId);
    void deleteByCartId(UUID cartId);
}
