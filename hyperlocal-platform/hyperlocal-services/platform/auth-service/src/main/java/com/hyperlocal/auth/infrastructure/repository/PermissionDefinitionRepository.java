package com.hyperlocal.auth.infrastructure.repository;

import com.hyperlocal.auth.infrastructure.entity.PermissionDefinitionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PermissionDefinitionRepository extends JpaRepository<PermissionDefinitionEntity, UUID> {
    Optional<PermissionDefinitionEntity> findByPermissionKey(String permissionKey);
    List<PermissionDefinitionEntity> findByCategoryOrderByPermissionKeyAsc(String category);
    List<PermissionDefinitionEntity> findAllByOrderByCategoryAscPermissionKeyAsc();
}
