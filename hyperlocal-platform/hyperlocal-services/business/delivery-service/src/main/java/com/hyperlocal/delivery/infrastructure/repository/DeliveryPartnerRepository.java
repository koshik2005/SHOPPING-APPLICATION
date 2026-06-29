package com.hyperlocal.delivery.infrastructure.repository;

import com.hyperlocal.delivery.infrastructure.entity.DeliveryPartnerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeliveryPartnerRepository extends JpaRepository<DeliveryPartnerEntity, UUID> {
    Optional<DeliveryPartnerEntity> findByUserId(UUID userId);
}
