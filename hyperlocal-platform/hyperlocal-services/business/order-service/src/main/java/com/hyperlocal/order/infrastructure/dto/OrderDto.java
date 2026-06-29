package com.hyperlocal.order.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class OrderDto {
    private UUID id;
    private UUID customerId;
    private UUID branchId;
    private String status;
    private double totalPrice;
}
