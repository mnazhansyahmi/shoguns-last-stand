---
name: Shogun's Last Stand
description: Japanese ink silhouettes at sunset, with an approved painted swordsman.
colors:
  ink: "#121018"
  ink-back: "#2a2633"
  ink-detail: "#3b3646"
  paper: "#efe6cf"
  steel: "#c9ced6"
  charcoal: "#1c1a1f"
  button: "#2a272e"
  button-hover: "#38333c"
  button-pressed: "#141216"
  parchment: "#eadfc4"
  parchment-dim: "#b8ad94"
  disabled: "#7a7266"
  gold: "#c9a24a"
  gold-bright: "#e8c46a"
  crimson: "#b8322a"
  samurai-red: "#d7372b"
  spirit: "#8fe3ff"
  warning: "#e8795f"
typography:
  display:
    fontFamily: "Yu Mincho, Hiragino Mincho ProN, Noto Serif CJK JP, Noto Serif JP, Noto Serif, Georgia, Times New Roman, serif"
    fontSize: "76px"
    fontWeight: 600
  menu-primary:
    fontSize: "52px"
    fontWeight: 600
  menu-row:
    fontSize: "42px"
    fontWeight: 600
  caption:
    fontSize: "26px"
rounded:
  button: "4px"
  panel: "6px"
  card: "8px"
spacing:
  menu-gap: "8px"
  button-vertical: "10px"
  card-inset: "14px"
  panel-inset: "24px"
  menu-text-inset: "40px"
components:
  button:
    backgroundColor: "{colors.button}"
    textColor: "{colors.parchment}"
    rounded: "{rounded.button}"
    padding: "10px 24px"
  button-hover:
    backgroundColor: "{colors.button-hover}"
    textColor: "{colors.gold-bright}"
  button-pressed:
    backgroundColor: "{colors.button-pressed}"
    textColor: "{colors.gold-bright}"
  menu-primary:
    textColor: "{colors.paper}"
    typography: "{typography.menu-primary}"
    width: "520px"
    height: "132px"
  menu-row:
    textColor: "{colors.parchment}"
    typography: "{typography.menu-row}"
    width: "520px"
    height: "122px"
  card:
    rounded: "{rounded.card}"
    padding: "{spacing.card-inset}"
---

# Design System: Shogun's Last Stand

## Overview

**Creative North Star: "Japanese ink silhouette at dusk"**

The incumbent world is a pale layered sunset landscape with dark fighters, warm celestial light and parchment UI. The approved slim swordsman adds weathered painted cloth and lean anatomy inside that world. He is lightly robed, bareheaded and fast in character, with a long ponytail, grey sash, restrained red waist tails, ankle wraps and sandals.

This records the shipped refinement, not a new world selection. The approved concept and scope are in `docs/slim_samurai/direction.md` and `PRODUCT.md`; no FORM roll or historical seed was run. The original transparent samurai paintings are an explicit exception to the procedural art used for the world and other figures. This is visual work only; combat statistics and timing are unchanged.

**Key Characteristics:**

- Dark readable fighters against a light action band.
- Painted samurai cloth with connected joints and transparent negative space.
- One crimson title action, quiet parchment navigation and restrained gold focus.

## Colors

The frontmatter records shared `InkPalette` values; painted asset pixels are not flat palette tokens.

### Primary

- **Crimson:** the title's Start/Continue ink impression. Its idle fill is the source crimson darkened by 25%; focus brings it to full color and pressing darkens it by 45%.
- **Gold / Gold Bright:** panel edges, titles, focus markers and active text.

### Secondary

- **Samurai Red:** the procedural samurai accent reference; the approved painted sash carries its own muted red shading.
- **Spirit:** energy and supernatural blade effects, distinct from cloth accents.

### Neutral

- **Ink / Ink Back / Ink Detail:** silhouette, far limbs and restrained interior structure.
- **Paper / Steel:** warm highlights and blade glints.
- **Charcoal / Button states:** UI surfaces and native control feedback.
- **Parchment / Parchment Dim / Disabled:** main, secondary and inactive text.

Atmosphere colors come from `data/atmosphere/*.tres` through `Atmosphere.current()`, not the older fallback backdrop constants in `InkPalette`. Golden Sunset runs from indigo through crimson to gold; other stages retain their established themes. See `docs/ART_BIBLE.md` for the full accent and atmosphere tables.

**The Light Action Band Rule.** Keep fighters dark against pale mist and ground-edge washes; keep near bamboo away from the central combat band.

## Typography

The native `SystemFont` title stack is recorded under display; first installed face wins, with Godot's default fallback. Both title menu label sizes inherit that same weight and family. Captions and ordinary body labels use the Godot default font. Values are Godot design pixels, not web responsive sizes.

- **Display:** title menu heading (76 px).
- **Menu primary:** Start/Continue (52 px).
- **Menu row:** secondary title actions (42 px).
- **Caption:** saved progress and stage subcaption (26 px).

No custom line height or tracking scale is established. Battlefield label variations carry ink outlines; reuse those theme variations instead of inventing scene colors.

## Layout

The design viewport is 1920 by 1080 with `canvas_items` stretch and expanded aspect. This is a landscape game, not a CSS breakpoint layout. Title navigation occupies the left column; moon, rock and portrait anchor the right. Backdrop parallax and the moon anchor accommodate wider views. The main menu has an 8 px vertical container separation, 520 by 132 px primary target and 520 by 122 px secondary targets. Painting may sit inside the full native Button hit area.

The title portrait is 540 design pixels high and grounded on its outcrop with both sandals touching rock. Its placement follows the moon/ledge anchor. Gameplay feet remain anchored to the existing fixed-length rig and planted-foot IK; visual transforms do not change collision or reach.

## Elevation & Depth

World depth comes from pale distant washes, darker near silhouettes, parallax, rim lighting and low fog. Native panels have a soft `StyleBoxFlat` shadow (size 16, black at 50% alpha) and a 2 px gold border. This soft UI shadow is retained; the title action itself is a brush impression. Effects such as spirit glows are native world devices, not a general card treatment.

## Shapes

Procedural silhouettes use filled, brush-tapered shapes and scarce interior detail. The approved samurai instead uses transparent painted layers with weathered folds and torn edges. Preserve lean torso, narrow gathered hakama, independent wrapped legs and sandals, long ponytail and low-held katana. No helmet or bulky shoulder armor on this samurai.

Native controls use small radii: buttons 4 px, panels 6 px, cards 8 px. The title primary action has an irregular polygon edge; secondary title rows remain open. Gold focus diamond and chevron are drawn geometry, not text glyph icons.

## Components

### Title navigation

`InkMenuButton` paints one crimson primary impression and open parchment rows. Hover/focus warms row text to gold, reveals geometric markers and subtly tints the row. Active feedback settles over 0.18 s. Pressing uses paper text; disabled labels use the disabled tone. Saved-stage captions sit beneath the primary label. Menu entries fade and slide in sequentially; retain full native focus/input behavior.

### Native buttons and panels

`InkThemeBuilder` generates `assets/ui/ink_theme.tres`: charcoal buttons, parchment text, gold borders on hover/focus and darker pressed fills. The separate `PrimaryButton` variation used outside the title uses a 12% gold blend over button charcoal; do not confuse it with the title's crimson action. Danger buttons use warning text and crimson borders. Panels have 24 px insets; upgrade cards have 14 px insets and a dim locked variant.

### Painted samurai

`SamuraiSpriteArt` shares cached `AtlasTexture` regions and transforms from `slim_parts.png`. Painted sleeve and sash atlas strips follow the cloth chains; their alpha edges and texture remain visible. Head/torso overlap keeps the neck connected. Hair and cloth retain secondary motion on the existing gameplay skeleton. The static `slim_menu.png` portrait is separate, larger, upright and without the stowed yumi. Gameplay and cached figure icons retain their skill equipment and Bow/War Cry transitions.

**The Painted Continuity Rule.** Keep joints connected and all exposed samurai cloth painted; no solid geometric filler over the approved texture.

Evidence sampled: final menu and wide captures, samurai detail and run strip, War Cry battle and figure icon sheet under `builds/slim_samurai/final/`; source theme, title art, palette and atlas mappings. A sampled strip establishes pose appearance, not human judgement of animation smoothness. No Godot build or benchmark was run for this documentation pass.

## Do's and Don'ts

### Do:

- **Do** preserve the existing sunset landscape, menu hierarchy and native control behavior.
- **Do** keep the samurai slim, lightly robed and grounded, with painted cloth and connected joints.
- **Do** reuse the shared theme and cached alpha atlas; keep appearance independent of gameplay statistics.

### Don't:

- **Don't** extend the approved samurai raster exception to unrelated world art without a new decision.
- **Don't** replace painted samurai cloth with flat filler or omit equipment required by a gameplay skill.
- **Don't** treat static captures as proof of animation smoothness or performance.

Not canonized or repaired: the incumbent system-font display stack conflicts with the generic craft-floor font preference; it is retained as an established project choice, not a recommendation for future visual worlds. Historical ART_BIBLE references to the samurai helmet/armor in generic motion text are stale; the approved direction and shipped painted figure govern this character.
