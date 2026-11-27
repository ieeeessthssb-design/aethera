# AETHERA Design System

This document is the visual source of truth for the Flutter application. New screens and redesigned screens must follow it. The goal is an agricultural product identity that feels calm, credible, and specific to Tunisian farming—not a generic AI dashboard.

## Design concept: Field Notes, Modern Agriculture

AETHERA combines the visual warmth of a field journal with the precision of a modern agricultural instrument. Use real crop and landscape photography selectively, restrained botanical color, strong typographic hierarchy, and clear data presentation. Let agricultural information lead; decoration is secondary.

## Color tokens

| Token | Hex | Role |
|---|---|---|
| `forest` | `#183F32` | Primary brand, high-emphasis actions, dark hero surfaces |
| `leaf` | `#527B58` | Secondary actions, icons, supporting emphasis |
| `mint` | `#EAF2EA` | Soft selected and supporting surfaces |
| `cream` | `#F7F6EF` | Main light background |
| `ink` | `#24352C` | Main text |
| `muted` | `#59665C` | Secondary text |
| `lime` | `#B6DC70` | Small accent only; never use as a large background |
| `warning` | `#B36B2C` | Weather and safety warnings |
| `danger` | `#A94438` | Destructive actions and critical states |

Do not introduce a second unrelated accent palette. Use semantic colors consistently for success, warning, error, and information.

## Typography

- Use the existing `Tajawal` theme family for Arabic-aware presentation.
- Use clear weight contrast: regular for explanatory copy, medium for labels, bold for section headings and key values.
- Avoid all-caps body text. Small uppercase eyebrow labels are acceptable when used sparingly.
- Keep numeric weather values visually prominent and units subordinate.

## Layout and spacing

Use an 4/8-point rhythm: 4, 8, 12, 16, 20, 24, 32. Prefer consistent 16–20 px page gutters on mobile. Group related data with whitespace and alignment rather than nesting multiple cards inside cards.

## Surfaces and shape

- Use a small radius vocabulary: 12 px for controls, 16 px for standard surfaces, 22–24 px for large feature surfaces.
- Use subtle borders or tonal surface contrast before adding shadows.
- Avoid excessive glassmorphism, gradient fills, and floating card stacks.
- Use dark forest surfaces for intentional emphasis, not as the default for every panel.

## Photography

Use authentic agricultural photography. The generated Tunisian landscape lives at `app/assets/images/backgrounds/tunisian_farm_landscape.png`. Reserve large imagery for onboarding, a dashboard hero, or feature storytelling. Crop images intentionally and apply a dark overlay only when text is placed on top. Do not use the UI concept collages as in-app artwork.

## Assistant motion

The assistant orb is an identity and interaction cue, not proof of an active AI model. Motion should be slow, organic, and low-amplitude by default. State changes (idle, listening, thinking, responding, error) must be tied to real application state before they are represented as active. Respect reduced-motion accessibility preferences when adding additional motion.

## Weather presentation

Weather is an operational tool. Prioritize current conditions, hourly progression, seven-day min/max values, precipitation probability, wind, sunrise/sunset, and notable changes. Alert only when a meaningful threshold is crossed. Clearly label forecast source and uncertainty; never turn forecast data into a guaranteed crop outcome.

## Accessibility and interaction

- Maintain readable contrast; do not use pale green for small text on white.
- Every tappable control needs a meaningful action and an adequate touch target.
- Provide loading, empty, error, and success states for network-backed screens.
- Preserve RTL behavior and verify Arabic layouts.
- Do not communicate status using color alone; pair it with text or an icon.
- Avoid autoplay audio and high-frequency animation.

## Anti-slop review checklist

Before considering a screen complete, verify:

1. Its layout is appropriate to the task, not copied from another screen by default.
2. There is one clear primary action or information hierarchy.
3. Repeated components share the same tokens and behavior.
4. Cards are used only where grouping or interaction benefits from them.
5. Images are real, relevant, and correctly cropped—not decorative filler.
6. Every button, tab, and form control works.
7. Loading, empty, error, and success states are covered.
8. Contrast, RTL, text scaling, and touch targets are checked.
9. Motion has a purpose and does not distract from farm information.
10. The screen looks recognizably like AETHERA even without the logo.
