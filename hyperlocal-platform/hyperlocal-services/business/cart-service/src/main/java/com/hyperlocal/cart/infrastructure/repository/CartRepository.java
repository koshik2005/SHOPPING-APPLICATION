package com.hyperlocal.cart.infrastructure.repository;

import com.hyperlocal.cart.infrastructure.entity.CartEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CartRepository extends JpaRepository<CartEntity, UUID> {
    Optional<CartEntity> findByCustomerId(UUID customerId);
}
