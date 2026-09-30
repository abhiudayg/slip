package com.slip.passengine.db;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "pass_build_events")
public class PassBuildEventEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "template_id", nullable = false)
  private String templateId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt = Instant.now();

  @Column(nullable = false)
  private boolean success;

  @Column(name = "error_code")
  private String errorCode;

  public Long getId() { return id; }
  public String getTemplateId() { return templateId; }
  public void setTemplateId(String templateId) { this.templateId = templateId; }
  public Instant getCreatedAt() { return createdAt; }
  public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
  public boolean isSuccess() { return success; }
  public void setSuccess(boolean success) { this.success = success; }
  public String getErrorCode() { return errorCode; }
  public void setErrorCode(String errorCode) { this.errorCode = errorCode; }
}
