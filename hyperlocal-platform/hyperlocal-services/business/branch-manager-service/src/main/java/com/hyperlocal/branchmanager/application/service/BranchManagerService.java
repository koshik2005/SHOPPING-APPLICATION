package com.hyperlocal.branchmanager.application.service;

import com.hyperlocal.branchmanager.infrastructure.entity.*;
import com.hyperlocal.branchmanager.infrastructure.repository.*;
import com.hyperlocal.branchmanager.infrastructure.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BranchManagerService {
    private final BranchManagerConfigRepository configRepository;

    @Transactional(readOnly = true)
    public BranchDashboardDto getDashboardMetrics(UUID branchId) {
        return BranchDashboardDto.builder()
            .branchId(branchId)
            .activeOrdersCount(15)
            .pendingOrdersCount(4)
            .totalSalesToday(1245.50)
            .activeShopsCount(8)
            .onlinePartnersCount(5)
            .build();
    }

    @Transactional
    public void updateBranchConfig(BranchConfigurationDto dto) {
        BranchManagerConfigEntity entity = new BranchManagerConfigEntity();
        entity.setBranchId(dto.getBranchId());
        entity.setConfigKey(dto.getConfigKey());
        entity.setConfigValue(dto.getConfigValue());
        configRepository.save(entity);
    }
}
