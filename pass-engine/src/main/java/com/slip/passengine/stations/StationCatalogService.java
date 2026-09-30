package com.slip.passengine.stations;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.slip.passengine.api.PassDtos.LocationDto;
import com.slip.passengine.api.PassDtos.StationCatalogDto;
import com.slip.passengine.api.PassDtos.StationDto;
import com.slip.passengine.config.SlipProperties;
import com.slip.passengine.db.CatalogMapper;
import com.slip.passengine.db.StationCatalogEntity;
import com.slip.passengine.db.StationCatalogRepository;
import com.slip.passengine.db.StationEntity;
import com.slip.passengine.db.StationRepository;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class StationCatalogService {
  private final Path stationsRoot;
  private final ObjectMapper mapper;
  private final StationCatalogRepository catalogRepository;
  private final StationRepository stationRepository;

  public StationCatalogService(
      SlipProperties props,
      ObjectMapper mapper,
      StationCatalogRepository catalogRepository,
      StationRepository stationRepository
  ) {
    this.stationsRoot = Path.of(props.stationsDir()).toAbsolutePath().normalize();
    this.mapper = mapper;
    this.catalogRepository = catalogRepository;
    this.stationRepository = stationRepository;
  }

  public StationCatalogDto load(String catalogId) {
    Optional<StationCatalogEntity> db = catalogRepository.findById(catalogId);
    if (db.isPresent()) {
      List<StationEntity> stations = stationRepository.findByCatalogIdOrderByNameAsc(catalogId);
      if (!stations.isEmpty()) {
        return CatalogMapper.toCatalog(db.get(), stations);
      }
    }
    return loadFromFile(catalogId);
  }

  private StationCatalogDto loadFromFile(String catalogId) {
    Path file = stationsRoot.resolve(catalogId + ".json");
    if (!Files.exists(file)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown station catalog: " + catalogId);
    }
    try {
      JsonNode root = mapper.readTree(file.toFile());
      List<StationDto> stations = new ArrayList<>();
      for (JsonNode s : root.withArray("stations")) {
        stations.add(new StationDto(
            s.path("id").asText(),
            s.path("name").asText(),
            s.path("line").asText(""),
            s.path("latitude").asDouble(),
            s.path("longitude").asDouble()
        ));
      }
      return new StationCatalogDto(
          root.path("id").asText(catalogId),
          root.path("name").asText(catalogId),
          root.path("city").asText(""),
          stations
      );
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Bad station catalog", e);
    }
  }

  public List<LocationDto> resolveLocations(String catalogId, List<String> stationIds, List<LocationDto> explicit) {
    Map<String, LocationDto> merged = new LinkedHashMap<>();
    if (explicit != null) {
      for (LocationDto loc : explicit) {
        String key = loc.latitude() + "," + loc.longitude();
        merged.put(key, loc);
      }
    }
    if (catalogId != null && stationIds != null && !stationIds.isEmpty()) {
      StationCatalogDto catalog = load(catalogId);
      Map<String, StationDto> byId = new LinkedHashMap<>();
      Map<String, StationDto> byName = new LinkedHashMap<>();
      for (StationDto s : catalog.stations()) {
        byId.put(s.id().toUpperCase(), s);
        byName.put(s.name().toLowerCase(), s);
      }
      for (String raw : stationIds) {
        if (raw == null || raw.isBlank()) {
          continue;
        }
        StationDto match = byId.get(raw.toUpperCase());
        if (match == null) {
          match = byName.get(raw.toLowerCase());
        }
        if (match != null) {
          String key = match.latitude() + "," + match.longitude();
          merged.put(key, new LocationDto(match.latitude(), match.longitude(), match.name()));
        }
      }
    }
    List<LocationDto> out = new ArrayList<>(merged.values());
    if (out.size() > 10) {
      return out.subList(0, 10);
    }
    return out;
  }

  public Optional<StationDto> findByCodeOrName(String catalogId, String query) {
    if (query == null || query.isBlank()) {
      return Optional.empty();
    }
    StationCatalogDto catalog = load(catalogId);
    String q = query.trim();
    for (StationDto s : catalog.stations()) {
      if (s.id().equalsIgnoreCase(q) || s.name().equalsIgnoreCase(q)) {
        return Optional.of(s);
      }
    }
    return Optional.empty();
  }
}
