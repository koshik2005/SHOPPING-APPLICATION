package com.hyperlocal.audit.application.service;

import com.hyperlocal.audit.infrastructure.entity.AuditLogEntity;
import com.hyperlocal.audit.infrastructure.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuditLogService {
    private final AuditLogRepository auditLogRepository;

    @Transactional
    public void recordAudit(AuditLogEntity log) {
        auditLogRepository.save(log);
    }
}
