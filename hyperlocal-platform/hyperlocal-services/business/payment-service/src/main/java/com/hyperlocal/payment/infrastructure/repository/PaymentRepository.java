package com.hyperlocal.payment.infrastructure.repository;

import com.hyperlocal.payment.infrastructure.entity.PaymentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PaymentRepository extends JpaRepository<PaymentEntity, UUID> {
    Optional<PaymentEntity> findByOrderId(UUID orderId);
    Optional<PaymentEntity> findByGatewayReference(String ref);
}
