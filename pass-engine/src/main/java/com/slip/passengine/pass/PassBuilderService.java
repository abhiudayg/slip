package com.slip.passengine.pass;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.slip.passengine.api.PassDtos.BrandSummary;
import com.slip.passengine.api.PassDtos.CreatePassRequest;
import com.slip.passengine.api.PassDtos.LocationDto;
import com.slip.passengine.config.SlipProperties;
import com.slip.passengine.stations.StationCatalogService;
import com.slip.passengine.template.TemplateCatalog;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PassBuilderService {
  private static final List<String> ASSET_NAMES = List.of(
      "icon.png", "icon@2x.png", "icon@3x.png",
      "logo.png", "logo@2x.png", "logo@3x.png",
      "strip.png", "strip@2x.png", "strip@3x.png",
      "pauli.png"
  );

  private final TemplateCatalog templates;
  private final StationCatalogService stations;
  private final PassSigner signer;
  private final SlipProperties props;
  private final ObjectMapper mapper;

  public PassBuilderService(
      TemplateCatalog templates,
      StationCatalogService stations,
      PassSigner signer,
      SlipProperties props,
      ObjectMapper mapper
  ) {
    this.templates = templates;
    this.stations = stations;
    this.signer = signer;
    this.props = props;
    this.mapper = mapper;
  }

  public byte[] buildPkpass(CreatePassRequest request) {
    BrandSummary brand = templates.loadBrand(request.template());
    Map<String, String> fields = new HashMap<>();
    if (request.fields() != null) {
      fields.putAll(request.fields());
    }
    for (String required : brand.requiredFields()) {
      if (!fields.containsKey(required) || fields.get(required) == null || fields.get(required).isBlank()) {
        if ("membership".equals(required) || "passenger".equals(required) || "venue".equals(required)
            || "booking_id".equals(required)) {
          fields.putIfAbsent(required, "—");
        } else {
          throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Missing required field: " + required);
        }
      }
    }
    for (String optional : brand.optionalFields()) {
      fields.putIfAbsent(optional, "—");
    }

    List<LocationDto> locations = stations.resolveLocations(
        brand.stationCatalog(),
        request.stationIds(),
        request.locations()
    );

    // Also resolve origin/destination names into locations for transit
    if (brand.stationCatalog() != null) {
      List<String> extra = new java.util.ArrayList<>();
      if (fields.containsKey("origin")) {
        extra.add(fields.get("origin"));
      }
      if (fields.containsKey("destination")) {
        extra.add(fields.get("destination"));
      }
      if (!extra.isEmpty()) {
        locations = stations.resolveLocations(brand.stationCatalog(), extra, locations);
      }
    }

    ObjectNode passJson = (ObjectNode) templates.loadPassBoilerplate(request.template()).deepCopy();
    injectPlaceholders(passJson, fields);
    passJson.put("passTypeIdentifier", props.passTypeIdentifier());
    passJson.put("teamIdentifier", props.teamIdentifier());
    passJson.put("serialNumber", "slip-" + System.currentTimeMillis());

    if (request.barcodeFormat() != null && !request.barcodeFormat().isBlank() && passJson.has("barcode")) {
      ((ObjectNode) passJson.get("barcode")).put("format", request.barcodeFormat());
    }

    if (!locations.isEmpty()) {
      ArrayNode locs = passJson.putArray("locations");
      for (LocationDto loc : locations) {
        ObjectNode n = locs.addObject();
        n.put("latitude", loc.latitude());
        n.put("longitude", loc.longitude());
        if (loc.relevantText() != null && !loc.relevantText().isBlank()) {
          n.put("relevantText", loc.relevantText());
        }
      }
    }

    if (request.relevantDate() != null && !request.relevantDate().isBlank()) {
      passJson.put("relevantDate", request.relevantDate());
    }

    try {
      Map<String, byte[]> files = new HashMap<>();
      byte[] passBytes = mapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(passJson);
      files.put("pass.json", passBytes);

      Path dir = templates.templateDir(request.template());
      for (String asset : ASSET_NAMES) {
        Path p = dir.resolve(asset);
        if (Files.exists(p)) {
          files.put(asset, Files.readAllBytes(p));
        }
      }

      ObjectNode manifest = mapper.createObjectNode();
      MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
      for (Map.Entry<String, byte[]> e : files.entrySet()) {
        sha1.reset();
        byte[] digest = sha1.digest(e.getValue());
        manifest.put(e.getKey(), HexFormat.of().formatHex(digest));
      }
      byte[] manifestBytes = mapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(manifest);
      files.put("manifest.json", manifestBytes);

      byte[] signature = signer.sign(manifestBytes);
      if (signature != null) {
        files.put("signature", signature);
      } else if (!props.devMode()) {
        throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Signing certificates not configured");
      }

      fields.clear();
      return zip(files);
    } catch (ResponseStatusException e) {
      throw e;
    } catch (Exception e) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to build pkpass", e);
    }
  }

  private void injectPlaceholders(JsonNode node, Map<String, String> fields) {
    if (node.isObject()) {
      ObjectNode obj = (ObjectNode) node;
      java.util.ArrayList<String> keys = new java.util.ArrayList<>();
      obj.fieldNames().forEachRemaining(keys::add);
      for (String key : keys) {
        JsonNode child = obj.get(key);
        if (child.isTextual()) {
          obj.put(key, replace(child.asText(), fields));
        } else {
          injectPlaceholders(child, fields);
        }
      }
    } else if (node.isArray()) {
      for (JsonNode child : node) {
        injectPlaceholders(child, fields);
      }
    }
  }

  private static String replace(String text, Map<String, String> fields) {
    String out = text;
    for (Map.Entry<String, String> e : fields.entrySet()) {
      out = out.replace("{{" + e.getKey() + "}}", e.getValue() == null ? "" : e.getValue());
    }
    out = out.replace("{{PASS_TYPE_IDENTIFIER}}", "");
    out = out.replace("{{TEAM_IDENTIFIER}}", "");
    // Leave unknown placeholders as em-dash for optional display
    if (out.contains("{{") && out.contains("}}")) {
      out = out.replaceAll("\\{\\{[^}]+}}", "—");
    }
    return out;
  }

  private static byte[] zip(Map<String, byte[]> files) throws IOException {
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    try (ZipOutputStream zos = new ZipOutputStream(bos)) {
      for (Map.Entry<String, byte[]> e : files.entrySet()) {
        ZipEntry entry = new ZipEntry(e.getKey());
        zos.putNextEntry(entry);
        zos.write(e.getValue());
        zos.closeEntry();
      }
    }
    return bos.toByteArray();
  }

  /** Tiny helper to copy iterator entries without ConcurrentModification surprises. */
  private static final class ArrayListCopy extends java.util.ArrayList<Map.Entry<String, JsonNode>> {
    ArrayListCopy(Iterator<Map.Entry<String, JsonNode>> it) {
      while (it.hasNext()) {
        add(it.next());
      }
    }
  }
}
