package com.hyperlocal.config.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "system_configuration")
public class ConfigEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "config_key", nullable = false, unique = true)
    private String configKey;

    @Column(name = "config_value", nullable = false)
    private String configValue;

    @Column(nullable = false)
    private String category = "GLOBAL";
}
