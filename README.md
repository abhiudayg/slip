# Slip

**Digital Passes & QR Wallet** — turn messy Indian QR codes into lock-screen-ready Apple Wallet passes.

## Layout

```
wallet-india/          # repo folder
  ios/                 # Slip (SwiftUI) + Share Extension
  pass-engine/         # Spring Boot 3 / Java 21 signer
  templates/           # Brand boilerplates
  stations/            # Namma Metro lat/lng
  docs/PRODUCT.md
```

## Pass engine

```bash
cd pass-engine
mvn spring-boot:run
# POST http://localhost:8080/v1/passes
```

Dev mode (`PASS_ENGINE_DEV_MODE=true`, default): packages `.pkpass` without Apple certs.

Production: set `PASS_TYPE_IDENTIFIER`, `TEAM_IDENTIFIER`, `PASS_CERTIFICATE_PATH`, `PASS_CERTIFICATE_PASSWORD`, `WWDR_CERTIFICATE_PATH`.

## iOS (Slip)

Open `ios/Slip.xcodeproj` in Xcode 16+, set Team + App Group `group.com.aeswibon.slip`, run on device.

## Example

```bash
curl -X POST http://localhost:8080/v1/passes \
  -H 'Content-Type: application/json' \
  -d '{"template":"upi","fields":{"name":"Abhiuday","qr_data":"upi://pay?pa=user@upi&pn=Abhiuday"}}' \
  --output upi.pkpass
```
