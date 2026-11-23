# SmartMuseum Website

A high-performance single-page marketing and demo website for **SmartMuseum**, a BLE beacon-based digital heritage guide (demo built around Laxmi Vilas Palace).

The site is built with pure static HTML5, CSS3, and modern vanilla JavaScript with zero external frameworks, zero build steps, and zero client dependencies.

---

## Design System

The visual design is directly inspired by `design/DESIGN-linear.app.md` and adapted with SmartMuseum's royal heritage color palette:

- **Canvas & Surfaces:**
  - Canvas: `#090807` (Deep near-black charcoal)
  - Surface Ladder:
    - Level 1: `#141110` (Panels, feature cards)
    - Level 2: `#1B1613` (Elevated tiles, app UI)
    - Level 3: `#251F1B` (Interactive elements, chips)
    - Level 4: `#2F2722` (Lifted details)
  - Hairline borders: `#26201B` with top edge highlights (`rgba(251, 247, 239, 0.08)`)
- **Brand Accents:**
  - Antique Gold: `#C9962B` (Primary CTA, active markers, signal pulses, brand highlights)
  - Royal Maroon: `#6B1426` (Subtle badges, secondary emphasis)
  - Ivory: `#FBF7EF` (Primary headings, readable ink)
  - Muted Ivory: `#D3CDC2` (Body copy, secondary text)
- **Typography:**
  - Font family: `Inter` with system fallback stack (`-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`).
  - Monospace font: `JetBrains Mono` / `SF Mono` for data and telemetry readouts.
  - Negative letter tracking on display headings (`-0.03em` to `-0.04em`) and uppercase positive tracking (`+0.08em`) on eyebrows.

---

## Folder Structure

```text
smartmuseum-website/
├── index.html                   # Main semantic single-page document
├── favicon.ico                  # Standard 32x32 website icon
├── README.md                    # Documentation and maintenance guide
├── css/
│   └── styles.css               # Design system, CSS custom properties, and responsive styles
├── js/
│   └── main.js                  # Navigation, scroll-spy, scroll-reveal, and mockup fallback handlers
├── design/
│   └── DESIGN-linear.app.md     # Reference design analysis
└── assets/
    ├── branding/
    │   ├── logo.png             # SmartMuseum logo (1024x1024 RGBA)
    │   ├── icon_foreground.png  # High-resolution brand emblem
    │   ├── favicon.png          # 32x32 PNG favicon
    │   ├── favicon-32x32.png    # 32x32 PNG favicon
    │   ├── favicon-16x16.png    # 16x16 PNG favicon
    │   └── apple-touch-icon.png # 180x180 Apple touch icon
    ├── downloads/
    │   ├── SmartMuseum_Makerfest_Deck.pdf   # 7-slide dark-themed presentation PDF matching website theme
    │   └── SmartMuseum_Makerfest_Deck.pptx  # 7-slide widescreen PowerPoint presentation deck
    └── images/
        └── screen-exhibit.png   # (Optional) App exhibit detail screenshot
```

---

## How to Edit the Copy

All website text is cleanly organized in `index.html` inside semantic `<section>` blocks matching the project outline:

1. **Hero Section (`#hero`):**
   - Edit the eyebrow, H1, subhead, CTA buttons, or disclaimer inside `<section id="hero">`.
2. **Visitor Journey (`#journey`):**
   - Edit the 7 vertical timeline steps or status chips inside `<div class="timeline-vertical">`.
   - Update the preview card items inside `<aside class="journey-preview-card">`.
3. **Live Demo (`#demo`):**
   - Google Drive preview embed URL and fallback link can be adjusted inside `<section id="demo">`.
4. **The Demo Tour (`#tour`):**
   - Update stop titles (Entrance Gate, Durbar Hall, Royal Gallery) and content chips in `<div class="tour-layout">`.
5. **How It Works / Infrastructure (`#how`):**
   - Update architecture nodes, bullet points, content tags, and concept dashboard metrics.
6. **Impact For Museums (`#impact`):**
   - Edit the 12 institutional value cards.
7. **Presentation (`#presentation`):**
   - Download PPTX button and Open presentation (PDF) action card.
8. **Footer (`footer.site-footer`):**
   - Brand identity, "Go to top" navigation button, and palace inspiration disclaimer.

---

## How to Replace Screenshots

SmartMuseum automatically checks for application screenshots in `assets/images/`:

- **Exhibit Detail Screenshot:**
  - Place an exhibit screen capture named `screen-exhibit.png` inside `assets/images/`.
  - If present, the phone frame appears seamlessly alongside the three palace tour cards in Section D (`#tour`).
  - If absent, Section D automatically skips the mockup silently and expands the tour cards across a full 3-column desktop layout.

---

## Testing & Local Preview

To preview the website locally without any installation or build step:

```bash
# Start a lightweight local HTTP server
python3 -m http.server 8000
```

Open `http://localhost:8000` in any web browser.

### Verifications Completed
- Responsive breakpoints tested at 360 px (mobile small), 768 px (tablet/mobile large), and 1280 px (desktop).
- Verified zero horizontal page overflow across all viewports.
- Skip link and `:focus-visible` accessibility tested.
- `prefers-reduced-motion` tested to disable CSS animations and instant-reveal content.
- Verified all anchor links (`#journey`, `#demo`, `#tour`, `#how`, `#impact`, `#presentation`, `#top`).
- Validated both PPTX and PDF download attributes and iframe/object embeds.
- Total asset payload (excluding downloadable PPTX/PDF and remote video iframe) is well under 200 KB.
