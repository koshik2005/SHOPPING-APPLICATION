package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.WorkflowStepEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WorkflowStepRepository extends JpaRepository<WorkflowStepEntity, UUID> {
    List<WorkflowStepEntity> findByServiceKeyOrderByDisplayOrderAsc(String serviceKey);
    Optional<WorkflowStepEntity> findByServiceKeyAndStepKey(String serviceKey, String stepKey);
    Optional<WorkflowStepEntity> findByServiceKeyAndInitialTrue(String serviceKey);
}
