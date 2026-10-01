# Slip App Clip

Lightweight invite surface for shared tickets (`https://slip.app/import/<token>`).

## Xcode setup (one-time)

1. File → New → Target → **App Clip**
2. Product Name: `SlipAppClip`, bundle id `com.aeswibon.slip.Clip`
3. Replace generated sources with this folder (or add these files to the target)
4. Embed App Clip in the Slip app target
5. Associated Domains on **Slip** + **SlipAppClip**: `applinks:slip.app`, `appclips:slip.app`
6. Host `/.well-known/apple-app-site-association` (see `docs/aasa/apple-app-site-association`)

App Clip size budget is tight — share `SlipShared` + `PassAPIClient` / `AddToWalletButton` only; avoid vault / Vision / full Marketplace.
