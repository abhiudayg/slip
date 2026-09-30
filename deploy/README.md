# Slip pass-engine — Neon + OCI Always Free

## Architecture

- **Compute**: Oracle Cloud Always Free `VM.Standard.A1.Flex` (Ampere)
- **Database**: [Neon](https://neon.tech) serverless Postgres (`brands`, `stations`, `pass_build_events`)
- **Pass assets**: still on disk (`templates/`, PNG/pass.json) — never store QR/PNR field bodies in Neon

## 1. Neon

```bash
brew install neonctl   # if needed
./scripts/setup-neon.sh
```

Creates `deploy/oci/.env.neon` with `DATABASE_URL` (gitignored).

## 2. OCI CLI

```bash
brew install oci-cli
./scripts/setup-oci.sh
```

Then:

```bash
export COMPARTMENT_ID=ocid1.compartment...
export AVAILABILITY_DOMAIN="$(oci iam availability-domain list -c "$COMPARTMENT_ID" --query 'data[0].name' --raw-output)"
source deploy/oci/.env.neon
./deploy/oci/provision.sh
./deploy/oci/deploy-app.sh
```

## 3. Local with Neon

```bash
source deploy/oci/.env.neon
export SPRING_PROFILES_ACTIVE=neon
export FLYWAY_ENABLED=true
export JPA_DDL_AUTO=validate
export DATABASE_DRIVER=org.postgresql.Driver
cd pass-engine && mvn spring-boot:run
```

Without Neon, local defaults to embedded H2 and file-based catalogs.
