package com.hyperlocal.customer.infrastructure.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class CustomerProfileDto {
    private UUID id;
    private UUID userId;
    private String displayName;
    private String profilePhotoUrl;
    private double rating;
}
