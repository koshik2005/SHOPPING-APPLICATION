package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.OtpEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface OtpRepository extends JpaRepository<OtpEntity, UUID> {
    Optional<OtpEntity> findFirstByEmailOrPhoneAndOtpCodeAndUsedFalseOrderByCreatedAtDesc(String emailOrPhone, String otpCode);
}
