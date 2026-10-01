---
name: Slip
colors:
  surface: '#141313'
  surface-dim: '#141313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2b2a2a'
  surface-container-highest: '#353434'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c8c5ca'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#919095'
  outline-variant: '#47464a'
  surface-tint: '#c8c6c8'
  primary: '#c8c6c8'
  on-primary: '#313032'
  primary-container: '#0a0a0c'
  on-primary-container: '#7a797b'
  inverse-primary: '#5f5e60'
  secondary: '#c7c5d0'
  on-secondary: '#303038'
  secondary-container: '#46464f'
  on-secondary-container: '#b6b4bf'
  tertiary: '#ccc5bf'
  on-tertiary: '#33302c'
  tertiary-container: '#0c0a07'
  on-tertiary-container: '#7d7973'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e5e1e4'
  primary-fixed-dim: '#c8c6c8'
  on-primary-fixed: '#1c1b1d'
  on-primary-fixed-variant: '#474649'
  secondary-fixed: '#e4e1ec'
  secondary-fixed-dim: '#c7c5d0'
  on-secondary-fixed: '#1b1b23'
  on-secondary-fixed-variant: '#46464f'
  tertiary-fixed: '#e8e1db'
  tertiary-fixed-dim: '#ccc5bf'
  on-tertiary-fixed: '#1e1b17'
  on-tertiary-fixed-variant: '#4a4642'
  background: '#141313'
  on-background: '#e5e2e1'
  surface-variant: '#353434'
  mesh-violet: '#1f1035'
  mesh-teal: '#0c2329'
  mesh-base: '#070709'
  glass-surface: rgba(255, 255, 255, 0.08)
  glass-border: rgba(255, 255, 255, 0.12)
  text-primary: '#F5F5F7'
  text-secondary: '#8E8E93'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  code-mono:
    fontFamily: JetBrains Mono
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.1em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 16px
  margin: 20px
  space-xs: 4px
  space-sm: 8px
  space-md: 16px
  space-lg: 24px
  space-xl: 32px
---

## Brand & Style

Slip is an ultra-premium pass wallet application designed for the discerning user who demands native fidelity, elegance, and speed. The experience is meticulously crafted to evoke the tactile nostalgia of physical tickets and boarding passes combined with futuristic digital luxury.

- **Brand Personality:** Sophisticated, precise, immersive, and effortlessly modern.
- **Target Audience:** Urban professionals, frequent travelers, and digital-first enthusiasts who value aesthetic perfection and seamless organization.
- **Emotional Response:** Calm control, exclusivity, and the quiet satisfaction of fine craftsmanship.
- **Design Style:** Glassmorphism and High-End iOS. The interface relies on translucent frosted glass layers (`backdrop-filter: blur`), dark ambient mesh gradients, precise 1px borders, and tactile card structures that mimic physical passes.

## Colors

The color system is exclusively dark-mode native, built upon deep obsidian blacks, rich ambient mesh gradients, and translucent glass tiers. 

- **Primary Color (`#0A0A0C`):** The foundational void black used for root canvases.
- **Secondary Color (`#1C1C24`):** Elevated surface tone for cards and floating containers.
- **Named Colors:** Features specialized mesh undertones (`mesh-violet`, `mesh-teal`) that shift softly behind glass layers, along with strict semantic opacities for glass strokes and muted secondary text (`#8E8E93`).

## Typography

Typography balances humanistic grotesque proportions for prose with uncompromising monospaced figures for data integrity.

- **Headline Font (`Inter`):** Delivers clean, neutral, Apple-grade geometry across all primary titles and structural headers.
- **Body Font (`Inter`):** Highly legible at small scales within dense pass metadata grids.
- **Label Font (`JetBrains Mono`):** Applied exclusively to PNRs, booking IDs, timestamps, and numerical tokens to emulate physical printed tickets and secure access passes.

## Layout & Spacing

The layout model is built on a fluid, edge-to-edge canvas philosophy optimized for mobile viewports, anchored by safe-area insets and organic floating navigation elements.

- **Grid System:** Flexible column framing with 16px structural gutters and 20px outer canvas margins.
- **Spacing Rhythm:** Based on an 8px grid multiplier (`space-xs` through `space-xl`), ensuring consistent breathing room between nested card metadata blocks and hero banners.

## Elevation & Depth

Depth is achieved entirely through the principles of advanced glassmorphism and ambient light scattering rather than harsh drop shadows.

- **Glass Surfaces:** Semi-transparent panels utilizing subtle backdrop blurs (20px to 40px) layered over the animating mesh background.
- **Borders & Highlights:** 1px "ghost borders" at 12% white opacity define edges cleanly against dark voids.
- **Shadows:** Extra-diffused, low-opacity dark shadows (`radius: 20px, y: 10px, opacity: 0.3`) anchor floating components like the `FloatingDock` and expanded pass details without visual clutter.

## Shapes

The shape language relies heavily on generous, organic radiuses and specialized physical cutouts to mimic authentic wallet passes and tickets.

- **Roundedness Scale:** Set to pill-shaped and highly rounded containers (`rounded-xl` ranging from 20px to 32px corner radius).
- **Specialized Geometry:** Pass shells incorporate physical metaphors such as side semi-circle tear-off notches and top-center lanyard cutouts, reinforcing the tangible pass wallet aesthetic.

## Components

Components are engineered to mirror native iOS Human Interface Guidelines combined with high-end digital pass wallet constraints.

- **Buttons:** Pill-shaped primary actions with high-contrast glass fills, accompanied by haptic-feedback scaling states.
- **Chips & Status Pills:** Compact capsule badges featuring translucent colored backgrounds and monospaced text for status tracking (e.g., "ACTIVE").
- **Input Fields:** Minimalist borderless or subtle 1px outlined fields with floating uppercase labels in monospaced type.
- **Pass Cards (`PassShell` & `EventTicketShell`):** Composable container systems housing brand headers, horizontal strip hero banners, strict grid field blocks, and bottom-anchored QR/NFC panels.
- **Floating Dock:** A floating, blurred navigation dock anchored at the base of the screen housing primary views (Home, Scan/Import, Marketplace, Settings).