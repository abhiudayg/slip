package com.slip.passengine.pass;

import com.slip.passengine.config.SlipProperties;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import org.bouncycastle.cert.jcajce.JcaCertStore;
import org.bouncycastle.cms.CMSProcessableByteArray;
import org.bouncycastle.cms.CMSSignedData;
import org.bouncycastle.cms.CMSSignedDataGenerator;
import org.bouncycastle.cms.jcajce.JcaSignerInfoGeneratorBuilder;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.operator.ContentSigner;
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder;
import org.bouncycastle.operator.jcajce.JcaDigestCalculatorProviderBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class PassSigner {
  private static final Logger log = LoggerFactory.getLogger(PassSigner.class);

  static {
    if (java.security.Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
      java.security.Security.addProvider(new BouncyCastleProvider());
    }
  }

  private final SlipProperties props;

  public PassSigner(SlipProperties props) {
    this.props = props;
  }

  /**
   * Signs manifest.json bytes as Apple expects (detached CMS/PKCS#7).
   * Returns null in dev mode when certificates are not configured.
   */
  public byte[] sign(byte[] manifestBytes) throws Exception {
    if (props.certificatePath() == null || props.certificatePath().isBlank()) {
      if (props.devMode()) {
        log.warn("Dev mode: skipping PKCS#7 signature (no PASS_CERTIFICATE_PATH)");
        return null;
      }
      throw new IllegalStateException("PASS_CERTIFICATE_PATH is required when not in dev mode");
    }

    Path p12Path = Path.of(props.certificatePath());
    char[] password = props.certificatePassword() == null
        ? new char[0]
        : props.certificatePassword().toCharArray();

    KeyStore keyStore = KeyStore.getInstance("PKCS12");
    try (InputStream in = Files.newInputStream(p12Path)) {
      keyStore.load(in, password);
    }

    String alias = null;
    Enumeration<String> aliases = keyStore.aliases();
    while (aliases.hasMoreElements()) {
      String a = aliases.nextElement();
      if (keyStore.isKeyEntry(a)) {
        alias = a;
        break;
      }
    }
    if (alias == null) {
      throw new IllegalStateException("No private key found in PKCS#12 store");
    }

    PrivateKey privateKey = (PrivateKey) keyStore.getKey(alias, password);
    X509Certificate passCert = (X509Certificate) keyStore.getCertificate(alias);

    List<X509Certificate> certChain = new ArrayList<>();
    certChain.add(passCert);
    if (props.wwdrCertificatePath() != null && !props.wwdrCertificatePath().isBlank()) {
      try (InputStream in = Files.newInputStream(Path.of(props.wwdrCertificatePath()))) {
        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        certChain.add((X509Certificate) cf.generateCertificate(in));
      }
    }

    ContentSigner sha1Signer = new JcaContentSignerBuilder("SHA1withRSA")
        .setProvider(BouncyCastleProvider.PROVIDER_NAME)
        .build(privateKey);

    CMSSignedDataGenerator generator = new CMSSignedDataGenerator();
    generator.addSignerInfoGenerator(
        new JcaSignerInfoGeneratorBuilder(
                new JcaDigestCalculatorProviderBuilder()
                    .setProvider(BouncyCastleProvider.PROVIDER_NAME)
                    .build())
            .build(sha1Signer, passCert)
    );
    generator.addCertificates(new JcaCertStore(certChain));

    CMSSignedData signedData = generator.generate(new CMSProcessableByteArray(manifestBytes), false);
    return signedData.getEncoded();
  }
}
