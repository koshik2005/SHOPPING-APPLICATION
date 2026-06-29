package com.hyperlocal.wallet.infrastructure.adapter.inbound;

import com.hyperlocal.wallet.application.service.WalletService;
import com.hyperlocal.wallet.infrastructure.dto.*;
import com.hyperlocal.core.domain.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/wallets")
@RequiredArgsConstructor
public class WalletController {
    private final WalletService walletService;

    @GetMapping("/balance")
    public ResponseEntity<ApiResponse<WalletDto>> getBalance(@RequestHeader("X-User-ID") String userId) {
        WalletDto response = walletService.getWalletByCustomer(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }

    @PostMapping("/credit")
    public ResponseEntity<ApiResponse<String>> credit(
            @RequestHeader("X-User-ID") String userId,
            @Valid @RequestBody CreditDebitRequest request) {
        walletService.creditWallet(UUID.fromString(userId), request.getAmount(), request.getReferenceId());
        return ResponseEntity.ok(ApiResponse.ok("Wallet successfully credited", UUID.randomUUID().toString()));
    }

    @PostMapping("/debit")
    public ResponseEntity<ApiResponse<String>> debit(
            @RequestHeader("X-User-ID") String userId,
            @Valid @RequestBody CreditDebitRequest request) {
        walletService.debitWallet(UUID.fromString(userId), request.getAmount(), request.getReferenceId());
        return ResponseEntity.ok(ApiResponse.ok("Wallet successfully debited", UUID.randomUUID().toString()));
    }

    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<List<WalletTransactionDto>>> getTransactions(@RequestHeader("X-User-ID") String userId) {
        List<WalletTransactionDto> response = walletService.getTransactions(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(response, UUID.randomUUID().toString()));
    }
}
