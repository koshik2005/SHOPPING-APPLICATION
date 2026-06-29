package com.hyperlocal.config.application.service;

import com.hyperlocal.config.infrastructure.entity.ConfigEntity;
import com.hyperlocal.config.infrastructure.repository.ConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ConfigService {
    private final ConfigRepository configRepository;

    @Transactional(readOnly = true)
    public String resolveValue(String key, String fallback) {
        return configRepository.findByConfigKey(key)
            .map(ConfigEntity::getConfigValue)
            .orElse(fallback);
    }
}
