package com.hyperlocal.delivery.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "delivery_partners")
public class DeliveryPartnerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(nullable = false)
    private String name;

    @Column(name = "status", nullable = false)
    private String status = "OFFLINE"; // e.g. OFFLINE, AVAILABLE, BUSY

    @Column(name = "vehicle_type")
    private String vehicleType;

    @Column(nullable = false)
    private double rating = 5.00;
}
