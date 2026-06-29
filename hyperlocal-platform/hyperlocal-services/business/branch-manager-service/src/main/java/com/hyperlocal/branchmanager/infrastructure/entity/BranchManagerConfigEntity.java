package com.hyperlocal.branchmanager.infrastructure.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "branch_configuration")
public class BranchManagerConfigEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "config_key", nullable = false)
    private String configKey;

    @Column(name = "config_value", nullable = false)
    private String configValue;
}
