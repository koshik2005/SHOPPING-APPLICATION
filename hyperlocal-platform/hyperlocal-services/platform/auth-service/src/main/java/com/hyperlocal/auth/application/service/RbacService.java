package com.hyperlocal.auth.application.service;

import com.hyperlocal.auth.infrastructure.entity.PermissionDefinitionEntity;
import com.hyperlocal.auth.infrastructure.entity.RolePermissionMappingEntity;
import com.hyperlocal.auth.infrastructure.repository.PermissionDefinitionRepository;
import com.hyperlocal.auth.infrastructure.repository.RolePermissionMappingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * RbacService — Dynamic Role-Based Access Control.
 *
 * Replaces the hardcoded ROLE_PERMISSIONS constant in AuthContext.tsx.
 * All role→permission mappings now live exclusively in the database.
 *
 * The ROLE_SUPER_ADMIN is treated specially: it has wildcard (*) access
 * and this is checked at the API level, not by listing permissions.
 */
@Service
@RequiredArgsConstructor
public class RbacService {

    private static final String SUPER_ADMIN_ROLE = "ROLE_SUPER_ADMIN";

    private final PermissionDefinitionRepository permissionRepo;
    private final RolePermissionMappingRepository mappingRepo;

    // ======================================================================
    // PERMISSION QUERIES
    // ======================================================================

    /**
     * Returns all permission keys for a given role.
     * For ROLE_SUPER_ADMIN returns ["*"] (wildcard).
     */
    @Transactional(readOnly = true)
    public List<String> getPermissionsForRole(String roleName) {
        if (SUPER_ADMIN_ROLE.equals(roleName)) {
            return List.of("*");
        }
        return mappingRepo.findByRoleNameOrderByPermissionKeyAsc(roleName)
                .stream()
                .map(RolePermissionMappingEntity::getPermissionKey)
                .collect(Collectors.toList());
    }

    /**
     * Returns permissions for multiple roles (for users with compound roles).
     * Deduplicates across roles.
     */
    @Transactional(readOnly = true)
    public Set<String> getPermissionsForRoles(List<String> roleNames) {
        if (roleNames.contains(SUPER_ADMIN_ROLE)) {
            return Set.of("*");
        }
        Set<String> permissions = new HashSet<>();
        for (String role : roleNames) {
            permissions.addAll(getPermissionsForRole(role));
        }
        return permissions;
    }

    /**
     * Checks if a specific role has a specific permission.
     */
    @Transactional(readOnly = true)
    public boolean hasPermission(String roleName, String permissionKey) {
        if (SUPER_ADMIN_ROLE.equals(roleName)) return true;
        return mappingRepo.existsByRoleNameAndPermissionKey(roleName, permissionKey);
    }

    /**
     * Checks if any of the supplied roles has the given permission.
     */
    @Transactional(readOnly = true)
    public boolean anyRoleHasPermission(List<String> roleNames, String permissionKey) {
        if (roleNames.contains(SUPER_ADMIN_ROLE)) return true;
        return roleNames.stream().anyMatch(role -> hasPermission(role, permissionKey));
    }

    // ======================================================================
    // PERMISSION CATALOG
    // ======================================================================

    @Transactional(readOnly = true)
    public List<PermissionDefinitionEntity> getAllPermissions() {
        return permissionRepo.findAllByOrderByCategoryAscPermissionKeyAsc();
    }

    @Transactional(readOnly = true)
    public List<PermissionDefinitionEntity> getPermissionsByCategory(String category) {
        return permissionRepo.findByCategoryOrderByPermissionKeyAsc(category);
    }

    @Transactional
    public PermissionDefinitionEntity createPermission(PermissionDefinitionEntity entity) {
        return permissionRepo.save(entity);
    }

    // ======================================================================
    // ROLE-PERMISSION ASSIGNMENT
    // ======================================================================

    /**
     * Grants a permission to a role.
     * Admin-only operation — recorded with grantedBy audit trail.
     */
    @Transactional
    public RolePermissionMappingEntity grantPermission(
            String roleName, String permissionKey, UUID grantedBy) {
        if (mappingRepo.existsByRoleNameAndPermissionKey(roleName, permissionKey)) {
            return mappingRepo.findByRoleNameAndPermissionKey(roleName, permissionKey).orElseThrow();
        }
        RolePermissionMappingEntity mapping = new RolePermissionMappingEntity();
        mapping.setRoleName(roleName);
        mapping.setPermissionKey(permissionKey);
        mapping.setGrantedBy(grantedBy);
        mapping.setGrantedAt(Instant.now());
        return mappingRepo.save(mapping);
    }

    /**
     * Revokes a permission from a role.
     */
    @Transactional
    public void revokePermission(String roleName, String permissionKey) {
        mappingRepo.deleteByRoleNameAndPermissionKey(roleName, permissionKey);
    }

    /**
     * Returns all roles that have a specific permission.
     */
    @Transactional(readOnly = true)
    public List<String> getRolesWithPermission(String permissionKey) {
        return mappingRepo.findByPermissionKey(permissionKey)
                .stream()
                .map(RolePermissionMappingEntity::getRoleName)
                .distinct()
                .sorted()
                .collect(Collectors.toList());
    }

    /**
     * Returns a full RBAC matrix: Map<roleName, List<permissionKey>>
     * Used by the Portal's RBAC management page.
     */
    @Transactional(readOnly = true)
    public Map<String, List<String>> getRbacMatrix() {
        List<RolePermissionMappingEntity> all = mappingRepo.findAll();
        return all.stream()
                .collect(Collectors.groupingBy(
                        RolePermissionMappingEntity::getRoleName,
                        Collectors.mapping(
                                RolePermissionMappingEntity::getPermissionKey,
                                Collectors.toList()
                        )
                ));
    }
}
