# Slip — Advanced Apple Wallet features

## 1. Pass signing (`.pkpass`) — **shipped**

Slip already signs Wallet passes via **pass-engine** (Spring Boot on OCI Always Free), not a local mock:

- iOS → `POST /v1/passes` with template + fields  
- Server builds `pass.json`, assets, `manifest.json`, PKCS#7 `signature` (Pass Type ID `.p12` + WWDR)  
- Returns `application/vnd.apple.pkpass` → native `PKAddPassesViewController`

Optional edge: `deploy/cloudflare-worker/` proxies `/v1/passes` to the OCI origin (no certs on the Worker).

**Do not** put the `.p12` in the iOS app or a Worker that stores secrets in plaintext.

## 2. Apple VAS (NFC) — **scaffolded, entitlement-gated**

Mockups show “Hold Near Reader” / VAS. Real NFC in Wallet requires Apple’s **NFC / VAS entitlement**.

When approved, set:

```bash
SLIP_NFC_ENCRYPTION_PUBLIC_KEY=<base64 EC public key from Apple>
```

pass-engine then injects an `nfc` dictionary for `airbnb`, `zoomcar`, and `district` passes (`message` = booking id / door pin / QR payload). Without the key, templates stay barcode-only (valid Wallet passes).

Apply via [Apple Developer → Identifiers → Pass Type IDs](https://developer.apple.com/contact/request/wallet/) / Wallet NFC request.

## 3. Live Activities + ActivityKit push — **client wired**

- App requests Live Activities with `pushType: .token` and registers the push token at `POST /v1/live-activities`.
- Gate / delay updates still apply while the app is active (`LiveStatusService`).
- Background Island updates need APNs with Live Activity topic (`<bundleId>.push-type.liveactivity`) and your AuthKey — see endpoint stub + payload shape in pass-engine `LiveActivityController`.

## 4. App Clip share — **on-ramp ready**

Share links include:

- `slip://import/<token>` (full app)  
- `https://slip.app/import/<token>` (Universal Link / App Clip invocation once AASA + App Clip target are live)

Sources live under `ios/SlipAppClip/`. Add an App Clip target in Xcode pointing at that folder, enable Associated Domains (`applinks:slip.app`, `appclips:slip.app`), and host `apple-app-site-association`.


## 5. PassKit `webServiceURL` (auto-updating Wallet)

Set `SLIP_WEB_SERVICE_URL=https://your-host/passkit` (no trailing slash). New `.pkpass` files include `webServiceURL` + `authenticationToken`.

Wallet registers at:
- `POST /passkit/v1/devices/{deviceLibraryId}/registrations/{passTypeId}/{serial}`
- `GET /passkit/v1/passes/{passTypeId}/{serial}` (Authorization: `ApplePass <token>`)

Ops: `POST /passkit/v1/admin/passes/{serial}/update` with `{ "fields": { "gate": "14A" } }`, then send an **empty APNs** to the device push tokens so Wallet pulls the new pass. Native Wallet notifies *"Gate changed…"*.

## 6. Identity vault & DigiLocker

Slip encrypts masked Aadhaar / PAN / DL locally (AES-GCM). Swipe the live pass in Pass Details to show ID. Full DigiLocker OAuth needs UIDAI / ASC approval — vault is the secure on-device interim.

## 7. UPI Pay Now

Back-of-pass and UPI / dining surfaces open `upi://pay?…` (or the pass QR if already a UPI URI).

## 8. Insights

Dashboard → Insights (ex-Scrapbook): Wrapped narrative, flight/movie/dining counts, estimated Dineout savings, shareable text card.
