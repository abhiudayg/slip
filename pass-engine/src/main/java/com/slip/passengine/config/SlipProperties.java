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
    String wwdrCertificatePath,
    /** Base64 EC public key for Apple VAS NFC. Empty = omit nfc from pass.json. */
    String nfcEncryptionPublicKey,
    /**
     * Public base for PassKit Web Service (no trailing slash), e.g. https://api.example.com/passkit.
     * When set, passes get webServiceURL + authenticationToken for silent Wallet updates.
     */
    String webServiceUrl
) {
  public SlipProperties {
    if (nfcEncryptionPublicKey == null) {
      nfcEncryptionPublicKey = "";
    }
    if (webServiceUrl == null) {
      webServiceUrl = "";
    }
  }

  public boolean nfcEnabled() {
    return nfcEncryptionPublicKey != null && !nfcEncryptionPublicKey.isBlank();
  }

  public boolean webServiceEnabled() {
    return webServiceUrl != null && !webServiceUrl.isBlank();
  }

  public String webServiceUrlNormalized() {
    if (!webServiceEnabled()) {
      return "";
    }
    String u = webServiceUrl.trim();
    while (u.endsWith("/")) {
      u = u.substring(0, u.length() - 1);
    }
    return u;
  }
}
