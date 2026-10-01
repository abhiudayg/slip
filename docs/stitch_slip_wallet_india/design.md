# Slip Wallet App - Comprehensive UI/UX Definition

## 1. Global Design System & Aesthetics
**Theme:** Exclusively Dark Mode. High-end, premium, and native iOS feel.
**Backgrounds:** 
- `MeshBackground`: A subtle, slowly animating mesh gradient used as the root background for the main app navigation screens.
- `SoftDivider`: 1px dividers with 12% opacity of th pass' y accent color to separate content blocks elegantly without harsh lines.
**Typography:** 
- Clean, Apple-esque typography (San Francisco / SF Pro).
- Prominent use of Monospaced fonts for numbers, PNRs, booking IDs, and timings to mimic physical printed tickets.
**Visual Effects:** Glassmorphism, frosted glass backgrounds for floating elements, subtle drop shadows (`radius: 20, y: 10, opacity: 0.3`), and heavy use of SF Symbols.

---

## 2. Core Navigation & Shell
### `ContentView` (Root Container)
- Houses the `MeshBackground` and acts as the router.
- Features a **`FloatingDock`** at the bottom of the screen (similar to the iPad dock or macOS dock) rather than a standard iOS TabBar.
- **Dock Items:** Home (Dashboard), Scan/Import (prominent center button), Marketplace (Discover), Settings.

---

## 3. Main Screens (Macro UI)

### 1. `DashboardView` (My Passes Hub)
- **Layout:** Vertical `ScrollView` hiding indicators.
- **Content:** 
  - A greeting/header at the top.
  - A segmented layout organizing passes by state: **Active** (upcoming trips/events) and **Expired** (past events).
  - Passes are rendered as overlapping or stacked cards (similar to native Apple Wallet). Tapping a pass expands it to `PassDetailsView`.

### 2. `MarketplaceView`
- **Layout:** Grid or List view.
- **Content:** 
  - A catalog of supported brands (Indigo, IRCTC, BookMyShow, Zomato, etc.).
  - Users can tap a brand to see its styling and trigger a manual pass creation flow.
  - Features prominent buttons for **"Scan Screenshot"** or **"Import PDF"**.

### 3. `PassDetailsView` & `ConfirmPassSheet`
- **Layout:** A full-screen modal or pushed view.
- **Content:**
  - A translucent blurred background.
  - The actual Pass Card rendered in the center.
  - "Add to Wallet" standard Apple button at the bottom (or "Delete" if already saved).
  - `PassMetaBar` floating just above the card, showing the PassKit style and NFC compatibility tag.

### 4. `LiveScannerView`
- **Content:** Camera viewfinder covering the screen, with a dark overlay and a clear cutout bounding box in the center for scanning QR/Barcodes. Animated scanning laser line.

---

## 4. Pass Card Templates (Micro UI)
All passes are built using a composable container system that mimics physical constraints.

### A. The Container Shells
1. **`PassShell` (Classic Layout):**
   - Solid rounded rectangle.
   - Side semi-circle notches just above the barcode area (to mimic a tear-off stub).
   - Optional `appIcon` floating in the bottom-left corner of the card.
2. **`EventTicketShell` (Modern Layout):**
   - Distinctive **top-center semi-circle cutout** (mimicking a lanyard hole).
   - Supports a floating `appIcon` on the left.
   - Clean continuous body, no side notches.

### B. Core Card Components
- **`BrandHeaderRow` / `EventTicketHeader`:** Located at the top. Contains the Brand Name, a subtitle (e.g., "Room Key & Access"), and an optional right-aligned status pill (e.g., "ACTIVE").
- **`StripHero`:** A horizontal hero banner. Can contain:
  - A solid gradient block.
  - A large `SF Symbol` (e.g., a wineglass, car, or bed) rendered as a frosted glass thumbnail on the right side.
  - High-contrast text overlay (e.g., the Property Name or Event Name).
- **`FieldBlock`:** The fundamental data unit. Contains a small, uppercase label (e.g., "CHECK-IN", "PNR") in a muted color, and a large value string below it in bright white. Used in `HStack` grids.
- **`QRPanel` / `NFCPanel`:** Housed at the bottom of the card on a white rounded square backing. Shows the QR code and a small string of text (e.g., "HM2ZH3CRTT") underneath.

---

## 5. Specific Brand Implementations (To be generated)

### 1. `BoardingCard` (Transit: Indigo, IRCTC, Namma Metro, RedBus)
- **Container:** `PassShell` (Side notches).
- **Visuals:** Top left brand logo. Large Origin -> Destination text. 
- **Grid:** Departure Time, Arrival Time, Terminal, Seat/Class, PNR.
- **Iconography:** A floating transport icon (airplane, train, bus) overlaying the QR code section.

### 2. `EventTicket` (Entertainment: BookMyShow, District)
- **Container:** `EventTicketShell` (Top notch).
- **Hero:** Vibrant gradient banner with the Movie/Festival name.
- **Grid:** Venue, Showtime, Seats, Booking ID.

### 3. `DiningCard` (Zomato, Swiggy Dineout, EazyDiner)
- **Container:** `EventTicketShell` (Top notch).
- **Hero:** Frosted wineglass thumbnail (`wineglass.fill`). Large Restaurant Name.
- **Grid:** Reservation Time, Guests, Discount code.

### 4. `ZoomcarKeylessCard` (Mobility)
- **Container:** `EventTicketShell`.
- **Hero:** Frosted car thumbnail (`car.side.fill`).
- **Grid:** Pickup time, Drop-off time, Vehicle Reg Number, PIN.
- **Interactivity:** Mentions "Hold Near Reader" for Apple VAS NFC unlocking.

### 5. `UPIPayPassCard` (Payments)
- **Container:** `EventTicketShell`.
- **Hero:** Frosted QR thumbnail (`qrcode`). 
- **Grid:** Account Holder, VPA (UPI ID), Linked Bank, Txn Limit.
