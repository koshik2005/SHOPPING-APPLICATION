package com.hyperlocal.order.infrastructure.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;
import java.util.UUID;

@Data
public class CreateOrderRequest {
    @NotNull(message = "Branch ID is required")
    private UUID branchId;

    /**
     * Service domain for this order — determines which workflow applies.
     * Examples: "food", "grocery", "medicine", "rides", "courier"
     * MUST match a service_key in platform_services and workflow_step_definitions.
     */
    @NotBlank(message = "Service key is required")
    private String serviceKey;

    @NotNull(message = "Cart item variants must be provided")
    private List<OrderItemInput> items;

    @Data
    public static class OrderItemInput {
        private UUID productVariantId;
        private int quantity;
        private double price;
    }
}
