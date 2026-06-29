package com.hyperlocal.inventory.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class ProductDto {
    private UUID id;
    private UUID shopId;
    private UUID categoryId;
    private String name;
    private String description;
}
