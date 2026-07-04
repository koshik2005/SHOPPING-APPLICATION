package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.RolePermissionMappingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RolePermissionMappingRepository extends JpaRepository<RolePermissionMappingEntity, UUID> {
    List<RolePermissionMappingEntity> findByRoleNameOrderByPermissionKeyAsc(String roleName);
    List<RolePermissionMappingEntity> findByPermissionKey(String permissionKey);
    Optional<RolePermissionMappingEntity> findByRoleNameAndPermissionKey(String roleName, String permissionKey);
    void deleteByRoleNameAndPermissionKey(String roleName, String permissionKey);
    boolean existsByRoleNameAndPermissionKey(String roleName, String permissionKey);
}
