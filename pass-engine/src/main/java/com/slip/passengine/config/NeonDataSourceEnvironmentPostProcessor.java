package com.slip.passengine.config;

import java.util.HashMap;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.SystemEnvironmentPropertySource;

/**
 * Accepts Neon-style {@code DATABASE_URL=postgresql://user:pass@host/db?sslmode=require}
 * and rewrites it to a JDBC URL + username/password for Spring Datasource / Flyway.
 */
public class NeonDataSourceEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {
  @Override
  public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
    String raw = firstNonBlank(
        environment.getProperty("DATABASE_URL"),
        environment.getProperty("SPRING_DATASOURCE_URL"),
        environment.getProperty("spring.datasource.url")
    );
    // Also peek system env before placeholder resolution quirks.
    if (raw == null || raw.isBlank()) {
      raw = firstNonBlank(System.getenv("DATABASE_URL"), System.getenv("SPRING_DATASOURCE_URL"));
    }
    if (raw == null || raw.startsWith("jdbc:")) {
      return;
    }
    if (!(raw.startsWith("postgresql://") || raw.startsWith("postgres://"))) {
      return;
    }
    String rest = raw.replaceFirst("^postgres(ql)?://", "");
    String userPass = null;
    String hostPart;
    if (rest.contains("@")) {
      userPass = rest.substring(0, rest.indexOf('@'));
      hostPart = rest.substring(rest.indexOf('@') + 1);
    } else {
      hostPart = rest;
    }
    String user = null;
    String pass = null;
    if (userPass != null) {
      int colon = userPass.indexOf(':');
      if (colon >= 0) {
        user = java.net.URLDecoder.decode(userPass.substring(0, colon), java.nio.charset.StandardCharsets.UTF_8);
        pass = java.net.URLDecoder.decode(userPass.substring(colon + 1), java.nio.charset.StandardCharsets.UTF_8);
      } else {
        user = userPass;
      }
    }
    Map<String, Object> props = new HashMap<>();
    String jdbc = "jdbc:postgresql://" + hostPart;
    props.put("spring.datasource.url", jdbc);
    props.put("spring.datasource.driver-class-name", "org.postgresql.Driver");
    props.put("spring.flyway.url", jdbc);
    if (user != null) {
      props.put("spring.datasource.username", user);
      props.put("spring.flyway.user", user);
    }
    if (pass != null) {
      props.put("spring.datasource.password", pass);
      props.put("spring.flyway.password", pass);
    }
    // Insert ahead of systemEnvironment so ${DATABASE_URL} placeholders cannot win.
    environment.getPropertySources().addFirst(new MapPropertySource("neonDatasourceRewrite", props));
  }

  private static String firstNonBlank(String... values) {
    for (String v : values) {
      if (v != null && !v.isBlank()) return v.trim();
    }
    return null;
  }

  @Override
  public int getOrder() {
    return Ordered.HIGHEST_PRECEDENCE;
  }
}
