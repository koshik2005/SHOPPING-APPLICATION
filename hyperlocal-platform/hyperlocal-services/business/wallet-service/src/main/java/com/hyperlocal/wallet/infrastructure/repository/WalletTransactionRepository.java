package com.hyperlocal.wallet.infrastructure.repository;

import com.hyperlocal.wallet.infrastructure.entity.WalletTransactionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface WalletTransactionRepository extends JpaRepository<WalletTransactionEntity, UUID> {
    List<WalletTransactionEntity> findByWalletIdOrderByCreatedAtDesc(UUID walletId);
}
