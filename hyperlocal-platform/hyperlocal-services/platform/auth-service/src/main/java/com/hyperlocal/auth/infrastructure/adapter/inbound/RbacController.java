package com.hyperlocal.auth.infrastructure.adapter.inbound;

import com.hyperlocal.auth.application.service.RbacService;
import com.hyperlocal.auth.infrastructure.entity.PermissionDefinitionEntity;
import com.hyperlocal.auth.infrastructure.entity.RolePermissionMappingEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * RbacController — exposes the dynamic RBAC API consumed by
 * Enterprise Portal's AuthContext and RBAC management page.
 *
 * The Portal's `can(permission)` function now calls this API
 * instead of reading a hardcoded ROLE_PERMISSIONS constant.
 */
@RestController
@RequestMapping("/api/v1/auth/rbac")
@RequiredArgsConstructor
public class RbacController {

    private final RbacService rbacService;

    // ------------------------------------------------------------------
    // PERMISSION QUERIES (consumed by Portal AuthContext)
    // ------------------------------------------------------------------

    /**
     * Returns all permissions for a given role.
     * Portal calls: GET /api/v1/auth/rbac/permissions?role=ROLE_BRANCH_MANAGER
     * Response: { "data": { "role": "ROLE_BRANCH_MANAGER", "permissions": ["dashboard:view", ...] } }
     */
    @GetMapping("/permissions")
    public ResponseEntity<Map<String, Object>> getPermissionsForRole(
            @RequestParam String role) {
        List<String> permissions = rbacService.getPermissionsForRole(role);
        return ok(Map.of("role", role, "permissions", permissions));
    }

    /**
     * Returns permissions for multiple roles (compound user context).
     * Portal calls: GET /api/v1/auth/rbac/permissions/multi?roles=ROLE_A,ROLE_B
     */
    @GetMapping("/permissions/multi")
    public ResponseEntity<Map<String, Object>> getPermissionsForRoles(
            @RequestParam List<String> roles) {
        Set<String> permissions = rbacService.getPermissionsForRoles(roles);
        return ok(Map.of("roles", roles, "permissions", permissions));
    }

    /**
     * Returns the complete RBAC matrix (for Portal RBAC management page).
     */
    @GetMapping("/matrix")
    public ResponseEntity<Map<String, Object>> getRbacMatrix() {
        return ok(Map.of("matrix", rbacService.getRbacMatrix()));
    }

    /**
     * Returns all available roles with their permission counts.
     */
    @GetMapping("/roles")
    public ResponseEntity<Map<String, Object>> getAllRoles() {
        Map<String, List<String>> matrix = rbacService.getRbacMatrix();
        List<Map<String, Object>> roles = new ArrayList<>();
        matrix.forEach((roleName, perms) -> {
            roles.add(Map.of(
                    "roleName", roleName,
                    "permissionCount", perms.size(),
                    "permissions", perms
            ));
        });
        return ok(Map.of("roles", roles));
    }

    // ------------------------------------------------------------------
    // PERMISSION CATALOG
    // ------------------------------------------------------------------

    @GetMapping("/catalog")
    public ResponseEntity<Map<String, Object>> getPermissionCatalog(
            @RequestParam(required = false) String category) {
        var permissions = category != null
                ? rbacService.getPermissionsByCategory(category)
                : rbacService.getAllPermissions();
        return ok(Map.of("permissions", permissions));
    }

    @PostMapping("/catalog")
    public ResponseEntity<Map<String, Object>> createPermission(
            @RequestBody PermissionDefinitionEntity entity) {
        return ok(Map.of("permission", rbacService.createPermission(entity)));
    }

    // ------------------------------------------------------------------
    // ROLE → PERMISSION ASSIGNMENT
    // ------------------------------------------------------------------

    /**
     * Grants a permission to a role.
     * POST /api/v1/auth/rbac/roles/{roleName}/permissions/{permKey}
     */
    @PostMapping("/roles/{roleName}/permissions/{permissionKey}")
    public ResponseEntity<Map<String, Object>> grantPermission(
            @PathVariable String roleName,
            @PathVariable String permissionKey,
            @RequestBody(required = false) Map<String, Object> body) {
        UUID grantedBy = (body != null && body.get("grantedBy") != null)
                ? UUID.fromString(body.get("grantedBy").toString())
                : null;
        RolePermissionMappingEntity mapping = rbacService.grantPermission(roleName, permissionKey, grantedBy);
        return ok(Map.of(
                "message", "Permission granted",
                "mapping", Map.of("roleName", mapping.getRoleName(), "permissionKey", mapping.getPermissionKey())
        ));
    }

    /**
     * Revokes a permission from a role.
     * DELETE /api/v1/auth/rbac/roles/{roleName}/permissions/{permKey}
     */
    @DeleteMapping("/roles/{roleName}/permissions/{permissionKey}")
    public ResponseEntity<Map<String, Object>> revokePermission(
            @PathVariable String roleName,
            @PathVariable String permissionKey) {
        rbacService.revokePermission(roleName, permissionKey);
        return ok(Map.of("message", "Permission revoked", "roleName", roleName, "permissionKey", permissionKey));
    }

    /**
     * Returns all roles that have a specific permission.
     */
    @GetMapping("/permissions/{permissionKey}/roles")
    public ResponseEntity<Map<String, Object>> getRolesWithPermission(
            @PathVariable String permissionKey) {
        return ok(Map.of(
                "permissionKey", permissionKey,
                "roles", rbacService.getRolesWithPermission(permissionKey)
        ));
    }

    // ------------------------------------------------------------------
    private ResponseEntity<Map<String, Object>> ok(Map<String, Object> data) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("success", true);
        response.put("data", data);
        return ResponseEntity.ok(response);
    }
}
