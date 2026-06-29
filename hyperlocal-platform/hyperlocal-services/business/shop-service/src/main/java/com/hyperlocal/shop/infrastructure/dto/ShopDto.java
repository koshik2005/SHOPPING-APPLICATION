package com.hyperlocal.shop.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class ShopDto {
    private UUID id;
    private UUID branchId;
    private String name;
    private boolean isOpen;
}
