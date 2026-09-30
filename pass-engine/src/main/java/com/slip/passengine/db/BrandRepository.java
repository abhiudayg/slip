package com.slip.passengine.db;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BrandRepository extends JpaRepository<BrandEntity, String> {
  List<BrandEntity> findAllByOrderByDisplayNameAsc();
}
