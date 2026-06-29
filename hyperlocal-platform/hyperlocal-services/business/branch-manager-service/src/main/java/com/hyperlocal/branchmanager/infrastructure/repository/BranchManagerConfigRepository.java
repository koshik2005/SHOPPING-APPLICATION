package com.hyperlocal.branchmanager.infrastructure.repository;

import com.hyperlocal.branchmanager.infrastructure.entity.BranchManagerConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface BranchManagerConfigRepository extends JpaRepository<BranchManagerConfigEntity, UUID> {
    List<BranchManagerConfigEntity> findByBranchId(UUID branchId);
}
