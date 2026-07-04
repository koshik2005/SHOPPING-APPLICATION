package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.NavigationMenuEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface NavigationMenuRepository extends JpaRepository<NavigationMenuEntity, UUID> {
    List<NavigationMenuEntity> findByPortalTargetAndActiveTrueOrderByDisplayOrderAsc(String portalTarget);
    List<NavigationMenuEntity> findByPortalTargetAndParentIdIsNullAndActiveTrueOrderByDisplayOrderAsc(String portalTarget);
}
