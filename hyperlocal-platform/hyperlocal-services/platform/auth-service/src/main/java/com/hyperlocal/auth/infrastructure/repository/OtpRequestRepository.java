package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.OtpRequestEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpRequestRepository extends JpaRepository<OtpRequestEntity, UUID> {
    Optional<OtpRequestEntity> findFirstByEmailOrPhoneAndVerifiedFalseAndExpiresAtAfterOrderByCreatedAtDesc(
        String emailOrPhone, Instant now
    );
}
