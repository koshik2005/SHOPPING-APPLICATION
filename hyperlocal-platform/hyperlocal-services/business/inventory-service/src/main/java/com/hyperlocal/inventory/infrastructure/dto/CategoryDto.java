package com.hyperlocal.inventory.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class CategoryDto {
    private UUID id;
    private String name;
    private String iconUrl;
    /** Which service this category belongs to */
    private String serviceKey;
    private UUID parentCategoryId;
    private int displayOrder;
    private String colorHex;
    private boolean active;
}
