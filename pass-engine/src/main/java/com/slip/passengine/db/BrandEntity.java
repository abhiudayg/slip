package com.slip.passengine.db;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "brands")
public class BrandEntity {
  @Id
  private String id;

  @Column(name = "display_name", nullable = false)
  private String displayName;

  @Column(nullable = false)
  private String category;

  @Column(name = "apple_style", nullable = false)
  private String appleStyle;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "required_fields", nullable = false)
  private List<String> requiredFields = new ArrayList<>();

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "optional_fields", nullable = false)
  private List<String> optionalFields = new ArrayList<>();

  @Column(name = "supports_locations", nullable = false)
  private boolean supportsLocations;

  @Column(name = "supports_relevant_date", nullable = false)
  private boolean supportsRelevantDate;

  @Column(name = "accent_hint")
  private String accentHint;

  @Column(name = "station_catalog")
  private String stationCatalog;

  private String summary;
  private String badge;

  @Column(name = "icon_hint")
  private String iconHint;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt = Instant.now();

  public String getId() { return id; }
  public void setId(String id) { this.id = id; }
  public String getDisplayName() { return displayName; }
  public void setDisplayName(String displayName) { this.displayName = displayName; }
  public String getCategory() { return category; }
  public void setCategory(String category) { this.category = category; }
  public String getAppleStyle() { return appleStyle; }
  public void setAppleStyle(String appleStyle) { this.appleStyle = appleStyle; }
  public List<String> getRequiredFields() { return requiredFields; }
  public void setRequiredFields(List<String> requiredFields) { this.requiredFields = requiredFields; }
  public List<String> getOptionalFields() { return optionalFields; }
  public void setOptionalFields(List<String> optionalFields) { this.optionalFields = optionalFields; }
  public boolean isSupportsLocations() { return supportsLocations; }
  public void setSupportsLocations(boolean supportsLocations) { this.supportsLocations = supportsLocations; }
  public boolean isSupportsRelevantDate() { return supportsRelevantDate; }
  public void setSupportsRelevantDate(boolean supportsRelevantDate) { this.supportsRelevantDate = supportsRelevantDate; }
  public String getAccentHint() { return accentHint; }
  public void setAccentHint(String accentHint) { this.accentHint = accentHint; }
  public String getStationCatalog() { return stationCatalog; }
  public void setStationCatalog(String stationCatalog) { this.stationCatalog = stationCatalog; }
  public String getSummary() { return summary; }
  public void setSummary(String summary) { this.summary = summary; }
  public String getBadge() { return badge; }
  public void setBadge(String badge) { this.badge = badge; }
  public String getIconHint() { return iconHint; }
  public void setIconHint(String iconHint) { this.iconHint = iconHint; }
  public Instant getUpdatedAt() { return updatedAt; }
  public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
