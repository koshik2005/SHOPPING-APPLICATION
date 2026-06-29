package com.hyperlocal.payment.infrastructure.repository;

import com.hyperlocal.payment.infrastructure.entity.PaymentAttemptEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PaymentAttemptRepository extends JpaRepository<PaymentAttemptEntity, UUID> {
    Optional<PaymentAttemptEntity> findByGatewayRef(String ref);
}
