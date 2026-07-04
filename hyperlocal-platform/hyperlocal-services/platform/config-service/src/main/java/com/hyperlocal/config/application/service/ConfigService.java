package com.hyperlocal.config.application.service;

import com.hyperlocal.config.infrastructure.entity.*;
import com.hyperlocal.config.infrastructure.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ConfigService — The central hub for all platform configuration resolution.
 *
 * Resolution strategy for all "resolve*" methods:
 *   1. Branch-scoped override (if branchId supplied)
 *   2. Global default
 *   3. Supplied fallback
 *
 * No business logic is ever hardcoded in any other service.
 * Everything calls ConfigService or one of the engine services below.
 */
@Service
@RequiredArgsConstructor
public class ConfigService {

    private final ConfigRepository configRepository;
    private final ServiceRegistryRepository serviceRegistryRepository;
    private final NavigationMenuRepository navigationMenuRepository;
    private final FeatureFlagRepository featureFlagRepository;
    private final PricingRuleRepository pricingRuleRepository;
    private final BannerRepository bannerRepository;
    private final WorkflowStepRepository workflowStepRepository;
    private final LocalisationRepository localisationRepository;

    // ======================================================================
    // SYSTEM CONFIGURATION
    // ======================================================================

    @Transactional(readOnly = true)
    public String resolveValue(String key, String fallback) {
        return configRepository.findByConfigKey(key)
                .map(ConfigEntity::getConfigValue)
                .orElse(fallback);
    }

    @Transactional(readOnly = true)
    public String resolveForBranch(String key, UUID branchId, String fallback) {
        if (branchId != null) {
            List<ConfigEntity> resolved = configRepository.findByKeyWithBranchFallback(key, branchId);
            if (!resolved.isEmpty()) return resolved.get(0).getConfigValue();
        }
        return resolveValue(key, fallback);
    }

    @Transactional(readOnly = true)
    public boolean resolveAsBoolean(String key, boolean fallback) {
        return configRepository.findByConfigKey(key)
                .map(c -> "true".equalsIgnoreCase(c.getConfigValue()))
                .orElse(fallback);
    }

    @Transactional(readOnly = true)
    public BigDecimal resolveAsDecimal(String key, BigDecimal fallback) {
        return configRepository.findByConfigKey(key)
                .map(c -> new BigDecimal(c.getConfigValue()))
                .orElse(fallback);
    }

    @Transactional(readOnly = true)
    public int resolveAsInt(String key, int fallback) {
        return configRepository.findByConfigKey(key)
                .map(c -> Integer.parseInt(c.getConfigValue()))
                .orElse(fallback);
    }

    @Transactional(readOnly = true)
    public Map<String, String> resolveAllByCategory(String category) {
        return configRepository.findByCategoryAndScopeAndScopeIdIsNull(category, "GLOBAL")
                .stream()
                .collect(Collectors.toMap(
                        ConfigEntity::getConfigKey,
                        c -> c.isSensitive() ? "***" : c.getConfigValue()
                ));
    }

    @Transactional
    public ConfigEntity upsert(String key, String value, String category, String scope,
                               UUID scopeId, String dataType, UUID updatedBy) {
        ConfigEntity entity = configRepository
                .findByConfigKeyAndScopeAndScopeIdIsNull(key, scope)
                .orElseGet(ConfigEntity::new);
        entity.setConfigKey(key);
        entity.setConfigValue(value);
        entity.setCategory(category);
        entity.setScope(scope);
        entity.setScopeId(scopeId);
        entity.setDataType(dataType != null ? dataType : "STRING");
        entity.setUpdatedBy(updatedBy);
        entity.setUpdatedAt(Instant.now());
        return configRepository.save(entity);
    }

    // ======================================================================
    // SERVICE REGISTRY
    // ======================================================================

    @Transactional(readOnly = true)
    public List<ServiceRegistryEntity> getActiveServices() {
        return serviceRegistryRepository.findByActiveTrueOrderByDisplayOrderAsc();
    }

    @Transactional(readOnly = true)
    public Optional<ServiceRegistryEntity> getService(String serviceKey) {
        return serviceRegistryRepository.findByServiceKey(serviceKey);
    }

    @Transactional
    public ServiceRegistryEntity saveService(ServiceRegistryEntity entity) {
        entity.setUpdatedAt(Instant.now());
        return serviceRegistryRepository.save(entity);
    }

    @Transactional
    public void toggleService(String serviceKey, boolean active) {
        serviceRegistryRepository.findByServiceKey(serviceKey).ifPresent(s -> {
            s.setActive(active);
            s.setUpdatedAt(Instant.now());
            serviceRegistryRepository.save(s);
        });
    }

    // ======================================================================
    // NAVIGATION MENUS
    // ======================================================================

    @Transactional(readOnly = true)
    public List<NavigationMenuEntity> getNavigation(String portalTarget) {
        return navigationMenuRepository
                .findByPortalTargetAndActiveTrueOrderByDisplayOrderAsc(portalTarget);
    }

    @Transactional
    public NavigationMenuEntity saveNavigationItem(NavigationMenuEntity entity) {
        entity.setUpdatedAt(Instant.now());
        return navigationMenuRepository.save(entity);
    }

    // ======================================================================
    // FEATURE FLAGS
    // ======================================================================

    @Transactional(readOnly = true)
    public boolean isFeatureEnabled(String flagKey) {
        return featureFlagRepository.findByFlagKeyAndScope(flagKey, "GLOBAL")
                .map(FeatureFlagEntity::isEnabled)
                .orElse(false);
    }

    @Transactional(readOnly = true)
    public boolean isFeatureEnabledForBranch(String flagKey, UUID branchId) {
        // Branch override first
        return featureFlagRepository.findByFlagKeyAndScopeAndScopeId(flagKey, "BRANCH", branchId)
                .map(FeatureFlagEntity::isEnabled)
                .orElseGet(() -> isFeatureEnabled(flagKey));
    }

    @Transactional(readOnly = true)
    public List<FeatureFlagEntity> getAllFlags() {
        return featureFlagRepository.findAll();
    }

    @Transactional
    public void toggleFlag(String flagKey, String scope, UUID scopeId, boolean enabled, UUID updatedBy) {
        FeatureFlagEntity flag = featureFlagRepository
                .findByFlagKeyAndScopeAndScopeId(flagKey, scope, scopeId)
                .orElseGet(() -> {
                    FeatureFlagEntity f = new FeatureFlagEntity();
                    f.setFlagKey(flagKey);
                    f.setScope(scope);
                    f.setScopeId(scopeId);
                    return f;
                });
        flag.setEnabled(enabled);
        flag.setUpdatedBy(updatedBy);
        flag.setUpdatedAt(Instant.now());
        featureFlagRepository.save(flag);
    }

    // ======================================================================
    // PRICING ENGINE
    // ======================================================================

    /**
     * Resolves the most specific pricing rule for a given key.
     * Priority: branch+service > branch-global > service-global > global
     */
    @Transactional(readOnly = true)
    public Optional<BigDecimal> resolvePricingRule(String ruleKey, String serviceKey, UUID branchId) {
        List<PricingRuleEntity> rules = pricingRuleRepository
                .findByRuleKeyResolved(ruleKey, serviceKey, branchId);
        return rules.stream().findFirst().map(PricingRuleEntity::getValue);
    }

    @Transactional(readOnly = true)
    public BigDecimal resolvePricingRuleOrDefault(String ruleKey, String serviceKey,
                                                   UUID branchId, BigDecimal defaultValue) {
        return resolvePricingRule(ruleKey, serviceKey, branchId).orElse(defaultValue);
    }

    @Transactional
    public PricingRuleEntity savePricingRule(PricingRuleEntity rule) {
        rule.setUpdatedAt(Instant.now());
        return pricingRuleRepository.save(rule);
    }

    @Transactional(readOnly = true)
    public List<PricingRuleEntity> getAllGlobalPricingRules() {
        return pricingRuleRepository.findByBranchIdIsNullAndServiceKeyIsNullOrderByPriorityDesc();
    }

    @Transactional(readOnly = true)
    public List<PricingRuleEntity> getPricingRulesForBranch(UUID branchId) {
        return pricingRuleRepository.findByBranchIdOrderByPriorityDesc(branchId);
    }

    // ======================================================================
    // BANNERS
    // ======================================================================

    @Transactional(readOnly = true)
    public List<BannerEntity> getActiveBanners(UUID branchId) {
        return bannerRepository.findActiveBannersForBranch(branchId, Instant.now());
    }

    @Transactional
    public BannerEntity saveBanner(BannerEntity banner) {
        banner.setUpdatedAt(Instant.now());
        return bannerRepository.save(banner);
    }

    @Transactional
    public void deleteBanner(UUID bannerId) {
        bannerRepository.deleteById(bannerId);
    }

    // ======================================================================
    // WORKFLOW ENGINE
    // ======================================================================

    @Transactional(readOnly = true)
    public List<WorkflowStepEntity> getWorkflowSteps(String serviceKey) {
        return workflowStepRepository.findByServiceKeyOrderByDisplayOrderAsc(serviceKey);
    }

    @Transactional(readOnly = true)
    public Optional<WorkflowStepEntity> getInitialStep(String serviceKey) {
        return workflowStepRepository.findByServiceKeyAndInitialTrue(serviceKey);
    }

    @Transactional(readOnly = true)
    public String resolveInitialStepKey(String serviceKey) {
        return getInitialStep(serviceKey)
                .map(WorkflowStepEntity::getStepKey)
                .orElse("PENDING"); // Safe fallback if workflow not yet configured
    }

    /**
     * Validates that a transition from fromStatus → toStatus is allowed
     * for the given actor role, per the workflow definition.
     */
    @Transactional(readOnly = true)
    public boolean isValidTransition(String serviceKey, String fromStatus,
                                     String toStatus, String actorRole) {
        Optional<WorkflowStepEntity> fromStep =
                workflowStepRepository.findByServiceKeyAndStepKey(serviceKey, fromStatus);
        if (fromStep.isEmpty()) return false;

        String allowedNextJson = fromStep.get().getAllowedNextSteps();
        if (!allowedNextJson.contains("\"" + toStatus + "\"")) return false;

        // Check toStep's allowedRoles
        Optional<WorkflowStepEntity> toStep =
                workflowStepRepository.findByServiceKeyAndStepKey(serviceKey, toStatus);
        if (toStep.isEmpty()) return false;

        String rolesJson = toStep.get().getAllowedRoles();
        // If allowedRoles is empty array, anyone can transition
        return rolesJson.equals("[]") || rolesJson.contains("\"" + actorRole + "\"");
    }

    // ======================================================================
    // LOCALISATION (i18n)
    // ======================================================================

    @Transactional(readOnly = true)
    public String getString(String key, String locale, String fallback) {
        return localisationRepository.findByStringKeyAndLocale(key, locale)
                .map(LocalisationEntity::getValue)
                .orElseGet(() ->
                    // Fallback to English if requested locale not found
                    localisationRepository.findByStringKeyAndLocale(key, "en")
                            .map(LocalisationEntity::getValue)
                            .orElse(fallback)
                );
    }

    @Transactional(readOnly = true)
    public Map<String, String> getAllStrings(String locale) {
        return localisationRepository.findByLocaleOrderByStringKeyAsc(locale)
                .stream()
                .collect(Collectors.toMap(
                        LocalisationEntity::getStringKey,
                        LocalisationEntity::getValue
                ));
    }

    @Transactional
    public LocalisationEntity upsertString(String key, String locale, String value, UUID updatedBy) {
        LocalisationEntity entity = localisationRepository
                .findByStringKeyAndLocale(key, locale)
                .orElseGet(LocalisationEntity::new);
        entity.setStringKey(key);
        entity.setLocale(locale);
        entity.setValue(value);
        entity.setUpdatedBy(updatedBy);
        entity.setLastUpdated(Instant.now());
        return localisationRepository.save(entity);
    }
}
