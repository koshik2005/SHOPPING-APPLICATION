package com.hyperlocal.branch.application.service;

import com.hyperlocal.branch.infrastructure.entity.BranchEntity;
import com.hyperlocal.branch.infrastructure.repository.BranchRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BranchService {
    private final BranchRepository branchRepository;

    @Transactional(readOnly = true)
    public List<BranchEntity> getActiveBranches() {
        return branchRepository.findByIsActiveTrueAndDeletedFalse();
    }
}
