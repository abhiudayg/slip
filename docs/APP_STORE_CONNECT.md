# Slip — App Store Connect & TestFlight copy

Copy-paste ready text for TestFlight Beta App Information, App Review Notes, Custom EULA clauses, and metadata.

**Current product context (keep this doc in sync):**
- Bundle: `com.aeswibon.slip` (+ Share Extension `com.aeswibon.slip.share`)
- Deployment target: **iOS 17+** (UI marketing may say “iOS 26” Liquid Glass; on-device Foundation Models / `@Generable` paths are gated to iOS 26 when available, with Vision + rule-based classifiers as fallback)
- Default brand pack: IRCTC, BookMyShow, District, IndiGo, EazyDiner, Zomato Dineout, Swiggy Dineout, Airbnb, Namma Metro, UPI PayPass, redBus, Zoomcar (Cult.fit is **not** in the shipped catalog)
- Import: Scan QR/barcode, Photo/screenshot, PDF booking, Browse templates
- Vault: on-device AES-GCM + Keychain/CloudKit; pass-engine signs `.pkpass` ephemerally (no QR/PNR vault on server)
- Triggers: per-pass **Location** (geocode / lat-lon / metro stations) + optional Live Activity / Dynamic Island
- Multi-traveler: IRCTC / IndiGo party tickets can become **N** separate Wallet passes
- Wallet identity: regenerate **updates** an existing pass when the PassKit serial is reused

**Subtitle (App Store):** `Digital Passes & QR Wallet` (29 / 30 characters)

---

## 1. TestFlight — Beta App Information

### Beta App Description

Slip turns everyday Indian tickets and QR codes into native Apple Wallet passes — metro rides, rail and flight PNRs, cinema and festival tickets, dining reservations, Airbnb stay keys, redBus, Zoomcar, and personal UPI PayPasses.

Import a screenshot, booking PDF, or live scan. Vision (and on-device ML when available) classifies the brand and fills Stitch-aligned Wallet fields. Add to Apple Wallet, then surface the pass near a venue with GPS geofencing or around showtime / departure via Live Activities.

Passes stay in your on-device vault (encrypted). Only extracted text and QR payloads are sent to Slip’s pass-engine to mint a cryptographically signed `.pkpass` — images are not uploaded.

### What to Test

* **Import ticket menu:** From **+ New Pass**, open **Import ticket** and try **Scan QR / barcode**, **Photo / screenshot**, **PDF booking**, and **Browse templates**. Confirm the dimmed backdrop dismisses on outside tap.
* **Screenshot / Share Sheet:** Save a sample Airbnb, BookMyShow, IRCTC, IndiGo, or Namma Metro screenshot (or PDF) to Photos. Share → **Slip** (or import in-app) and verify brand auto-match + field extraction.
* **Multi-traveler:** Import an IRCTC or IndiGo booking with multiple passengers; confirm Slip offers separate passes per traveler.
* **Wallet integration:** Edit fields / location if needed → **Generate Pass** / **Create Pass** → native `PKAddPassesViewController`. Regenerate the same vault pass and confirm Wallet **updates** instead of duplicating (when signing certs are live).
* **Location geofence:** On Pass Details, set **Location** (or lat/lon), enable Lock Screen auto-surface with Always location, then simulate the region in Xcode and confirm notification / surfacing behavior.
* **Live Activity (optional):** Toggle Live Activity on confirm / details for time-based Dynamic Island surfacing where supported.
* **UI:** Liquid Glass dock, mesh backgrounds, and Stitch-faithful Wallet previews across iPhone sizes.

### Feedback Email

`beta-feedback@slipapp.in` *(replace with your real inbox before submit)*

---

## 2. App Store Connect — App Review Information

### Sign-In Information

* **Sign-in required:** **No** (unchecked). Core import → classify → generate → Add to Wallet works without an account.

### Notes to App Review

Hello App Review Team,

Slip is a local utility that helps users format **their own** ticket QR codes and booking text into Apple Wallet `.pkpass` files. Please note:

**1. No account required (Guideline 5.1.1)**  
Users can import, edit, vault, and add passes anonymously. There is no account wall for core functionality.

**2. Intellectual property & brand names (Guideline 5.2)**  
Slip ships templates optimized for common Indian services (for example IRCTC, BookMyShow, District, IndiGo, EazyDiner, Zomato Dineout, Swiggy Dineout, Airbnb, Namma Metro, UPI, redBus, Zoomcar). **Slip is not affiliated with, endorsed by, or partnered with these companies.**  
The app is a user-driven formatting tool: the user supplies data from tickets they already hold; Slip maps that data into standard PassKit layouts. A “No Affiliation” disclaimer appears in the App Description and Custom EULA.

**3. Privacy & on-device processing (Guideline 5.1)**  
Screenshot / PDF / camera ingestion uses Apple’s on-device **Vision** (and, on supported OS versions, on-device language / Foundation Models). **Images are not uploaded.** Only extracted strings (QR payload and structured fields the user confirms) are sent to our pass-engine so it can return a signed `.pkpass`. Sensitive vault ciphertext stays on device (Keychain / CloudKit private DB); the server does not retain pass field vaults.

**4. Location (Guideline 5.1.5)**  
Optional **Always** location is used only when the user enables Lock Screen auto-surface / geofencing for a pass they labeled with a venue location. Deny-location still allows full Wallet generation.

**5. How to test without Indian transit apps**  
Attach a ZIP of sample screenshots / PDFs (Airbnb reservation, BookMyShow, IRCTC, IndiGo, Namma Metro, UPI QR, etc.):

1. Save samples to Photos (or Files for PDFs).  
2. Open Slip → **+ New Pass** → **Import ticket** → Photo / PDF (or Share Sheet → Slip).  
3. Confirm classification → **Create / Generate Pass** → `PKAddPassesViewController`.  
4. Optionally set **Location** on Pass Details and enable auto-surface to exercise geofence prompts.

Thank you for your time.

---

## 3. Custom EULA clauses (App Store Connect → App Information → License Agreement)

Use a Custom EULA (do not rely only on Apple’s Standard EULA). Append at least:

### Disclaimer of Affiliation and Third-Party Trademarks

> Slip is an independent utility application. Slip is not affiliated with, endorsed by, sponsored by, or officially connected to any third-party brands, transit authorities, airlines, hotels, dining platforms, or corporations whose names, logos, or templates may appear within the app (including, but not limited to, IRCTC, BookMyShow, District by Zomato, IndiGo, EazyDiner, Zomato, Swiggy, Airbnb, Namma Metro / BMRCL, NPCI / UPI participating banks, redBus, Zoomcar, and similar services).  
> All product and company names are trademarks™ or registered® trademarks of their respective holders. Use of these names within Slip is solely to help the end user identify and format their own personal, lawfully acquired data for Apple Wallet.

### User Responsibility for Data and Ticket Validity

> Slip formats QR codes and booking text into PassKit files. Slip does not verify validity, payment status, or acceptance of any ticket. The user is solely responsible for merchant / transit / venue acceptance. Slip is not liable for denied entry, missed travel, or losses arising from generated passes.

### Apple Wallet Disclaimer (required)

> “Apple”, “Apple Watch”, “iPhone”, “Apple Wallet”, and “PassKit” are trademarks of Apple Inc., registered in the U.S. and other countries and regions.

---

## 4. Suggested App Description (store listing)

**Promotional text** *(optional, updatable without a new build)*  
Turn screenshots and booking PDFs into lock-screen Apple Wallet passes — metro, rail, flights, cinema, stays, UPI, and more.

**Description**

Slip is Digital Passes & QR Wallet for India.

Stop digging through Photos at the turnstile. Import a screenshot, PDF, or live QR scan. Slip classifies the brand on-device, fills Wallet fields, and helps you Add to Apple Wallet — with optional GPS and time-based surfacing.

Includes templates for IRCTC, BookMyShow, District, IndiGo, EazyDiner, Zomato Dineout, Swiggy Dineout, Airbnb, Namma Metro, UPI PayPass, redBus, and Zoomcar. Not affiliated with those brands — you bring your own tickets; Slip only formats them.

• Import: scan, photo, PDF, or pick a template  
• On-device Vision (images stay on your iPhone)  
• Encrypted on-device vault  
• Location-aware Lock Screen triggers  
• Multi-passenger bookings → separate passes  

Always free. iPhone only.

**Keywords** *(100 char max — tune as needed)*  
```
wallet,pass,qr,metro,irctc,indigo,upi,ticket,passkit,india,boarding,cinema
```

---

## 5. Reviewer attachment checklist

Prepare `Slip-AppReview-Samples.zip` with anonymized samples:

| Sample | Purpose |
|--------|---------|
| Namma Metro QR screenshot | Transit boardingPass + station geofence |
| BookMyShow / District ticket | eventTicket seats / showtime |
| IRCTC e-ticket PDF or screenshot | Multi-passenger split |
| IndiGo boarding stub | Flight fields |
| Airbnb reservation PDF | storeCard room-key fields |
| UPI collect QR | PayPass |

Include a one-page `README.txt` in the ZIP mirroring the “How to test” steps above.
