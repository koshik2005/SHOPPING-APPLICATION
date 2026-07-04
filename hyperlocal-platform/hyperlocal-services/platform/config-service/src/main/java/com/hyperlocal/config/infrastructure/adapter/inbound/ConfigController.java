package com.hyperlocal.config.infrastructure.adapter.inbound;

import com.hyperlocal.config.application.service.ConfigService;
import com.hyperlocal.config.infrastructure.entity.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.*;

/**
 * ConfigController — exposes all dynamic configuration APIs consumed by
 * Flutter Customer App, Delivery App, and Enterprise Portal.
 *
 * No endpoint contains hardcoded data. All values come from ConfigService → DB.
 */
@RestController
@RequestMapping("/api/v1/config")
@RequiredArgsConstructor
public class ConfigController {

    private final ConfigService configService;

    // ------------------------------------------------------------------
    // SERVICE REGISTRY
    // ------------------------------------------------------------------

    /** Flutter: load home screen service grid dynamically */
    @GetMapping("/services")
    public ResponseEntity<Map<String, Object>> getServices() {
        List<ServiceRegistryEntity> services = configService.getActiveServices();
        return ok(Map.of("services", services));
    }

    @PostMapping("/services")
    public ResponseEntity<Map<String, Object>> createService(
            @RequestBody ServiceRegistryEntity entity) {
        ServiceRegistryEntity saved = configService.saveService(entity);
        return ok(Map.of("service", saved));
    }

    @PutMapping("/services/{serviceKey}")
    public ResponseEntity<Map<String, Object>> updateService(
            @PathVariable String serviceKey,
            @RequestBody ServiceRegistryEntity entity) {
        entity.setServiceKey(serviceKey);
        return ok(Map.of("service", configService.saveService(entity)));
    }

    @PatchMapping("/services/{serviceKey}/toggle")
    public ResponseEntity<Map<String, Object>> toggleService(
            @PathVariable String serviceKey,
            @RequestParam boolean active) {
        configService.toggleService(serviceKey, active);
        return ok(Map.of("message", "Service " + serviceKey + " is now " + (active ? "enabled" : "disabled")));
    }

    // ------------------------------------------------------------------
    // NAVIGATION MENUS
    // ------------------------------------------------------------------

    /** Portal: load sidebar navigation dynamically */
    @GetMapping("/navigation")
    public ResponseEntity<Map<String, Object>> getNavigation(
            @RequestParam(defaultValue = "ENTERPRISE") String portal) {
        List<NavigationMenuEntity> menus = configService.getNavigation(portal);
        return ok(Map.of("navigation", menus));
    }

    @PostMapping("/navigation")
    public ResponseEntity<Map<String, Object>> createNavItem(
            @RequestBody NavigationMenuEntity entity) {
        return ok(Map.of("item", configService.saveNavigationItem(entity)));
    }

    @PutMapping("/navigation/{menuKey}")
    public ResponseEntity<Map<String, Object>> updateNavItem(
            @PathVariable String menuKey,
            @RequestBody NavigationMenuEntity entity) {
        entity.setMenuKey(menuKey);
        return ok(Map.of("item", configService.saveNavigationItem(entity)));
    }

    // ------------------------------------------------------------------
    // FEATURE FLAGS
    // ------------------------------------------------------------------

    /** Flutter + Portal: check if a feature is available */
    @GetMapping("/features")
    public ResponseEntity<Map<String, Object>> getAllFlags() {
        return ok(Map.of("flags", configService.getAllFlags()));
    }

    @GetMapping("/features/{flagKey}")
    public ResponseEntity<Map<String, Object>> getFlag(
            @PathVariable String flagKey,
            @RequestParam(required = false) UUID branchId) {
        boolean enabled = branchId != null
                ? configService.isFeatureEnabledForBranch(flagKey, branchId)
                : configService.isFeatureEnabled(flagKey);
        return ok(Map.of("flagKey", flagKey, "enabled", enabled));
    }

    @PostMapping("/features/toggle")
    public ResponseEntity<Map<String, Object>> toggleFlag(
            @RequestBody Map<String, Object> body) {
        String flagKey = (String) body.get("flagKey");
        String scope = (String) body.getOrDefault("scope", "GLOBAL");
        UUID scopeId = body.get("scopeId") != null ? UUID.fromString(body.get("scopeId").toString()) : null;
        boolean enabled = Boolean.parseBoolean(body.getOrDefault("enabled", "false").toString());
        UUID updatedBy = body.get("updatedBy") != null ? UUID.fromString(body.get("updatedBy").toString()) : null;
        configService.toggleFlag(flagKey, scope, scopeId, enabled, updatedBy);
        return ok(Map.of("message", "Feature flag updated"));
    }

    // ------------------------------------------------------------------
    // PRICING ENGINE
    // ------------------------------------------------------------------

    /** All pricing rules (admin view) */
    @GetMapping("/pricing")
    public ResponseEntity<Map<String, Object>> getAllPricingRules(
            @RequestParam(required = false) UUID branchId) {
        List<PricingRuleEntity> rules = branchId != null
                ? configService.getPricingRulesForBranch(branchId)
                : configService.getAllGlobalPricingRules();
        return ok(Map.of("rules", rules));
    }

    /** Resolve a specific rule for a branch + service */
    @GetMapping("/pricing/resolve")
    public ResponseEntity<Map<String, Object>> resolveRule(
            @RequestParam String ruleKey,
            @RequestParam(required = false) String serviceKey,
            @RequestParam(required = false) UUID branchId) {
        BigDecimal value = configService.resolvePricingRuleOrDefault(
                ruleKey, serviceKey, branchId, BigDecimal.ZERO);
        return ok(Map.of("ruleKey", ruleKey, "value", value));
    }

    @PostMapping("/pricing")
    public ResponseEntity<Map<String, Object>> savePricingRule(
            @RequestBody PricingRuleEntity rule) {
        return ok(Map.of("rule", configService.savePricingRule(rule)));
    }

    // ------------------------------------------------------------------
    // BANNERS
    // ------------------------------------------------------------------

    /** Flutter: load home screen banners for a branch */
    @GetMapping("/banners")
    public ResponseEntity<Map<String, Object>> getBanners(
            @RequestParam(required = false) UUID branchId) {
        return ok(Map.of("banners", configService.getActiveBanners(branchId)));
    }

    @PostMapping("/banners")
    public ResponseEntity<Map<String, Object>> createBanner(
            @RequestBody BannerEntity banner) {
        return ok(Map.of("banner", configService.saveBanner(banner)));
    }

    @PutMapping("/banners/{id}")
    public ResponseEntity<Map<String, Object>> updateBanner(
            @PathVariable UUID id, @RequestBody BannerEntity banner) {
        banner.setId(id);
        return ok(Map.of("banner", configService.saveBanner(banner)));
    }

    @DeleteMapping("/banners/{id}")
    public ResponseEntity<Map<String, Object>> deleteBanner(@PathVariable UUID id) {
        configService.deleteBanner(id);
        return ok(Map.of("message", "Banner deleted"));
    }

    // ------------------------------------------------------------------
    // WORKFLOW ENGINE
    // ------------------------------------------------------------------

    /** Get all workflow steps for a service type */
    @GetMapping("/workflow")
    public ResponseEntity<Map<String, Object>> getWorkflow(
            @RequestParam String serviceKey) {
        return ok(Map.of("steps", configService.getWorkflowSteps(serviceKey)));
    }

    /** Validate a status transition */
    @GetMapping("/workflow/validate-transition")
    public ResponseEntity<Map<String, Object>> validateTransition(
            @RequestParam String serviceKey,
            @RequestParam String fromStatus,
            @RequestParam String toStatus,
            @RequestParam String actorRole) {
        boolean valid = configService.isValidTransition(serviceKey, fromStatus, toStatus, actorRole);
        return ok(Map.of("valid", valid, "fromStatus", fromStatus, "toStatus", toStatus));
    }

    // ------------------------------------------------------------------
    // SYSTEM CONFIGURATION (Key-Value Store)
    // ------------------------------------------------------------------

    @GetMapping("/system")
    public ResponseEntity<Map<String, Object>> getSystemConfig(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) UUID branchId) {
        Map<String, String> config = category != null
                ? configService.resolveAllByCategory(category)
                : configService.resolveAllByCategory("GLOBAL");
        return ok(Map.of("config", config, "category", category != null ? category : "GLOBAL"));
    }

    @PostMapping("/system")
    public ResponseEntity<Map<String, Object>> upsertSystemConfig(
            @RequestBody Map<String, Object> body) {
        String key = (String) body.get("key");
        String value = (String) body.get("value");
        String category = (String) body.getOrDefault("category", "GLOBAL");
        String scope = (String) body.getOrDefault("scope", "GLOBAL");
        String dataType = (String) body.getOrDefault("dataType", "STRING");
        UUID scopeId = body.get("scopeId") != null ? UUID.fromString(body.get("scopeId").toString()) : null;
        UUID updatedBy = body.get("updatedBy") != null ? UUID.fromString(body.get("updatedBy").toString()) : null;
        ConfigEntity saved = configService.upsert(key, value, category, scope, scopeId, dataType, updatedBy);
        return ok(Map.of("config", saved));
    }

    // ------------------------------------------------------------------
    // LOCALISATION (i18n)
    // ------------------------------------------------------------------

    /** Flutter: fetch all i18n strings for a locale (bulk load at startup) */
    @GetMapping("/i18n")
    public ResponseEntity<Map<String, Object>> getAllStrings(
            @RequestParam(defaultValue = "en") String locale) {
        return ok(Map.of("locale", locale, "strings", configService.getAllStrings(locale)));
    }

    /** Resolve a single string (used for specific key lookups) */
    @GetMapping("/i18n/{key}")
    public ResponseEntity<Map<String, Object>> getString(
            @PathVariable String key,
            @RequestParam(defaultValue = "en") String locale) {
        String value = configService.getString(key, locale, key);
        return ok(Map.of("key", key, "locale", locale, "value", value));
    }

    @PostMapping("/i18n")
    public ResponseEntity<Map<String, Object>> upsertString(
            @RequestBody Map<String, Object> body) {
        String key = (String) body.get("key");
        String locale = (String) body.getOrDefault("locale", "en");
        String value = (String) body.get("value");
        UUID updatedBy = body.get("updatedBy") != null ? UUID.fromString(body.get("updatedBy").toString()) : null;
        return ok(Map.of("string", configService.upsertString(key, locale, value, updatedBy)));
    }

    // ------------------------------------------------------------------
    // HELPER
    // ------------------------------------------------------------------
    private ResponseEntity<Map<String, Object>> ok(Map<String, Object> data) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("success", true);
        response.put("data", data);
        return ResponseEntity.ok(response);
    }
}
