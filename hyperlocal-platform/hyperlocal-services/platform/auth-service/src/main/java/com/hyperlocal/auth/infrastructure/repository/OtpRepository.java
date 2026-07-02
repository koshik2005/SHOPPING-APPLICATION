package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.OtpEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.UUID;
import java.util.List;

public interface OtpRepository extends JpaRepository<OtpEntity, UUID> {
    @Query("SELECT o FROM OtpEntity o WHERE o.emailOrPhone = :emailOrPhone AND o.otpCode = :otpCode AND o.used = false ORDER BY o.createdAt DESC")
    List<OtpEntity> findValidOtps(
        @Param("emailOrPhone") String emailOrPhone, 
        @Param("otpCode") String otpCode
    );

    default Optional<OtpEntity> findFirstByEmailOrPhoneAndOtpCodeAndUsedFalseOrderByCreatedAtDesc(String emailOrPhone, String otpCode) {
        return findValidOtps(emailOrPhone, otpCode).stream().findFirst();
    }
}
