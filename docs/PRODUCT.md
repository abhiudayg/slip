# Slip

**App Store name:** Slip  
**Subtitle:** Digital Passes & QR Wallet

Paper transit slips and receipts, modernized into digital glass cards in Apple Wallet.

## North star

Cut QR present-time for Indian iPhone users from ~15s to ~1s (double-click Side Button → Wallet).

## Locked decisions

- No freeform canvas; Apple PassKit zones only
- No DIY branding; brand grid only
- iOS gathers data; Spring Boot signs `.pkpass` **ephemerally** (no pass vault DB on server)
- Templates are boilerplates under `templates/{id}/`
- **Security (1C + iCloud):** Sensitive pass payloads sealed on-device with AES-256-GCM; master key syncs via iCloud Keychain; ciphertext syncs via CloudKit private DB. pass-engine never persists QR/PNR/UPI fields.

## MVP brand pack

| Brand | Template id | Apple style |
|-------|-------------|-------------|
| UPI (Get Paid) | `upi` | generic |
| Cult.fit | `cult` | storeCard |
| Namma Metro | `namma-metro` | boardingPass |
| BookMyShow | `bookmyshow` | eventTicket |

## Pillars

1. **Ingestion** — Share Extension, live scanner, minimal brand fields
2. **Context** — `locations` (metro), `relevantDate` (events)
3. **Engine** — inject into boilerplate → SHA-1 manifest → BouncyCastle PKCS#7 → zip (in-memory only)
4. **Vault** — CryptoKit + Keychain + CloudKit ciphertext mirror; PassKit remains presentation custody after Add to Wallet
