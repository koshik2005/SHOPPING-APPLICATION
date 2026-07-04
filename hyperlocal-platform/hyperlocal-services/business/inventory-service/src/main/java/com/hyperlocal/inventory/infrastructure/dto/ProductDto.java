package com.hyperlocal.inventory.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
public class ProductDto {
    private UUID id;
    private UUID shopId;
    private UUID categoryId;
    /** Service domain this product belongs to */
    private String serviceKey;
    private String name;
    private String description;
    /** Dynamic attribute values: key → value (used for create/update) */
    private Map<String, String> attributes;
}
