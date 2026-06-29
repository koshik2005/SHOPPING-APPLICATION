package com.hyperlocal.payment.infrastructure.repository;

import com.hyperlocal.payment.infrastructure.entity.RefundEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefundRepository extends JpaRepository<RefundEntity, UUID> {
    Optional<RefundEntity> findByRefundRef(String ref);
}
