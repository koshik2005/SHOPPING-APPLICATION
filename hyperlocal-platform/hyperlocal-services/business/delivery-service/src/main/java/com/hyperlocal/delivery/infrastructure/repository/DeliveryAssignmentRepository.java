package com.hyperlocal.delivery.infrastructure.repository;

import com.hyperlocal.delivery.infrastructure.entity.DeliveryAssignmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeliveryAssignmentRepository extends JpaRepository<DeliveryAssignmentEntity, UUID> {
    Optional<DeliveryAssignmentEntity> findByOrderId(UUID orderId);
}
