package com.hyperlocal.audit.infrastructure.repository;

import com.hyperlocal.audit.infrastructure.entity.AuditLogEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLogEntity, UUID> {
}
