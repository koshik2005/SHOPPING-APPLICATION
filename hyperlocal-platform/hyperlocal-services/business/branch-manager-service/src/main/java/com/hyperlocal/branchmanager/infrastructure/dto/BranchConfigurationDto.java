package com.hyperlocal.branchmanager.infrastructure.dto;

import lombok.Data;
import java.util.UUID;

@Data
public class BranchConfigurationDto {
    private UUID branchId;
    private String configKey;
    private String configValue;
}
