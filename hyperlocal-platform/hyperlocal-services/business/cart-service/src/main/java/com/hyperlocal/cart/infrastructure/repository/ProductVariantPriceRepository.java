package com.hyperlocal.cart.infrastructure.repository;

import com.hyperlocal.cart.infrastructure.entity.ProductVariantPriceProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ProductVariantPriceRepository
        extends JpaRepository<ProductVariantPriceProjection, UUID> {
}
