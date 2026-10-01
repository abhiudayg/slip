package com.slip.passengine.api;

import com.slip.passengine.api.LiveActivityDtos.RegisterLiveActivityRequest;
import com.slip.passengine.api.LiveActivityDtos.RegisterLiveActivityResponse;
import com.slip.passengine.api.LiveActivityDtos.UpdateLiveActivityRequest;
import com.slip.passengine.api.LiveActivityDtos.UpdateLiveActivityResponse;
import com.slip.passengine.live.LiveActivityTokenStore;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * ActivityKit push token registry. APNs delivery of content-state updates requires an AuthKey
 * configured in ops — until then tokens are stored so a worker/cron can fan out updates.
 */
@RestController
@RequestMapping("/v1/live-activities")
public class LiveActivityController {
  private final LiveActivityTokenStore store;

  public LiveActivityController(LiveActivityTokenStore store) {
    this.store = store;
  }

  @PostMapping
  public RegisterLiveActivityResponse register(@Valid @RequestBody RegisterLiveActivityRequest body) {
    store.register(body.activityId(), body.pushToken(), body.templateId(), body.displayName());
    return new RegisterLiveActivityResponse(body.activityId(), "registered");
  }

  @GetMapping("/{activityId}")
  public Map<String, Object> get(@PathVariable String activityId) {
    return store
        .find(activityId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown activity"));
  }

  /**
   * Accepts an Island update intent. Returns instructions until APNs AuthKey is wired in prod.
   * Payload shape for APNs Live Activity (topic = {bundleId}.push-type.liveactivity):
   * <pre>
   * { "aps": { "timestamp": &lt;unix&gt;, "event": "update",
   *   "content-state": { "statusLine": "...", "detailLine": "...", "progress": 0.5 } } }
   * </pre>
   */
  @PostMapping("/{activityId}/update")
  public UpdateLiveActivityResponse update(
      @PathVariable String activityId,
      @Valid @RequestBody UpdateLiveActivityRequest body
  ) {
    if (store.find(activityId).isEmpty()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown activity");
    }
    store.rememberUpdate(activityId, body.statusLine(), body.detailLine(), body.progress());
    return new UpdateLiveActivityResponse(
        activityId,
        "queued",
        "Configure APNs AuthKey to push content-state to the Live Activity token; token is stored."
    );
  }
}
