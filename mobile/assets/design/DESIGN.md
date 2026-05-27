---
name: Unity Arena
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#404942'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#707971'
  outline-variant: '#bfc9bf'
  surface-tint: '#296a46'
  primary: '#00341c'
  on-primary: '#ffffff'
  primary-container: '#004d2c'
  on-primary-container: '#7bbd93'
  inverse-primary: '#92d5a9'
  secondary: '#705d00'
  on-secondary: '#ffffff'
  secondary-container: '#fcd400'
  on-secondary-container: '#6e5c00'
  tertiary: '#002a60'
  on-tertiary: '#ffffff'
  tertiary-container: '#00408a'
  on-tertiary-container: '#86afff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#aef2c4'
  primary-fixed-dim: '#92d5a9'
  on-primary-fixed: '#002110'
  on-primary-fixed-variant: '#085230'
  secondary-fixed: '#ffe16d'
  secondary-fixed-dim: '#e9c400'
  on-secondary-fixed: '#221b00'
  on-secondary-fixed-variant: '#544600'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc7ff'
  on-tertiary-fixed: '#001a41'
  on-tertiary-fixed-variant: '#004493'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Montserrat
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Space Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  container-max: 1280px
  gutter: 20px
---

## Brand & Style

The brand personality is high-octane, celebratory, and competitive. Designed for the 2026 World Cup, it captures the diverse energy of North America through a "Modern Stadium" aesthetic. The UI should evoke the adrenaline of a last-minute goal and the communal joy of a tournament sweepstakes.

The design style is **Corporate Modern with Glassmorphism accents**. It utilizes a structured, card-based architecture to manage dense sports data, while layering translucent "glass" surfaces for overlays and navigation to maintain a sense of depth and lightness. Interactive elements should feel tactile and responsive, reflecting the real-time nature of live sports.

## Colors

The palette is rooted in a **Deep Tournament Green** (#004D2C), providing a pitch-inspired foundation that feels prestigious and authoritative. **Bright Gold** (#FFD700) is used sparingly for "winner" states, icons, and primary call-to-actions, symbolizing the trophy and peak achievement.

A clean **White and Neutral Gray** palette ensures maximum legibility for scoreboards and data tables. We introduce a **Tertiary Blue** to represent the oceanic and sky elements of the 2026 host nations. Backgrounds should use a subtle gradient from Neutral to White to prevent visual fatigue during long browsing sessions.

## Typography

The typography system is built for impact and clarity. **Montserrat** is the primary typeface for all headings, utilized in bold and extra-bold weights to mimic the high-energy typography seen in stadium signage and sports broadcasting.

**Hanken Grotesk** provides a sharp, contemporary feel for body copy and descriptions, ensuring that complex rules and betting odds remain readable at smaller sizes. **Space Mono** is used for "meta" information—such as match times, dates, and live scores—to give the app a technical, precise, and data-driven edge.

## Layout & Spacing

The design system employs a **12-column fluid grid** for desktop and a **4-column grid** for mobile. A strict 4px base unit governs all spacing tokens, ensuring a rhythmic and balanced layout.

On mobile, margins are kept tight (16px) to maximize the real estate for match listings and score inputs. On desktop, the layout centers with a maximum width of 1280px. Spacing between cards (gutters) should be consistent at 20px to allow the soft shadows of the cards to breathe without overlapping visually.

## Elevation & Depth

This design system uses a combination of **Tonal Layers** and **Glassmorphism**. 

1.  **Base Surface:** Pure White or very light gray (#F8F9FA).
2.  **Match Cards:** Elevated by a soft, diffused shadow (10% opacity Primary Green tint) to make them appear slightly lifted from the "pitch."
3.  **Overlays & Modals:** Use a high-density background blur (20px) with a semi-transparent white fill (70% opacity). This allows the colors of the match cards underneath to bleed through, maintaining the vibrant energy.
4.  **Interactive Elements:** Use a subtle inner-glow for "Pressed" states on score inputs, creating a tactile "pushed-in" feel.

## Shapes

The shape language is modern and approachable. A **Rounded (0.5rem)** corner radius is applied to all standard cards and containers. Larger elements like hero sections or modals use `rounded-xl` (1.5rem) to soften the aesthetic.

Progress bars and score input fields should be fully rounded (pill-shaped) to distinguish them from structural cards. Flags should be rendered with a tiny corner radius (2px) to maintain their iconic rectangular identity while fitting the softer UI style.

## Components

### Match & Team Cards
Match cards are the primary container. They feature a horizontal layout for desktop (Team A vs Team B) and a stacked layout for mobile. Team flags are placed in circular or slightly rounded square frames.

### Score Inputs
Inputs for sweepstakes guesses must be large and tappable. Use a bold `headline-md` font for the numbers. On focus, the input border should transition from a neutral gray to the Primary Green with a Gold glow.

### Leaderboard Table
The leaderboard utilizes alternating row stripes (zebra striping) in 5% opacity Primary Green. The "Top 3" players should have Gold, Silver, and Bronze accents respectively, with the current user's row highlighted using a subtle Primary Green border.

### Progress Bars
Used for group stage advancement. The background track is a light neutral, while the fill is a gradient from Primary Green to a brighter mint green.

### Chips & Badges
Use "Live," "Finished," and "Upcoming" status badges. These should be pill-shaped with high-contrast text and a small dot indicator for live matches.