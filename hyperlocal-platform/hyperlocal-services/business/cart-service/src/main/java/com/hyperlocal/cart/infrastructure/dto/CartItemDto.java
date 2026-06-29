package com.hyperlocal.cart.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class CartItemDto {
    private UUID id;
    private UUID productVariantId;
    private int quantity;
    private double unitPrice;
}
