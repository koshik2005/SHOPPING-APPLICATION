package com.hyperlocal.wallet.infrastructure.repository;

import com.hyperlocal.wallet.infrastructure.entity.WalletHoldEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface WalletHoldRepository extends JpaRepository<WalletHoldEntity, UUID> {
}
