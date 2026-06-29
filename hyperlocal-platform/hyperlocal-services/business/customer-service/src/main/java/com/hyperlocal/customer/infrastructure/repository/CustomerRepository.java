package com.hyperlocal.customer.infrastructure.repository;

import com.hyperlocal.customer.infrastructure.entity.CustomerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerRepository extends JpaRepository<CustomerEntity, UUID> {
    Optional<CustomerEntity> findByUserIdAndDeletedFalse(UUID userId);
}
