package com.slip.passengine.db;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.Objects;

@Entity
@Table(name = "stations")
@IdClass(StationEntity.StationId.class)
public class StationEntity {
  @Id
  private String id;

  @Id
  @Column(name = "catalog_id")
  private String catalogId;

  @Column(nullable = false)
  private String name;

  @Column(nullable = false)
  private String line = "";

  @Column(nullable = false)
  private double latitude;

  @Column(nullable = false)
  private double longitude;

  public String getId() { return id; }
  public void setId(String id) { this.id = id; }
  public String getCatalogId() { return catalogId; }
  public void setCatalogId(String catalogId) { this.catalogId = catalogId; }
  public String getName() { return name; }
  public void setName(String name) { this.name = name; }
  public String getLine() { return line; }
  public void setLine(String line) { this.line = line; }
  public double getLatitude() { return latitude; }
  public void setLatitude(double latitude) { this.latitude = latitude; }
  public double getLongitude() { return longitude; }
  public void setLongitude(double longitude) { this.longitude = longitude; }

  public static class StationId implements Serializable {
    private String id;
    private String catalogId;

    public StationId() {}

    public StationId(String id, String catalogId) {
      this.id = id;
      this.catalogId = catalogId;
    }

    @Override
    public boolean equals(Object o) {
      if (this == o) return true;
      if (!(o instanceof StationId that)) return false;
      return Objects.equals(id, that.id) && Objects.equals(catalogId, that.catalogId);
    }

    @Override
    public int hashCode() {
      return Objects.hash(id, catalogId);
    }
  }
}
