package com.slip.passengine.db;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StationRepository extends JpaRepository<StationEntity, StationEntity.StationId> {
  List<StationEntity> findByCatalogIdOrderByNameAsc(String catalogId);
}
