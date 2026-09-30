---
name: Gatepass Studio
colors:
  surface: '#11131d'
  surface-dim: '#11131d'
  surface-bright: '#373944'
  surface-container-lowest: '#0b0e18'
  surface-container-low: '#191b26'
  surface-container: '#1d1f2a'
  surface-container-high: '#272935'
  surface-container-highest: '#323440'
  on-surface: '#e1e1f1'
  on-surface-variant: '#ccc3d8'
  inverse-surface: '#e1e1f1'
  inverse-on-surface: '#2e303b'
  outline: '#958da1'
  outline-variant: '#4a4455'
  surface-tint: '#d2bbff'
  primary: '#d2bbff'
  on-primary: '#3f008e'
  primary-container: '#7c3aed'
  on-primary-container: '#ede0ff'
  inverse-primary: '#732ee4'
  secondary: '#93ccff'
  on-secondary: '#003351'
  secondary-container: '#3198dc'
  on-secondary-container: '#002c47'
  tertiary: '#ffb2bd'
  on-tertiary: '#670024'
  tertiary-container: '#cc0050'
  on-tertiary-container: '#ffdee1'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#eaddff'
  primary-fixed-dim: '#d2bbff'
  on-primary-fixed: '#25005a'
  on-primary-fixed-variant: '#5a00c6'
  secondary-fixed: '#cce5ff'
  secondary-fixed-dim: '#93ccff'
  on-secondary-fixed: '#001d31'
  on-secondary-fixed-variant: '#004b73'
  tertiary-fixed: '#ffd9dd'
  tertiary-fixed-dim: '#ffb2bd'
  on-tertiary-fixed: '#400014'
  on-tertiary-fixed-variant: '#900036'
  background: '#11131d'
  on-background: '#e1e1f1'
  surface-variant: '#323440'
typography:
  display-hero:
    fontFamily: Inter
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.03em
  display-hero-mobile:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 42px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.06em
  label-numeric:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: -0.01em
  label-token:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  gutter-lg: 1.5rem
  margin: 1.25rem
  margin-sm: 1rem
  margin-lg: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies an ultra-luxurious, futuristic vision of native iOS digital credentials, pairing native glassmorphic depth with high-contrast metropolitan transit accents. Designed for high-frequency urban explorers, daily transit riders, and executive travelers, the interface evokes the tactile prestige of a physical titanium luxury card fused with liquid-smooth optical refraction.

The personality is hyper-precise, quiet, and authoritative. Backgrounds remain deep in the obsidian spectrum, allowing vibrant Indian transit and lifestyle signifiers—such as Bangalore Metro Purple, IRCTC Rail Blue, and IndiGo Blue—to command focus without visual noise.

Key tenets:
- **Liquid Optical Clarity:** Frosted surfaces emulate 30px optical blurs that separate dynamic backgrounds from active controls.
- **Strict Single-Surface Depth:** Zero glass-on-glass stacking; components exist either directly within the root canvas or as cleanly elevated single-layer dynamic lenses.
- **Ergonomic Reachability:** Primary interactions dock within the lower 40% of the viewport for effortless one-handed thumb interaction.
- **Specular Precision:** Every card and floating sheet features a delicate, hairline highlight that grounds the structural boundary against the midnight base.

## Colors

The palette operates in strict dark mode, anchored by deep midnight obsidian gradients overlaid with high-luminance functional accents.

### Core Canvas & Surfaces
- **Canvas Base:** `#070913` transitioning diagonally to `#120E2E` via an ambient gradient mesh.
- **Glass Fill Base:** `rgba(18, 14, 46, 0.65)` layered with `backdrop-filter: blur(30px)`.
- **Specular Border Stroke:** `rgba(255, 255, 255, 0.18)` applied as an interior 1px hairline boundary.
- **Surface Elevation High:** `rgba(255, 255, 255, 0.08)` for active controls and pill segments.

### Transit & Identity Accents
- **BMRCL Purple (`primary`):** `#7C3AED` — Metro validations, terminal gates, primary confirmations.
- **IndiGo Carrier Blue (`secondary`):** `#0284C7` — Boarding privileges, gate departures, active flight nodes.
- **Cult.fit Neon Pink (`tertiary`):** `#FF1168` — Fitness privileges, club memberships, access alerts.
- **IRCTC Rail Blue:** `#2563EB` — Platform reservations, train coach manifests.
- **Transit Amber:** `#F59E0B` — Live delays, gate changes, security scan warnings.
- **Clearance Emerald:** `#10B981` — Successful tap-and-go passes, valid biometric verification.

### Typography & Icon Tones
- **Primary Text:** `#FFFFFF` (100% white) for highest contrast against midnight backdrops.
- **Secondary Text:** `rgba(255, 255, 255, 0.64)` for metadata, labels, and timestamps.
- **Tertiary Text:** `rgba(255, 255, 255, 0.40)` for disabled states and hairline track indicators.

## Typography

Typography prioritizes micro-legibility under direct sunlight and high-speed motion (e.g., passing through a metro turnstile). Inter serves as the foundation across display, structural, and numeric data to ensure crisp rendering across all screen densities.

### Hierarchy & Usage
- **Hero & Display (`display-hero`):** Reserved for primary credentials, real-time balance totals, or terminal seat codes.
- **Structural Sectioning (`headline-md`, `headline-sm`):** Delineates credential sections, barcode groups, and carrier manifests.
- **Data & Numeric Pairs (`label-caps` + `label-numeric`):** Always used in paired stacks for metadata (e.g., `GATE`, `SEAT`, `PLATFORM`, `PNR`). The `label-caps` level must always be presented in uppercase with positive letter spacing (+0.06em) in secondary white (`rgba(255,255,255,0.64)`).
- **Tabular Tokens (`label-token`):** Applied to alphanumeric flight codes, train numbers, and hex credentials.

## Layout & Spacing

The layout model is anchored to a 4-column fluid mobile grid scaling to an 8-column layout on larger viewing panels. The interface is engineered around modern iOS home indicators and Dynamic Island safe zones.

### Breakpoint Scaling
- **Compact Viewport (360px - 430px):** Single vertical stack with `margin: 1.25rem` and `gutter: 1rem`. Wallet cards consume 100% of the column width.
- **Expanded Mobile / Tablet (431px - 768px):** Dual card column grid with `margin: 1.5rem` and `gutter: 1.25rem`. Secondary floating actions switch from pinned sheets to inline horizontal toolbars.
- **Studio Canvas (> 768px):** Centered phone-canvas container (max width 440px) surrounded by inspector sidecars.

### Spatial Discipline
- **Pass Separation:** Stacked wallet cards use an overlap offset of `3.25rem`, revealing the primary header, transit icon, and route metadata of each pass.
- **Ergonomic Safe Zone:** Interactive CTAs must maintain a minimum distance of `2rem` (`space-xl`) above the device bottom safe boundary to avoid home bar interference.

## Elevation & Depth

This design system avoids traditional dropped mud-shadows, achieving visual hierarchy strictly through liquid refraction, luminosity tiers, and specular boundaries.

### Optical Refraction & Glass Rules
- **Base Glass (`Elevation 1`):** `rgba(255, 255, 255, 0.05)` fill with `backdrop-filter: blur(30px)` and an interior highlight border `1px solid rgba(255, 255, 255, 0.14)`.
- **Floating Controls (`Elevation 2`):** `rgba(255, 255, 255, 0.12)` fill with `backdrop-filter: blur(40px)`, cast over an ambient radial shadow: `0 12px 32px -4px rgba(0, 0, 0, 0.45)`. Specular highlight: `1px solid rgba(255, 255, 255, 0.28)`.
- **Zero Glass-on-Glass Rule:** Translucent glass containers must never sit directly atop another translucent glass container. If a nested element resides inside a glass card, it must use an opaque solid or flat tint fill (e.g., `rgba(255, 255, 255, 0.08)`) with zero backdrop filter.
- **Specular Highlight Gradient:** The 1px perimeter border is implemented as a top-to-bottom linear gradient: starting at `rgba(255, 255, 255, 0.24)` at the top edge and tapering to `rgba(255, 255, 255, 0.04)` at the bottom edge, simulating ceiling ambient light.

## Shapes

The shape visual language is soft, organic, and pill-dominant, reflecting modern handheld industrial design.

- **Pills (`roundedness: 3`):** Action buttons, status chips, segmented bars, and reachability floating docks use complete pill radiuses (`border-radius: 9999px` or minimum `1rem`).
- **Pass Envelopes (`rounded-lg`):** Standard pass modules and wallet cards utilize continuous curvature corner radiuses calibrated at `2rem` (32px), creating a physical token profile.
- **Sheet Overlays (`rounded-xl`):** Bottom interaction drawers and terminal security drawers employ `3rem` (48px) top radiuses.
- **Notches & Barcode Wells:** Dynamic punch-out notches on transit boarding cards mirror ticket perforations with circular cutouts using 16px radius.

## Components

### Buttons & Interactive Floating Pills
- **Primary CTA:** Pill shape (`9999px`), solid BMRCL Purple (`#7C3AED`) background, pure white label with high-contrast weight (`Inter 600`). In pressed states, scale smoothly to `0.97` with a brightness bump to 110%.
- **Liquid Floating Dock:** Floating reachability capsule docked at viewport bottom (`space-xl` margin). Holds icon triggers inside a unified frosted blur (`blur(32px)`) with hairline interior border (`rgba(255, 255, 255, 0.18)`).
- **Secondary Ghost Pill:** Transparent fill with `1px solid rgba(255, 255, 255, 0.18)`. Background shifts to `rgba(255, 255, 255, 0.06)` on touch.

### Credential Cards (Pass Modules)
- **Container Structure:** `32px` corner radius, `1px` specular border gradient. Background is a smooth vertical tint: `linear-gradient(180deg, rgba(255, 255, 255, 0.08) 0%, rgba(18, 14, 46, 0.85) 100%)`.
- **Accent Ribbon:** A crisp 3px vertical lead line or solid colored header strip carrying the transit authority brand color (e.g., IndiGo `#0284C7` or IRCTC `#2563EB`).
- **Perforated Tear Notch:** Visual punch-out positioned 70% down the card separating metadata from the Aztec/QR barcode chamber.

### Chips & Transit Status Badges
- **Status Pills:** Compact height (`28px`), padding `0.25rem 0.75rem`.
- **Active / Boarding:** Amber background tint (`rgba(245, 158, 11, 0.15)`) with solid Amber text (`#F59E0B`) and a 6px breathing status dot.
- **Verified / Cleared:** Emerald background tint (`rgba(16, 185, 129, 0.15)`) with Emerald text (`#10B981`).

### Lists & Manifest Groups
- **Dividers:** Never use high-contrast solid lines. Use hairline separators (`1px solid rgba(255, 255, 255, 0.08)`) with inset padding matching the label margin.
- **Row Architecture:** Left-aligned icon pill, vertical label/subtext stack, right-aligned monetary balance or gate assignment.

### Input Fields & Terminal Search
- **Search Capsule:** Pill-shaped glass container with an interior search icon tinted to `rgba(255, 255, 255, 0.40)`.
- **Active State:** Border glows with primary purple highlight (`rgba(124, 58, 237, 0.60)`); placeholder text smoothly shifts into secondary label hierarchy.

### Barcode & NFC Presentation Module
- **Optical NFC Target:** High-luminance white container with rounded 20px corners, completely isolated from ambient blur to ensure 100% optical readability at scanner turnstiles.
- **Tap Horizon:** Subtle concentric pulse waves emanating outward in accent purple `#7C3AED` to signify ready NFC field.