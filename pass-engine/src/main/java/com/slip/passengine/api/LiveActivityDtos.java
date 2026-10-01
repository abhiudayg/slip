package com.slip.passengine.api;

import jakarta.validation.constraints.NotBlank;

public final class LiveActivityDtos {
  private LiveActivityDtos() {}

  public record RegisterLiveActivityRequest(
      @NotBlank String activityId,
      @NotBlank String pushToken,
      String templateId,
      String displayName
  ) {}

  public record RegisterLiveActivityResponse(String activityId, String status) {}

  public record UpdateLiveActivityRequest(
      @NotBlank String statusLine,
      String detailLine,
      Double progress
  ) {}

  public record UpdateLiveActivityResponse(
      String activityId,
      String status,
      String hint
  ) {}
}
