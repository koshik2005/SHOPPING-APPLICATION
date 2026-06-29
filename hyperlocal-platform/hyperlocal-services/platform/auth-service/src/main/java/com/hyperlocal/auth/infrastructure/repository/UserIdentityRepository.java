package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.AuthEntities.UserIdentityEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;
import java.util.List;

@Repository
public interface UserIdentityRepository extends JpaRepository<UserIdentityEntity, UUID> {
    Optional<UserIdentityEntity> findByProviderAndProviderUserId(String provider, String providerUserId);
    List<UserIdentityEntity> findByUserId(UUID userId);
    Optional<UserIdentityEntity> findByEmail(String email);
}
