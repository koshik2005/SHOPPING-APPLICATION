package com.hyperlocal.inventory.infrastructure.repository;

import com.hyperlocal.inventory.infrastructure.entity.RolePermissionMappingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.Collection;
import java.util.UUID;

@Repository
public interface RolePermissionMappingRepository extends JpaRepository<RolePermissionMappingEntity, UUID> {
    
    @Query("""
        SELECT COUNT(r) > 0 FROM RolePermissionMappingEntity r
        WHERE r.roleName IN :roles AND r.permissionKey = :permission
    """)
    boolean hasPermission(
            @Param("roles") Collection<String> roles,
            @Param("permission") String permission);
}
