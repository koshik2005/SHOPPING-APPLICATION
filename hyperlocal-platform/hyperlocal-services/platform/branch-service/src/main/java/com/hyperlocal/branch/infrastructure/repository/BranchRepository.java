package com.hyperlocal.branch.infrastructure.repository;

import com.hyperlocal.branch.infrastructure.entity.BranchEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface BranchRepository extends JpaRepository<BranchEntity, UUID> {
    List<BranchEntity> findByIsActiveTrueAndDeletedFalse();
}
