package com.slip.passengine.live;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

@Component
public class LiveActivityTokenStore {
  public record Entry(
      String activityId,
      String pushToken,
      String templateId,
      String displayName,
      Instant registeredAt,
      String lastStatusLine,
      String lastDetailLine,
      Double lastProgress
  ) {}

  private final ConcurrentHashMap<String, Entry> byId = new ConcurrentHashMap<>();

  public void register(String activityId, String pushToken, String templateId, String displayName) {
    Entry prior = byId.get(activityId);
    byId.put(
        activityId,
        new Entry(
            activityId,
            pushToken,
            templateId == null ? "" : templateId,
            displayName == null ? "" : displayName,
            Instant.now(),
            prior == null ? null : prior.lastStatusLine(),
            prior == null ? null : prior.lastDetailLine(),
            prior == null ? null : prior.lastProgress()
        )
    );
  }

  public Optional<Map<String, Object>> find(String activityId) {
    Entry e = byId.get(activityId);
    if (e == null) {
      return Optional.empty();
    }
    return Optional.of(
        Map.of(
            "activityId", e.activityId(),
            "templateId", e.templateId(),
            "displayName", e.displayName(),
            "registeredAt", e.registeredAt().toString(),
            "hasPushToken", e.pushToken() != null && !e.pushToken().isBlank(),
            "lastStatusLine", e.lastStatusLine() == null ? "" : e.lastStatusLine(),
            "lastDetailLine", e.lastDetailLine() == null ? "" : e.lastDetailLine()
        )
    );
  }

  public void rememberUpdate(String activityId, String statusLine, String detailLine, Double progress) {
    byId.computeIfPresent(
        activityId,
        (id, prior) ->
            new Entry(
                prior.activityId(),
                prior.pushToken(),
                prior.templateId(),
                prior.displayName(),
                prior.registeredAt(),
                statusLine,
                detailLine,
                progress
            )
    );
  }

  /** For ops / future APNs fan-out. */
  public Optional<String> pushToken(String activityId) {
    Entry e = byId.get(activityId);
    return e == null ? Optional.empty() : Optional.ofNullable(e.pushToken());
  }
}
