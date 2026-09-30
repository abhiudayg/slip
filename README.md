# Slip

**Digital Passes & QR Wallet** — turn messy Indian QR codes and tickets into lock-screen-ready Apple Wallet passes.

Cut QR present-time from ~15s to ~1s: double-click Side Button → Wallet.

## What’s in the repo

| Path | Role |
|------|------|
| `ios/` | Slip (SwiftUI) + Share Extension + on-device vault |
| `pass-engine/` | Spring Boot 3 / Java 21 ephemeral `.pkpass` signer |
| `templates/` | Brand boilerplates (`upi`, `cult`, `namma-metro`, …) |
| `stations/` | Metro station lat/lng for relevance |
| `deploy/oci/` | Always Free OCI + Neon deploy scripts |
| `docs/PRODUCT.md` | Product north star and locked decisions |

Default branch: **`master`**.

## Architecture (short)

- **iOS** gathers tickets (scanner, share sheet, PDF) and seals sensitive fields on-device (AES-256-GCM + Keychain / CloudKit).
- **pass-engine** injects fields into templates, builds a SHA-1 manifest, signs with PKCS#7, and returns a zip — **no pass vault on the server**.
- **Neon Postgres** (optional) holds brand catalog + stations; H2 is used for local defaults.

## Pass engine (local)

```bash
cd pass-engine
mvn spring-boot:run
# GET  http://localhost:8080/v1/brands
# GET  http://localhost:8080/v1/stations/namma-metro
# POST http://localhost:8080/v1/passes
```

Dev mode (`PASS_ENGINE_DEV_MODE=true`, default): packages `.pkpass` without Apple signing certs.

Production signing needs `PASS_TYPE_IDENTIFIER`, `TEAM_IDENTIFIER`, `PASS_CERTIFICATE_PATH`, `PASS_CERTIFICATE_PASSWORD`, and `WWDR_CERTIFICATE_PATH`.

For Neon, set `DATABASE_URL` (or `SPRING_PROFILES_ACTIVE=neon`). See `scripts/setup-neon.sh` and `deploy/README.md`.

### Example

```bash
curl -X POST http://localhost:8080/v1/passes \
  -H 'Content-Type: application/json' \
  -d '{"template":"upi","fields":{"name":"Abhiuday","qr_data":"upi://pay?pa=user@upi&pn=Abhiuday"}}' \
  --output upi.pkpass
```

## iOS (Slip)

1. Open `ios/Slip.xcodeproj` in Xcode 16+.
2. Set your Team and App Group `group.com.aeswibon.slip`.
3. Point `SlipAPIBaseURL` in `Info.plist` at pass-engine (local or OCI).
4. Run on a device for Share Extension + Wallet flows.

## Deploy (OCI Always Free + Neon)

Scripts under `deploy/oci/` provision a free-tier VM and wire Neon. Secrets (`deploy/oci/.env.neon`, `state.env`) are gitignored — never commit them.

```bash
# After Neon + OCI CLI are configured:
./scripts/setup-neon.sh
./deploy/oci/provision.sh   # or follow deploy/README.md
./deploy/oci/deploy-app.sh
```

## MVP brands

| Brand | Template id | Pass style |
|-------|-------------|------------|
| UPI (Get Paid) | `upi` | generic |
| Cult.fit | `cult` | storeCard |
| Namma Metro | `namma-metro` | boardingPass |
| BookMyShow | `bookmyshow` | eventTicket |
| Indigo / IRCTC | `indigo` / `irctc` | boardingPass |

## License

Personal / experimental — rights reserved unless stated otherwise.
