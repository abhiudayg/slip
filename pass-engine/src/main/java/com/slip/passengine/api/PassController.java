package com.slip.passengine.api;

import com.slip.passengine.api.PassDtos.BrandSummary;
import com.slip.passengine.api.PassDtos.CreatePassRequest;
import com.slip.passengine.api.PassDtos.ErrorBody;
import com.slip.passengine.api.PassDtos.HealthBody;
import com.slip.passengine.api.PassDtos.StationCatalogDto;
import com.slip.passengine.config.SlipProperties;
import com.slip.passengine.db.PassBuildEventEntity;
import com.slip.passengine.db.PassBuildEventRepository;
import com.slip.passengine.pass.PassBuilderService;
import com.slip.passengine.stations.StationCatalogService;
import com.slip.passengine.template.TemplateCatalog;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/v1")
public class PassController {
  private final PassBuilderService builder;
  private final TemplateCatalog templates;
  private final StationCatalogService stations;
  private final SlipProperties props;
  private final PassBuildEventRepository buildEvents;

  public PassController(
      PassBuilderService builder,
      TemplateCatalog templates,
      StationCatalogService stations,
      SlipProperties props,
      PassBuildEventRepository buildEvents
  ) {
    this.builder = builder;
    this.templates = templates;
    this.stations = stations;
    this.props = props;
    this.buildEvents = buildEvents;
  }

  @GetMapping("/health")
  public HealthBody health() {
    return new HealthBody("ok", "slip-pass-engine", props.devMode());
  }

  @GetMapping("/brands")
  public List<BrandSummary> brands() {
    return templates.listBrands();
  }

  @GetMapping("/brands/{id}")
  public BrandSummary brand(@PathVariable String id) {
    return templates.loadBrand(id);
  }

  @GetMapping("/stations/{catalogId}")
  public StationCatalogDto stationCatalog(@PathVariable String catalogId) {
    return stations.load(catalogId);
  }

  @PostMapping("/passes")
  public ResponseEntity<byte[]> createPass(@Valid @RequestBody CreatePassRequest request) {
    // Ephemeral signing only: build in-memory, return bytes, do not persist request fields.
    try {
      byte[] pkpass = builder.buildPkpass(request);
      recordBuild(request.template(), true, null);
      return ResponseEntity.ok()
          .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"slip.pkpass\"")
          .contentType(MediaType.parseMediaType("application/vnd.apple.pkpass"))
          .body(pkpass);
    } catch (RuntimeException ex) {
      recordBuild(request.template(), false, ex.getClass().getSimpleName());
      throw ex;
    }
  }

  private void recordBuild(String templateId, boolean success, String errorCode) {
    try {
      PassBuildEventEntity event = new PassBuildEventEntity();
      event.setTemplateId(templateId == null ? "unknown" : templateId);
      event.setSuccess(success);
      event.setErrorCode(errorCode);
      buildEvents.save(event);
    } catch (Exception ignored) {
      // Metrics must never break pass issuance.
    }
  }

  @ExceptionHandler(ResponseStatusException.class)
  public ResponseEntity<ErrorBody> handleStatus(ResponseStatusException ex) {
    return ResponseEntity.status(ex.getStatusCode())
        .body(new ErrorBody(ex.getStatusCode().toString(), ex.getReason()));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorBody> handleValidation(MethodArgumentNotValidException ex) {
    String msg = ex.getBindingResult().getFieldErrors().stream()
        .findFirst()
        .map(err -> err.getField() + " " + err.getDefaultMessage())
        .orElse("Validation failed");
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorBody("bad_request", msg));
  }
}
