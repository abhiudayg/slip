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

## 3. Pass Type ID certificate (Wallet signing)

On the VM (`/opt/slip/certs/` + `/opt/slip/etc/pass-engine.env`):

```bash
source deploy/oci/state.env
scp /path/to/pass_cert.p12 /path/to/AppleWWDRCAG4.cer ubuntu@$PUBLIC_IP:/opt/slip/certs/
ssh ubuntu@$PUBLIC_IP 'sudo chown slip:slip /opt/slip/certs/pass_cert.p12 /opt/slip/certs/AppleWWDRCAG4.cer && sudo chmod 600 /opt/slip/certs/pass_cert.p12'
```

Set in `/opt/slip/etc/pass-engine.env` (never commit):

- `PASS_ENGINE_DEV_MODE=false`
- `PASS_TYPE_IDENTIFIER=pass.com.aeswibon.slip`
- `TEAM_IDENTIFIER=9HSMVVUMVX`
- `PASS_CERTIFICATE_PATH=/opt/slip/certs/pass_cert.p12`
- `PASS_CERTIFICATE_PASSWORD=...`
- `WWDR_CERTIFICATE_PATH=/opt/slip/certs/AppleWWDRCAG4.cer`

Then `sudo systemctl restart slip-pass-engine`. Health should report `"devMode":false`. A `/v1/passes` response `.pkpass` must contain a non-empty `signature`.

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
