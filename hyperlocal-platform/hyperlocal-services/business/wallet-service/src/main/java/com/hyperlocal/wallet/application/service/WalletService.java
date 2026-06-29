package com.hyperlocal.wallet.application.service;

import com.hyperlocal.wallet.infrastructure.entity.*;
import com.hyperlocal.wallet.infrastructure.repository.*;
import com.hyperlocal.wallet.infrastructure.dto.*;
import com.hyperlocal.common.exception.BusinessException;
import com.hyperlocal.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WalletService {
    private final WalletRepository walletRepository;
    private final WalletTransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public WalletDto getWalletByCustomer(UUID customerId) {
        WalletEntity wallet = walletRepository.findByCustomerId(customerId)
            .orElseGet(() -> {
                WalletEntity newWallet = new WalletEntity();
                newWallet.setCustomerId(customerId);
                newWallet.setBalance(0.00);
                return walletRepository.save(newWallet);
            });

        return WalletDto.builder()
            .id(wallet.getId())
            .customerId(wallet.getCustomerId())
            .balance(wallet.getBalance())
            .build();
    }

    @Transactional
    public void creditWallet(UUID customerId, double amount, UUID refId) {
        WalletEntity wallet = walletRepository.findByCustomerId(customerId)
            .orElseGet(() -> {
                WalletEntity newWallet = new WalletEntity();
                newWallet.setCustomerId(customerId);
                return walletRepository.save(newWallet);
            });

        wallet.setBalance(wallet.getBalance() + amount);
        walletRepository.save(wallet);

        recordTransaction(wallet.getId(), amount, "CREDIT", refId);
    }

    @Transactional
    public void debitWallet(UUID customerId, double amount, UUID refId) {
        WalletEntity wallet = walletRepository.findByCustomerId(customerId)
            .orElseThrow(() -> new ResourceNotFoundException("Wallet not found", "WALLET_NOT_FOUND"));

        if (wallet.getBalance() < amount) {
            throw new BusinessException("Insufficient wallet balance", "INSUFFICIENT_FUNDS");
        }

        wallet.setBalance(wallet.getBalance() - amount);
        walletRepository.save(wallet);

        recordTransaction(wallet.getId(), amount, "DEBIT", refId);
    }

    @Transactional(readOnly = true)
    public List<WalletTransactionDto> getTransactions(UUID customerId) {
        WalletEntity wallet = walletRepository.findByCustomerId(customerId)
            .orElseThrow(() -> new ResourceNotFoundException("Wallet not found", "WALLET_NOT_FOUND"));

        return transactionRepository.findByWalletIdOrderByCreatedAtDesc(wallet.getId()).stream()
            .map(t -> WalletTransactionDto.builder()
                .id(t.getId())
                .amount(t.getAmount())
                .type(t.getType())
                .referenceId(t.getReferenceId())
                .createdAt(t.getCreatedAt())
                .build())
            .collect(Collectors.toList());
    }

    private void recordTransaction(UUID walletId, double amount, String type, UUID refId) {
        WalletTransactionEntity transaction = new WalletTransactionEntity();
        transaction.setWalletId(walletId);
        transaction.setAmount(amount);
        transaction.setType(type);
        transaction.setReferenceId(refId);
        transactionRepository.save(transaction);
    }
}
