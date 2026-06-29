package com.hyperlocal.core.domain;

import java.math.BigDecimal;
import lombok.Value;

@Value
public class Money {
    BigDecimal amount;
    String currency;

    public Money(BigDecimal amount, String currency) {
        if (amount == null) {
            throw new IllegalArgumentException("Amount cannot be null");
        }
        if (currency == null || currency.trim().isEmpty()) {
            throw new IllegalArgumentException("Currency cannot be empty");
        }
        this.amount = amount;
        this.currency = currency;
    }
}
