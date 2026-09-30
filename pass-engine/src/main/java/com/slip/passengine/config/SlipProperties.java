package com.slip.passengine.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "slip")
public record SlipProperties(
    String templatesDir,
    String stationsDir,
    boolean devMode,
    String passTypeIdentifier,
    String teamIdentifier,
    String certificatePath,
    String certificatePassword,
    String wwdrCertificatePath
) {}
