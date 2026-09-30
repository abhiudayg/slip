package com.slip.passengine.template;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.slip.passengine.api.PassDtos.BrandSummary;
import com.slip.passengine.config.SlipProperties;
import com.slip.passengine.db.BrandEntity;
import com.slip.passengine.db.BrandRepository;
import com.slip.passengine.db.CatalogMapper;
import java.io.IOException;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class TemplateCatalog {
  private final Path templatesRoot;
  private final ObjectMapper mapper;
  private final BrandRepository brandRepository;

  public TemplateCatalog(SlipProperties props, ObjectMapper mapper, BrandRepository brandRepository) {
    this.templatesRoot = Path.of(props.templatesDir()).toAbsolutePath().normalize();
    this.mapper = mapper;
    this.brandRepository = brandRepository;
  }

  public Path root() {
    return templatesRoot;
  }

  public List<BrandSummary> listBrands() {
    List<BrandEntity> db = brandRepository.findAllByOrderByDisplayNameAsc();
    if (!db.isEmpty()) {
      // Prefer Neon catalog when seeded; still require on-disk pass assets.
      return db.stream()
          .filter(b -> Files.isDirectory(templatesRoot.resolve(b.getId())))
          .map(CatalogMapper::toBrand)
          .toList();
    }
    return listBrandsFromFiles();
  }

  private List<BrandSummary> listBrandsFromFiles() {
    List<BrandSummary> out = new ArrayList<>();
    if (!Files.isDirectory(templatesRoot)) {
      return out;
    }
    try (DirectoryStream<Path> stream = Files.newDirectoryStream(templatesRoot)) {
      for (Path dir : stream) {
        if (Files.isDirectory(dir) && Files.exists(dir.resolve("brand.json"))) {
          out.add(loadBrandFromFile(dir.getFileName().toString()));
        }
      }
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to list templates", e);
    }
    out.sort(Comparator.comparing(BrandSummary::displayName));
    return out;
  }

  public BrandSummary loadBrand(String templateId) {
    Optional<BrandEntity> db = brandRepository.findById(templateId);
    if (db.isPresent() && Files.isDirectory(templatesRoot.resolve(templateId))) {
      return CatalogMapper.toBrand(db.get());
    }
    return loadBrandFromFile(templateId);
  }

  private BrandSummary loadBrandFromFile(String templateId) {
    Path brandFile = templatesRoot.resolve(templateId).resolve("brand.json");
    if (!Files.exists(brandFile)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown template: " + templateId);
    }
    try {
      JsonNode n = mapper.readTree(brandFile.toFile());
      return new BrandSummary(
          text(n, "id", templateId),
          text(n, "displayName", templateId),
          text(n, "category", "other"),
          text(n, "appleStyle", "generic"),
          stringList(n.get("requiredFields")),
          stringList(n.get("optionalFields")),
          n.path("supportsLocations").asBoolean(false),
          n.path("supportsRelevantDate").asBoolean(false),
          text(n, "accentHint", null),
          text(n, "stationCatalog", null),
          text(n, "summary", null),
          text(n, "badge", null),
          text(n, "iconHint", null)
      );
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Bad brand.json for " + templateId, e);
    }
  }

  public Path templateDir(String templateId) {
    Path dir = templatesRoot.resolve(templateId).normalize();
    if (!dir.startsWith(templatesRoot) || !Files.isDirectory(dir)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown template: " + templateId);
    }
    return dir;
  }

  public JsonNode loadPassBoilerplate(String templateId) {
    Path passFile = templateDir(templateId).resolve("pass.json");
    try {
      return mapper.readTree(passFile.toFile());
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Bad pass.json for " + templateId, e);
    }
  }

  private static String text(JsonNode n, String field, String fallback) {
    JsonNode v = n.get(field);
    if (v == null || v.isNull()) {
      return fallback;
    }
    return v.asText();
  }

  private static List<String> stringList(JsonNode node) {
    List<String> list = new ArrayList<>();
    if (node != null && node.isArray()) {
      node.forEach(x -> list.add(x.asText()));
    }
    return list;
  }
}
