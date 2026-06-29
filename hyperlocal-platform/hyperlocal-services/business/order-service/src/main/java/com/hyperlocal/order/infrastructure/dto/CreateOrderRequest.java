package com.hyperlocal.order.infrastructure.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;
import java.util.UUID;

@Data
public class CreateOrderRequest {
    @NotNull(message = "Branch ID is required")
    private UUID branchId;
    
    @NotNull(message = "Cart item variants must be provided")
    private List<OrderItemInput> items;

    @Data
    public static class OrderItemInput {
        private UUID productVariantId;
        private int quantity;
        private double price;
    }
}
