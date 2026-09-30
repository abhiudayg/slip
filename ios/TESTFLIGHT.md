# Slip — TestFlight checklist

Team **9HSMVVUMVX** · Bundle IDs `com.aeswibon.slip` + `com.aeswibon.slip.share` · App Group `group.com.aeswibon.slip` · iCloud `iCloud.com.aeswibon.slip`

API (Release): `http://161.33.86.15:8080` (ATS exception for that host). Version **1.0.0 (2)**.

## One-time in Apple Developer / App Store Connect

1. Xcode → Settings → Accounts → sign in with the Apple ID for team `9HSMVVUMVX`.
2. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list):
   - App IDs: `com.aeswibon.slip`, `com.aeswibon.slip.share`
   - Capabilities on main app: **App Groups**, **iCloud (CloudKit)**
   - App Group: `group.com.aeswibon.slip` on both IDs
   - CloudKit container: `iCloud.com.aeswibon.slip`
3. In [App Store Connect](https://appstoreconnect.apple.com):
   - Create app **Slip** (bundle `com.aeswibon.slip`), platforms iOS
   - Add yourself as Internal Testing user (same Apple ID as the iPhone)
4. On the iPhone: install **TestFlight**, accept the invite when the build is ready.

## Archive & upload (Xcode UI — recommended)

```bash
cd ios && xcodegen generate   # if you use XcodeGen
open Slip.xcodeproj
```

1. Select scheme **Slip**, destination **Any iOS Device (arm64)**.
2. Product → Archive.
3. Organizer → Distribute App → **App Store Connect** → Upload.
4. Wait for processing → TestFlight → Internal Testing → add build → Install on iPhone.

## Archive from CLI

```bash
cd ios
chmod +x scripts/archive-testflight.sh
./scripts/archive-testflight.sh
# optional upload after ASC credentials are set up:
# UPLOAD=1 ./scripts/archive-testflight.sh
```

## Notes

- Share Extension version must stay in sync with the app (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`).
- Export compliance is set to non-exempt-encryption **false** (`ITSAppUsesNonExemptEncryption`).
- For production later, put pass-engine behind HTTPS and remove the ATS IP exception.
- Wallet / PassKit “Add to Wallet” works without a special Pass Type ID for *consuming* `.pkpass` files; Apple signing certs are only required on the **server** for real signatures (dev mode still packages unsigned-style passes for testing).
