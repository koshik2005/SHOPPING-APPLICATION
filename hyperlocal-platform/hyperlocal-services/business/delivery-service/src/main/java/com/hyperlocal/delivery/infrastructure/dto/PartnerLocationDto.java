package com.hyperlocal.delivery.infrastructure.dto;

import lombok.Data;

@Data
public class PartnerLocationDto {
    private double latitude;
    private double longitude;
    private double bearing;
    private double speed;
}
