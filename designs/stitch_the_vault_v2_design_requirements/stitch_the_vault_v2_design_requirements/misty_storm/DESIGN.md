# Design System Document: Atmospheric Security

## 1. Overview & Creative North Star: "The Sentinel in the Mist"
This design system is built to evoke a sense of calm, absolute authority. For a premium security SaaS, we move away from "anxious" security tropes—bright reds and heavy borders—and instead embrace an aesthetic of quiet, high-tech surveillance. 

**Creative North Star: The Sentinel in the Mist.**
The interface should feel like a high-end command deck viewed through a soft evening fog. We break the "template" look by prioritizing **tonal depth over structural lines**. By using intentional asymmetry in layout and overlapping glass containers, we create a digital environment that feels sophisticated, layered, and premium. We do not just show data; we curate an atmosphere of safety.

---

## 2. Colors & Surface Philosophy
The palette is rooted in the deep shadows of a storm, using blue-undertone charcols to provide a richer, more professional depth than pure black.

### The Color Palette (Material Mapping)
*   **Surface (Primary Background):** `#0F1419` – The deep charcoal base.
*   **Surface Container Low (Secondary):** `#1A1F2E` – The "fog layer" for secondary sections.
*   **Primary Action:** `#A4C9FF` (Storm Blue / `primary`) – Use for critical paths.
*   **Secondary Highlight:** `#8ACEFF` (Cyan Mist / `secondary`) – Use for accents and active states.
*   **Typography:** `#F0F3F7` (Primary) and `#B0B8C3` (Secondary/Muted).

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section off content. 
Boundaries must be defined solely through:
1.  **Background Color Shifts:** Placing a `surface-container-high` card on a `surface` background.
2.  **Tonal Transitions:** Using slight shifts in darkness to imply a change in context.
3.  **Negative Space:** Using the spacing scale to create mental groupings.

### The "Glass & Gradient" Rule
To escape the "flat" SaaS look, use **Glassmorphism** for floating elements (modals, dropdowns, navigation rails).
*   **Effect:** `surface-variant` at 60% opacity with a `12px` backdrop-blur.
*   **Signature Textures:** Apply a subtle linear gradient to main CTAs (transitioning from `primary` to `primary-container`). This provides a "soul" to the button that flat color cannot replicate.

---

## 3. Typography: Editorial Authority
We use a dual-font strategy to balance human-centric security with technical precision.

*   **Display & Headlines (Inter):** Set with tight letter-spacing (-0.02em) and generous leading. Headlines should feel like an editorial masthead—authoritative and clean.
*   **Body (Inter):** Standardized for readability. Use `body-md` (`0.875rem`) for the majority of UI text to maintain a sophisticated, "dense but airy" feel.
*   **Technical Data (JetBrains Mono):** All IP addresses, logs, hashes, and timestamps must use JetBrains Mono. This font acts as a visual "signal" that the user is looking at raw, unadulterated security data.

---

## 4. Elevation & Depth: Tonal Layering
In this design system, height is not measured by shadows alone, but by "atmospheric thickness."

*   **The Layering Principle:** Stacking is the primary driver of hierarchy. 
    *   *Base Level:* `surface`
    *   *Section Level:* `surface-container-low`
    *   *Object Level (Cards):* `surface-container-highest`
*   **Ambient Shadows:** For floating elements, use a "Cyan Glow" rather than a dark shadow. 
    *   *Value:* `box-shadow: 0 0 24px rgba(90, 173, 226, 0.15);`
    *   The shadow should feel like light refracting through mist, not a physical weight.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline-variant` token at **15% opacity**. Never use 100% opaque lines.

---

## 5. Components

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary-container`), 12px radius, no border.
*   **Secondary:** Ghost style. `outline-variant` (20% opacity) with `primary` text.
*   **Tertiary:** Text only, JetBrains Mono (all caps) for a technical, "utility" feel.

### Cards & Containers
*   **Rule:** No dividers. Use `surface-container` tiers to nest information.
*   **Radius:** Always use `12px` (`md`) for inner cards and `16px` (`lg`) for main containers to create a "nested" visual harmony.

### Input Fields
*   **State:** Default state uses `surface-container-highest`.
*   **Focus:** A soft `2px` outer glow using `secondary` (Cyan Mist) at 30% opacity. No harsh solid strokes.

### Technical Log Lists
*   **Style:** Use JetBrains Mono `label-md`. 
*   **Separation:** Use alternating row tints (`surface` vs `surface-container-low`) instead of lines. This maintains the "misty" flow of the data.

### Signature Component: The "Pulse Monitor"
A custom component for security status. A large, blurred glow (`secondary`) that pulses slowly behind critical data points to indicate "live" system health, mimicking a heartbeat in the storm.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use overlapping elements. Let a glassmorphic sidebar slightly overlap a main content card to create depth.
*   **Do** use JetBrains Mono for any string of characters that isn't a sentence.
*   **Do** lean into "Cyan Mist" glows for success states instead of standard "Green."

### Don't:
*   **Don't** use 1px solid `#000000` or high-contrast borders. It breaks the atmosphere.
*   **Don't** use standard "Drop Shadows." If it doesn't look like an ambient glow, it doesn't belong.
*   **Don't** use bright, saturated red for errors. Use the `error_container` token—a muted, bruised red that fits the stormy palette.