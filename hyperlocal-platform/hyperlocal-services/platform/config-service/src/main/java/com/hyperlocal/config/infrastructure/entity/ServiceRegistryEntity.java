package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * Dynamic Service Registry v2 — replaces ALL hardcoded service lists.
 */
@Getter
@Setter
@Entity
@Table(name = "platform_services")
public class ServiceRegistryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "service_key", nullable = false, unique = true, length = 80)
    private String serviceKey;

    @Column(name = "display_name", nullable = false, length = 150)
    private String displayName;

    @Column(name = "description")
    private String description;

    @Column(name = "icon_url")
    private String iconUrl;

    @Column(name = "color_hex", length = 10)
    private String colorHex;

    @Column(name = "route_path", length = 255)
    private String routePath;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    @Column(name = "feature_flag_key", length = 100)
    private String featureFlagKey;

    @Column(columnDefinition = "jsonb")
    private String metadata = "{}";

    @Column(name = "theme_config", columnDefinition = "jsonb")
    private String themeConfig = "{}";

    @Column(name = "priority")
    private Integer priority = 1;

    @Column(name = "maintenance_mode")
    private boolean maintenanceMode = false;

    @Column(name = "supported_countries", columnDefinition = "jsonb")
    private String supportedCountries = "[]";

    @Column(name = "supported_cities", columnDefinition = "jsonb")
    private String supportedCities = "[]";

    @Column(name = "supported_vehicle_types", columnDefinition = "jsonb")
    private String supportedVehicleTypes = "[]";

    @Column(name = "supported_delivery_types", columnDefinition = "jsonb")
    private String supportedDeliveryTypes = "[]";

    @Column(name = "supported_product_schemas", columnDefinition = "jsonb")
    private String supportedProductSchemas = "[]";

    @Column(name = "supported_payment_methods", columnDefinition = "jsonb")
    private String supportedPaymentMethods = "[]";

    @Column(name = "supported_roles", columnDefinition = "jsonb")
    private String supportedRoles = "[]";

    @Column(name = "api_gateway_route")
    private String apiGatewayRoute;

    @Column(name = "microservice_name")
    private String microserviceName;

    @Column(name = "audit_enabled")
    private boolean auditEnabled = true;

    @Column(name = "security_level")
    private Integer securityLevel = 1;

    @Column(name = "version")
    private Integer version = 1;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
