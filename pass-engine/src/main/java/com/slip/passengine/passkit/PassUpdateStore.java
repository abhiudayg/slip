package com.slip.passengine.passkit;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

@Component
public class PassUpdateStore {
  public record PassSnapshot(
      String serialNumber,
      String authenticationToken,
      String templateId,
      Map<String, String> fields,
      Instant updatedAt,
      String updateTag
  ) {}

  public record DeviceRegistration(String deviceLibraryIdentifier, String pushToken, Instant registeredAt) {}

  private final ConcurrentHashMap<String, PassSnapshot> bySerial = new ConcurrentHashMap<>();
  /** serial -> device registrations */
  private final ConcurrentHashMap<String, List<DeviceRegistration>> devicesBySerial = new ConcurrentHashMap<>();

  public void remember(String serial, String authToken, String templateId, Map<String, String> fields) {
    String tag = Long.toHexString(System.currentTimeMillis());
    bySerial.put(
        serial,
        new PassSnapshot(serial, authToken, templateId, fields, Instant.now(), tag)
    );
  }

  public Optional<PassSnapshot> find(String serial) {
    return Optional.ofNullable(bySerial.get(serial));
  }

  public boolean authorize(String serial, String applePassToken) {
    PassSnapshot s = bySerial.get(serial);
    if (s == null || applePassToken == null) {
      return false;
    }
    String raw = applePassToken.startsWith("ApplePass ")
        ? applePassToken.substring("ApplePass ".length()).trim()
        : applePassToken.trim();
    return s.authenticationToken().equals(raw);
  }

  public void registerDevice(String serial, String deviceLibraryIdentifier, String pushToken) {
    devicesBySerial
        .computeIfAbsent(serial, k -> new ArrayList<>())
        .removeIf(d -> d.deviceLibraryIdentifier().equals(deviceLibraryIdentifier));
    devicesBySerial
        .get(serial)
        .add(new DeviceRegistration(deviceLibraryIdentifier, pushToken, Instant.now()));
  }

  public void unregisterDevice(String serial, String deviceLibraryIdentifier) {
    List<DeviceRegistration> list = devicesBySerial.get(serial);
    if (list != null) {
      list.removeIf(d -> d.deviceLibraryIdentifier().equals(deviceLibraryIdentifier));
    }
  }

  public List<String> serialsForDevice(String deviceLibraryIdentifier, String passesUpdatedSince) {
    List<String> out = new ArrayList<>();
    Instant since = null;
    if (passesUpdatedSince != null && !passesUpdatedSince.isBlank()) {
      try {
        since = Instant.ofEpochMilli(Long.parseLong(passesUpdatedSince, 16));
      } catch (Exception ignored) {
        since = null;
      }
    }
    for (Map.Entry<String, List<DeviceRegistration>> e : devicesBySerial.entrySet()) {
      boolean forDevice = e.getValue().stream()
          .anyMatch(d -> d.deviceLibraryIdentifier().equals(deviceLibraryIdentifier));
      if (!forDevice) {
        continue;
      }
      PassSnapshot snap = bySerial.get(e.getKey());
      if (snap == null) {
        continue;
      }
      if (since == null || snap.updatedAt().isAfter(since)) {
        out.add(e.getKey());
      }
    }
    return out;
  }

  public void touchUpdate(String serial, Map<String, String> fields) {
    PassSnapshot prior = bySerial.get(serial);
    if (prior == null) {
      return;
    }
    String tag = Long.toHexString(System.currentTimeMillis());
    bySerial.put(
        serial,
        new PassSnapshot(
            prior.serialNumber(),
            prior.authenticationToken(),
            prior.templateId(),
            fields != null ? fields : prior.fields(),
            Instant.now(),
            tag
        )
    );
  }

  public List<DeviceRegistration> devices(String serial) {
    return devicesBySerial.getOrDefault(serial, List.of());
  }
}
