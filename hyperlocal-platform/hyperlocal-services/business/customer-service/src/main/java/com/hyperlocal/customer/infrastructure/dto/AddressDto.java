package com.hyperlocal.customer.infrastructure.dto;

import lombok.Data;
import java.util.UUID;

@Data
public class AddressDto {
    private UUID id;
    private String label;
    private String streetAddress;
    private double latitude;
    private double longitude;
    private boolean isDefault;
}
