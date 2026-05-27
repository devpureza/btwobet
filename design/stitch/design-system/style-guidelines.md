## Brand & Style

The brand personality is high-octane, celebratory, and competitive. Designed for the 2026 World Cup, it captures the diverse energy of North America through a "Modern Stadium" aesthetic. The UI should evoke the adrenaline of a last-minute goal and the communal joy of a tournament sweepstakes.

The design style is **Corporate Modern with Glassmorphism accents**. It utilizes a structured, card-based architecture to manage dense sports data, while layering translucent "glass" surfaces for overlays and navigation to maintain a sense of depth and lightness. Interactive elements should feel tactile and responsive, reflecting the real-time nature of live sports.

## Layout & Spacing

The design system employs a **12-column fluid grid** for desktop and a **4-column grid** for mobile. A strict 4px base unit governs all spacing tokens, ensuring a rhythmic and balanced layout.

On mobile, margins are kept tight (16px) to maximize the real estate for match listings and score inputs. On desktop, the layout centers with a maximum width of 1280px. Spacing between cards (gutters) should be consistent at 20px to allow the soft shadows of the cards to breathe without overlapping visually.

## Elevation & Depth

This design system uses a combination of **Tonal Layers** and **Glassmorphism**. 

1.  **Base Surface:** Pure White or very light gray (#F8F9FA).
2.  **Match Cards:** Elevated by a soft, diffused shadow (10% opacity Primary Green tint) to make them appear slightly lifted from the "pitch."
3.  **Overlays & Modals:** Use a high-density background blur (20px) with a semi-transparent white fill (70% opacity). This allows the colors of the match cards underneath to bleed through, maintaining the vibrant energy.
4.  **Interactive Elements:** Use a subtle inner-glow for "Pressed" states on score inputs, creating a tactile "pushed-in" feel.

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