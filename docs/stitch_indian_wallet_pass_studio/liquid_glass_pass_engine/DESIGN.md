---
name: Liquid Glass Pass Engine
colors:
  surface: '#11121e'
  surface-dim: '#11121e'
  surface-bright: '#373845'
  surface-container-lowest: '#0c0d18'
  surface-container-low: '#1a1b26'
  surface-container: '#1e1f2b'
  surface-container-high: '#282935'
  surface-container-highest: '#333440'
  on-surface: '#e2e1f2'
  on-surface-variant: '#c0c6d6'
  inverse-surface: '#e2e1f2'
  inverse-on-surface: '#2f2f3c'
  outline: '#8b91a0'
  outline-variant: '#414754'
  surface-tint: '#aac7ff'
  primary: '#aac7ff'
  on-primary: '#003064'
  primary-container: '#3e90ff'
  on-primary-container: '#002957'
  inverse-primary: '#005db8'
  secondary: '#c2c1ff'
  on-secondary: '#1800a7'
  secondary-container: '#3630bf'
  on-secondary-container: '#b1b1ff'
  tertiary: '#ffb3b5'
  on-tertiary: '#680019'
  tertiary-container: '#ff5167'
  on-tertiary-container: '#5b0015'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#00468d'
  secondary-fixed: '#e2dfff'
  secondary-fixed-dim: '#c2c1ff'
  on-secondary-fixed: '#0c006b'
  on-secondary-fixed-variant: '#332dbc'
  tertiary-fixed: '#ffdada'
  tertiary-fixed-dim: '#ffb3b5'
  on-tertiary-fixed: '#40000c'
  on-tertiary-fixed-variant: '#920027'
  background: '#11121e'
  on-background: '#e2e1f2'
  surface-variant: '#333440'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  title-sm:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.05em
  mono-barcode:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.5rem
  margin: 1.25rem
  margin-compact: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-xxl: 3rem
---

## Brand & Style
The design system establishes a high-fidelity utility aesthetic blending Cupertino HIG precision with a next-generation Liquid Glass paradigm. Designed specifically for bridging regional Indian ticketing, transit, and identity protocols (Cult.fit, Namma Metro, UPI merchant passes, BookMyShow) into Apple Wallet containers, the emotional response centers on institutional trust, kinetic luxury, and effortless micro-interactions.

The style builds upon tactile frosted materials, fluid light refraction, and midnight depth. Translucent optical tiers capture vibrant ambient mesh backdrops—deep navy, electric indigo, and ultraviolet—while preserving optical clarity and contrast ratios. Functional interaction models reflect Apple native mechanics: precise tactile spring physics, reaches-first thumb ergonomics, specular hairline edge highlights, and focused system legibility.

## Colors
The palette leverages a dark-mode-first environment calibrated for OLED black conservation and high refractive indices. 

- **Primary (`#0A84FF`)**: The definitive iOS native blue, serving as the functional anchor for primary execution states, verification beacons, and primary interactive elements.
- **Secondary (`#5E5CE6`)**: Electric Indigo, used for mesh gradient undercurrents, active state transitions, and secondary contextual linkages.
- **Tertiary (`#FF2D55`)**: Specular Neon Magenta/Pink, applied with surgical restraint to represent live alerts, active Cult.fit class slots, real-time Namma Metro gate countdowns, and critical scan points.
- **Neutral (`#080914`)**: Obsidian Midnight foundation, providing the deep low-luminosity plane necessary for multi-layered backdrop blurs (`rgba(255, 255, 255, 0.04)` to `rgba(255, 255, 255, 0.12)`) without producing mud or desaturation.

Accent colors are strictly contextual: UPI Green (`#30D158`) for real-time mandate authentication and BookMyShow Amber (`#FF9F0A`) for cinema aisle and seat metadata tags.

## Typography
Typography is calibrated to replicate the optical density, horizontal metrics, and tight tracking of Apple's system typeface across high-DPI displays. Inter is deployed across all levels, relying on alternate open tracking for auxiliary metadata and condensed negative tracking for prominent financial amounts and pass titles.

- **Display & Headlines**: Used strictly for balance values, transit station pairs (e.g., `MG RD → BYPL`), and pass titles. Strong negative tracking creates a compact, monolithic visual appearance.
- **Labels & Micro-data**: Fields such as PNR codes, metro gate validity, seat indices, and Cult.fit slot timers utilize `label-sm` with distinct uppercase tracking (+0.05em) to maintain readability on luminous blurred backgrounds.
- **Numeric & Barcode**: Numerical displays, transaction sums, and secondary barcode values enforce tabular figure rendering (`font-variant-numeric: tabular-nums`) to prevent layout shift during countdowns and real-time pass generation.

## Layout & Spacing
The layout adheres strictly to iOS Ergonomic Zones, prioritizing thumb-driven interaction across the lower two-thirds of the viewport. Structural layout relies on a fluid grid bounded by hardware safe areas and dynamic screen insets.

- **Form Factor Adaptations**: On standard mobile viewport formats, margins enforce `1.25rem` (20px), expanding to `1.5rem` (24px) on tablet canvases. Element groupings conform to standard 8pt baseline rhythm steps (`space-xs` through `space-xxl`).
- **Pass Sheet Anatomy**: The Apple Wallet preview utilizes standard `aspect-ratio: 1.586 / 1` (PKPass standard) centered within the fluid canvas.
- **Action Safe Zones**: Primary calls-to-action ("Add to Apple Wallet", "Scan New QR") hover fixed within the bottom thumb reach zone, offset by `env(safe-area-inset-bottom) + space-md`, floating as an isolated glass dock.

## Elevation & Depth
Elevation is constructed through physical optical refraction rather than arbitrary drop-shadows. Surfaces emulate multi-layered curved liquid glass with varying indices of translucency and surface diffusion:

1. **Layer 0 (Canvas Base)**: Pitch obsidian `#080914` underlaid with dynamic animated radial mesh gradients (`#5E5CE6`, `#0A84FF`, `#FF2D55`) exhibiting 90px Gaussian blur at 30% saturation.
2. **Layer 1 (Recessed Well / Scan Cavity)**: `rgba(0, 0, 0, 0.4)` fill with an inner hairline shadow `inset 0 1px 1px rgba(0, 0, 0, 0.6)` and `inset 0 -1px 1px rgba(255, 255, 255, 0.05)`.
3. **Layer 2 (Standard Pass Tile & Sheet)**: `backdrop-filter: blur(28px) saturate(180%)`; background fill `linear-gradient(135deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0.02) 100%)`.
4. **Layer 3 (Floating Controls / Modals)**: `backdrop-filter: blur(40px) saturate(210%)`; background fill `linear-gradient(135deg, rgba(255, 255, 255, 0.14) 0%, rgba(255, 255, 255, 0.04) 100%)`.
5. **Specular Hairlines**: All glass edges carry an ultra-crisp 1px border using linear gradient masks: `linear-gradient(to bottom, rgba(255, 255, 255, 0.35) 0%, rgba(255, 255, 255, 0.05) 50%, rgba(255, 255, 255, 0.0) 100%)`. Light enters from the top, casting specular refraction along upper element perimeters.

## Shapes
In alignment with roundedness tier `3`, components utilize continuous iOS-style super-ellipses (squircle geometry) transitioning into pill contours for tactile interactive targets:

- **Pass Shells**: 2rem (32px) corner radii matching native Apple Wallet boarding pass and event ticket structures.
- **Glass Tiles & Panels**: 1.5rem (24px) continuous smoothing corners.
- **Buttons & Control Chips**: Full continuous capsule/pill radius (`9999px` / `rounded-full`), producing soft silhouettes capable of holding specular highlights without angular light breaks.
- **Micro Badges**: Complete pill curves (`1rem` height-relative radius) hugging compact metadata indicators.

## Components

### Buttons
- **Primary CTA ("Add to Apple Wallet")**: Pill shape (`h: 56px`), solid Apple black `#000000` surface bounded by a continuous specular edge highlight `rgba(255, 255, 255, 0.25)`, centering the official Apple Wallet badge alongside white `title-sm` typography. Active tap scale: `0.97` with haptic feedback.
- **Glass Utility Button**: Pill shape, translucent base `rgba(255, 255, 255, 0.08)`, `backdrop-filter: blur(16px)`, `1px` top-lit specular rim. Icon-only or icon-and-label in `#FFFFFF`.

### Wallet Pass Preview Card
- **Structure**: Continuous corner-smoothed card (2rem radius) divided into header, transit/event matrix, barcode well, and footer.
- **Body Styling**: Layer 2 frosted glass. Cult.fit passes inject a localized `#FF2D55` refractive radial gradient behind the workout title; Namma Metro cards cast a cool `#0A84FF` sheen across the route vector path.
- **Barcode Cavity**: Pure high-contrast container (`#FFFFFF` background, `0.75rem` radius) isolating native PDF417 or Aztec codes to guarantee immediate optical scanner throughput at transit turnstiles and gym kiosks.

### Chips & Status Badges
- **Live Verification Chip**: Fully rounded pill, `rgba(10, 132, 255, 0.15)` fill with an animated 6px breathing dot emitting `#0A84FF` glow, displaying text in `label-sm`.
- **Category Filter Chips**: Floating frosted pills with `1px` border `rgba(255, 255, 255, 0.1)`. Active selection shifts fill to `rgba(255, 255, 255, 0.95)` with text shifting to `#080914`.

### Lists & Grouped Containers
- **Grouped Inset Lists**: Mimics iOS grouped tables. Cells reside inside a Layer 2 glass sheet with `0.5px` dividers in `rgba(255, 255, 255, 0.08)` inset by `margin-compact`. Cell interaction presents a brief `rgba(255, 255, 255, 0.06)` highlight.

### Input Fields & Scanner Wells
- **QR Viewfinder**: 1:1 square frame with smooth `2rem` rounded corners framed by four active optical brackets colored in `#0A84FF`. Central glass crosshairs react with a soft magenta highlight (`#FF2D55`) when a valid payload (UPI string, BookMyShow booking ID) is resolved.
- **Manual Input**: Recessed glass well, dark inner tone, `label-md` placeholder text in `rgba(255, 255, 255, 0.4)`, focusing to an electric blue specular border (`#0A84FF`).

### Selection Controls
- **Switches & Radios**: Native iOS-scale switches; thumb is an opaque high-white pill casting a downward soft ambient shadow (`rgba(0, 0, 0, 0.35)`), sliding across an active `#0A84FF` track or inactive `rgba(255, 255, 255, 0.16)` glass channel.