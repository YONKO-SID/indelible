# Design System Document: The Ink Wash Aesthetic

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Curator"**

This design system moves away from the aggressive, neon-drenched tropes of typical cybersecurity platforms. Instead, it adopts the persona of a high-end art gallery or a private archival vault. The goal is to evoke a sense of absolute permanence and quiet authority. 

We achieve this through "The Digital Curator" philosophy: treating every piece of data—from a cryptographic hash to a portfolio balance—as a precious artifact. We leverage **intentional asymmetry**, high-contrast editorial typography, and **tonal depth** to create a UI that feels less like software and more like a bespoke physical space. By using vast amounts of white space (or "dark space") and razor-thin detailing, we communicate that this is a platform of precision and prestige.

---

## 2. Colors & Tonal Architecture
The palette is rooted in a monochromatic "Ink Wash" spectrum. We utilize deep charcoals and soft ivories to create a high-contrast environment that remains easy on the eyes during long technical sessions.

### Surface Hierarchy & Nesting
Depth is not created with light; it is created with density. We use a "Nested Layering" approach:
*   **Base Layer:** `surface` (#131313) – The infinite floor of the gallery.
*   **Secondary Sections:** `surface_container_low` (#1C1B1B) – Subtle grounding for content blocks.
*   **Active/Elevated Surfaces:** `surface_container_high` (#2A2A2A) – Used for interactive modules and cards.
*   **The "No-Line" Rule:** Sectioning must be achieved through these tonal shifts. Traditional 1px solid borders for large-scale layout separation are strictly prohibited. If two sections meet, let the transition from `#131313` to `#1C1B1B` define the boundary.

### Signature Textures
*   **Glassmorphism:** For floating modals or navigation bars, use `surface_container_highest` (#353534) at 70% opacity with a `20px` backdrop-blur. This creates a "frosted obsidian" effect that allows the underlying data to bleed through subtly.
*   **The Ivory Accent:** The `primary` (#FFFFFF) is our light source. Use it sparingly for CTAs to ensure they command immediate attention against the ink-wash background.

---

## 3. Typography
Our typography is a dialogue between the technical and the editorial.

*   **Display & Headlines (Space Grotesk):** This font provides a structural, architectural feel. Use `display-lg` (3.5rem) with tighter letter-spacing (-0.02em) for hero moments to create an authoritative, "monolithic" brand presence.
*   **Body & UI (Inter):** The workhorse. We use `body-md` (0.875rem) for most interface text. It offers a neutral, Swiss-style clarity that balances the personality of the headings.
*   **Technical Data (Space Mono):** Used exclusively for hashes, wallet addresses, and code snippets. This ensures that "functional" data is visually distinct from "narrative" content.

---

## 4. Elevation & Depth
In this system, elevation is a psychological state, not just a CSS property.

*   **Tonal Layering:** To lift a card, place a `surface_container_highest` (#353534) element onto a `surface` (#131313) background. The contrast provides the "lift."
*   **Ambient Shadows:** For floating elements (like tooltips or dropdowns), use an extra-diffused shadow: `0 12px 40px rgba(0, 0, 0, 0.5)`. Never use pure black shadows on top of the dark surfaces; ensure they feel like an atmospheric "glow" of darkness.
*   **The Ghost Border:** For accessibility in form fields or buttons, use the `outline_variant` (#474747) at 20% opacity. This creates a "whisper" of a boundary that appears only when the user is looking for it.

---

## 5. Components

### Buttons
*   **Primary:** `primary` (#FFFFFF) background with `on_primary` (#1A1C1B) text. No border. 8px border-radius (`lg`).
*   **Secondary:** Ghost style. `outline` (#919191) 1px border. Text in `primary`. On hover, the background shifts to `surface_bright` (#3A3939).
*   **Tertiary:** No border, no background. Underline on hover only.

### Input Fields
*   **Style:** Editorial Underline. Inputs do not have four-sided boxes. They are defined by a 1px bottom border using `outline_variant`.
*   **State:** When focused, the bottom border transitions to `primary` (#FFFFFF). Label text (using `label-md`) moves 4px upward and stays in `muted` (#808080).

### Cards & Lists
*   **The Divider Prohibition:** Vertical white space is our primary separator. For lists, use `surface_container_low` for even rows and `surface` for odd rows to create a "Zebra" effect without using horizontal lines.
*   **Card Radii:** All cards must use `lg` (0.5rem/8px) to maintain a soft but disciplined aesthetic.

### Vault-Specific Components
*   **The Hash-Block:** A specialized container for cryptographic strings. Use `surface_container_lowest` (#0E0E0E) background, `Space Mono` typography, and a subtle 1px "Ghost Border" to make the data feel "encased."
*   **Status Toggles:** Minimalist. The track is `secondary_container` (#474747), and the thumb is `primary` (#FFFFFF). No icons inside the toggle; let the color-shift handle the communication.

---

## 6. Do's and Don'ts

### Do
*   **Do** use extreme whitespace. If a layout feels "full," increase the padding by 1.5x.
*   **Do** lean into asymmetry. For example, left-align a headline while right-aligning the body text below it to create a gallery-style layout.
*   **Do** use `Space Mono` for any string of text that is generated by a machine.

### Don't
*   **Don't** use standard "Success Green" or "Warning Yellow" unless absolutely necessary for safety. Use tonal shifts or ivory icons to indicate status where possible.
*   **Don't** use 100% opaque borders for sectioning. It breaks the "Ink Wash" flow.
*   **Don't** use traditional drop shadows on cards that are sitting on the base background; use tonal nesting instead.