# Multi-stage image for Slip pass-engine (Always Free / GHCR).
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pass-engine/pom.xml pass-engine/pom.xml
COPY pass-engine/src pass-engine/src
COPY templates /src/templates
COPY stations /src/stations
WORKDIR /src/pass-engine
RUN mvn -B -DskipTests package \
 && JAR=$(ls target/pass-engine-*.jar | head -1) \
 && cp "$JAR" /src/pass-engine.jar

FROM eclipse-temurin:21-jre-jammy
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -u 10001 slip
WORKDIR /opt/slip
COPY --from=build /src/pass-engine.jar /opt/slip/bin/pass-engine.jar
COPY --from=build /src/templates /opt/slip/templates
COPY --from=build /src/stations /opt/slip/stations
RUN mkdir -p /opt/slip/bin /opt/slip/certs && chown -R slip:slip /opt/slip
USER slip
ENV SLIP_TEMPLATES_DIR=/opt/slip/templates \
    SLIP_STATIONS_DIR=/opt/slip/stations \
    SERVER_PORT=8080 \
    PASS_ENGINE_DEV_MODE=true
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/v1/health || exit 1
ENTRYPOINT ["java","-Xms128m","-Xmx384m","-jar","/opt/slip/bin/pass-engine.jar"]
