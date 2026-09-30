package com.slip.passengine.api;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;

public final class PassDtos {
  private PassDtos() {}

  public record LocationDto(double latitude, double longitude, String relevantText) {}

  public record CreatePassRequest(
      @NotBlank String template,
      Map<String, String> fields,
      List<LocationDto> locations,
      List<String> stationIds,
      String relevantDate,
      String expirationDate,
      String barcodeFormat
  ) {
    /** Never log QR / PNR / UPI payloads. */
    @Override
    public String toString() {
      int fieldCount = fields == null ? 0 : fields.size();
      return "CreatePassRequest{template='%s', fieldCount=%d, stations=%d, hasRelevantDate=%s, hasExpirationDate=%s}"
          .formatted(
              template,
              fieldCount,
              stationIds == null ? 0 : stationIds.size(),
              relevantDate != null && !relevantDate.isBlank(),
              expirationDate != null && !expirationDate.isBlank()
          );
    }
  }

  public record BrandSummary(
      String id,
      String displayName,
      String category,
      String appleStyle,
      List<String> requiredFields,
      List<String> optionalFields,
      boolean supportsLocations,
      boolean supportsRelevantDate,
      String accentHint,
      String stationCatalog,
      String summary,
      String badge,
      String iconHint
  ) {}

  public record StationDto(
      String id,
      String name,
      String line,
      double latitude,
      double longitude
  ) {}

  public record StationCatalogDto(String id, String name, String city, List<StationDto> stations) {}

  public record ErrorBody(String error, String message) {}

  public record HealthBody(String status, String service, boolean devMode) {}
}
