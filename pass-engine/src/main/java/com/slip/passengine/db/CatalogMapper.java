package com.slip.passengine.db;

import com.slip.passengine.api.PassDtos.BrandSummary;
import com.slip.passengine.api.PassDtos.StationCatalogDto;
import com.slip.passengine.api.PassDtos.StationDto;
import java.util.List;

public final class CatalogMapper {
  private CatalogMapper() {}

  public static BrandSummary toBrand(BrandEntity e) {
    return new BrandSummary(
        e.getId(),
        e.getDisplayName(),
        e.getCategory(),
        e.getAppleStyle(),
        e.getRequiredFields() == null ? List.of() : e.getRequiredFields(),
        e.getOptionalFields() == null ? List.of() : e.getOptionalFields(),
        e.isSupportsLocations(),
        e.isSupportsRelevantDate(),
        e.getAccentHint(),
        e.getStationCatalog(),
        e.getSummary(),
        e.getBadge(),
        e.getIconHint()
    );
  }

  public static StationCatalogDto toCatalog(
      StationCatalogEntity catalog,
      List<StationEntity> stations
  ) {
    List<StationDto> dtos = stations.stream()
        .map(s -> new StationDto(
            s.getId(),
            s.getName(),
            s.getLine(),
            s.getLatitude(),
            s.getLongitude()
        ))
        .toList();
    return new StationCatalogDto(catalog.getId(), catalog.getName(), catalog.getCity(), dtos);
  }
}
