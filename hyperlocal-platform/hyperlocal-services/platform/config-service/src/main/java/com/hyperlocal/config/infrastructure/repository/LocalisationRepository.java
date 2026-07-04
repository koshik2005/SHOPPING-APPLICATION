package com.hyperlocal.config.infrastructure.repository;

import com.hyperlocal.config.infrastructure.entity.LocalisationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LocalisationRepository extends JpaRepository<LocalisationEntity, UUID> {
    Optional<LocalisationEntity> findByStringKeyAndLocale(String stringKey, String locale);
    List<LocalisationEntity> findByLocaleOrderByStringKeyAsc(String locale);
    Optional<LocalisationEntity> findByStringKeyAndLocaleOrderByLastUpdatedDesc(String stringKey, String locale);
}
