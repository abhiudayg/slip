# Slip

**App Store name:** Slip  
**Subtitle:** Digital Passes & QR Wallet

Paper transit slips and receipts, modernized into digital glass cards in Apple Wallet.

## North star

Cut QR present-time for Indian iPhone users from ~15s to ~1s (double-click Side Button → Wallet).

## Locked decisions

- Always free — no Pro / paid subscription tier
- iOS (iPhone) only for v1; Android and desktop are out of scope initially
- No freeform canvas; Apple PassKit zones only
- No DIY branding; brand grid only
- iOS gathers data; Spring Boot signs `.pkpass` **ephemerally** (no pass vault DB on server)
- Templates are boilerplates under `templates/{id}/`
- **Security (1C + iCloud):** Sensitive pass payloads sealed on-device with AES-256-GCM; master key syncs via iCloud Keychain; ciphertext syncs via CloudKit private DB. pass-engine never persists QR/PNR/UPI fields.

## Default brand pack

| Brand | Template id | Apple style |
|-------|-------------|-------------|
| IRCTC Rail | `irctc` | boardingPass |
| BookMyShow | `bookmyshow` | eventTicket |
| District | `district` | eventTicket |
| IndiGo | `indigo` | boardingPass |
| EazyDiner | `easydiner` | storeCard |
| Zomato Dineout | `zomato-dineout` | eventTicket |
| Swiggy Dineout | `swiggy-dineout` | eventTicket |
| Airbnb | `airbnb` | storeCard |
| Namma Metro | `namma-metro` | boardingPass |
| UPI (Get Paid) | `upi` | generic |
| redBus | `redbus` | boardingPass |
| Zoomcar | `zoomcar` | generic |

## Pillars

1. **Ingestion** — Share Extension, live scanner, minimal brand fields
2. **Context** — `locations` (metro), `relevantDate` (events)
3. **Engine** — inject into boilerplate → SHA-1 manifest → BouncyCastle PKCS#7 → zip (in-memory only)
4. **Vault** — CryptoKit + Keychain + CloudKit ciphertext mirror; PassKit remains presentation custody after Add to Wallet
