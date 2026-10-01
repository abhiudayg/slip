package com.slip.passengine.passkit;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.slip.passengine.api.PassDtos.CreatePassRequest;
import com.slip.passengine.config.SlipProperties;
import com.slip.passengine.pass.PassBuilderService;
import org.springframework.context.annotation.Lazy;
import com.slip.passengine.passkit.PassUpdateStore.PassSnapshot;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * Apple PassKit Web Service — Wallet registers here and pulls updated .pkpass after a silent push.
 * Paths are under /passkit so webServiceURL can be https://host/passkit
 */
@RestController
@RequestMapping("/passkit/v1")
public class PassKitWebServiceController {
  private final PassUpdateStore store;
  private final PassBuilderService builder;
  private final SlipProperties props;
  private final ObjectMapper mapper;

  public PassKitWebServiceController(
      PassUpdateStore store, @Lazy PassBuilderService builder, SlipProperties props, ObjectMapper mapper
  ) {
    this.store = store;
    this.builder = builder;
    this.props = props;
    this.mapper = mapper;
  }

  @PostMapping("/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}/{serialNumber}")
  public ResponseEntity<Void> register(
      @PathVariable String deviceLibraryIdentifier,
      @PathVariable String passTypeIdentifier,
      @PathVariable String serialNumber,
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @RequestBody(required = false) JsonNode body
  ) {
    assertPassType(passTypeIdentifier);
    if (!store.authorize(serialNumber, authorization)) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
    }
    String pushToken = body != null && body.has("pushToken") ? body.get("pushToken").asText("") : "";
    store.registerDevice(serialNumber, deviceLibraryIdentifier, pushToken);
    return ResponseEntity.status(HttpStatus.CREATED).build();
  }

  @GetMapping("/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}")
  public ResponseEntity<Map<String, Object>> serials(
      @PathVariable String deviceLibraryIdentifier,
      @PathVariable String passTypeIdentifier,
      @RequestParam(value = "passesUpdatedSince", required = false) String passesUpdatedSince
  ) {
    assertPassType(passTypeIdentifier);
    List<String> serialNumbers = store.serialsForDevice(deviceLibraryIdentifier, passesUpdatedSince);
    if (serialNumbers.isEmpty()) {
      return ResponseEntity.noContent().build();
    }
    String lastTag = Long.toHexString(System.currentTimeMillis());
    return ResponseEntity.ok(Map.of("serialNumbers", serialNumbers, "lastUpdated", lastTag));
  }

  @GetMapping("/passes/{passTypeIdentifier}/{serialNumber}")
  public ResponseEntity<byte[]> latestPass(
      @PathVariable String passTypeIdentifier,
      @PathVariable String serialNumber,
      @RequestHeader(value = "Authorization", required = false) String authorization
  ) {
    assertPassType(passTypeIdentifier);
    if (!store.authorize(serialNumber, authorization)) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
    }
    PassSnapshot snap = store.find(serialNumber)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    CreatePassRequest req = new CreatePassRequest(
        snap.templateId(),
        new HashMap<>(snap.fields()),
        null,
        null,
        null,
        null,
        null,
        serialNumber
    );
    byte[] pkpass = builder.buildPkpass(req);
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_TYPE, "application/vnd.apple.pkpass")
        .header("last-modified", snap.updateTag())
        .body(pkpass);
  }

  @DeleteMapping("/devices/{deviceLibraryIdentifier}/registrations/{passTypeIdentifier}/{serialNumber}")
  public ResponseEntity<Void> unregister(
      @PathVariable String deviceLibraryIdentifier,
      @PathVariable String passTypeIdentifier,
      @PathVariable String serialNumber,
      @RequestHeader(value = "Authorization", required = false) String authorization
  ) {
    assertPassType(passTypeIdentifier);
    if (!store.authorize(serialNumber, authorization)) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
    }
    store.unregisterDevice(serialNumber, deviceLibraryIdentifier);
    return ResponseEntity.ok().build();
  }

  @PostMapping("/log")
  public ResponseEntity<Void> log(@RequestBody(required = false) JsonNode body) {
    // Intentionally ignore — never echo pass payloads into access logs.
    return ResponseEntity.ok().build();
  }

  /**
   * Ops helper: mark a serial dirty so the next Wallet pull (after silent APNs) refreshes fields.
   * Body: { "fields": { "gate": "14A", ... } }
   */
  @PostMapping("/admin/passes/{serialNumber}/update")
  public Map<String, String> adminUpdate(
      @PathVariable String serialNumber,
      @RequestBody JsonNode body
  ) {
    Optional<PassSnapshot> prior = store.find(serialNumber);
    if (prior.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    }
    Map<String, String> fields = new HashMap<>(prior.get().fields());
    if (body != null && body.has("fields") && body.get("fields").isObject()) {
      body.get("fields").fields().forEachRemaining(e -> fields.put(e.getKey(), e.getValue().asText("")));
    }
    store.touchUpdate(serialNumber, fields);
    return Map.of(
        "status", "updated",
        "serialNumber", serialNumber,
        "hint", "Send empty APNs to registered device pushTokens so Wallet pulls GET /passkit/v1/passes/..."
    );
  }

  private void assertPassType(String passTypeIdentifier) {
    if (!props.passTypeIdentifier().equals(passTypeIdentifier)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    }
  }
}
