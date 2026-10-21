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
  reward-total:
    fontSize: "76px"
  reward-label:
    fontSize: "25px"
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
  skill-icon:
    width: "66px"
    height: "66px"
  result-action:
    height: "124px"
---

# Design System: Shogun's Last Stand

## Overview

**Creative North Star: "Japanese ink silhouette at dusk"**

The incumbent world is a pale layered sunset landscape with dark fighters, warm celestial light and parchment UI. The approved slim swordsman adds weathered painted cloth and lean anatomy inside that world. He is lightly robed, bareheaded and fast in character, with a long ponytail, grey sash, restrained red waist tails, ankle wraps and sandals.

This records the shipped refinement, not a new world selection. The approved concept and current scope are in `docs/slim_samurai/approved_concept.png`, `docs/game_feel/direction.md` and `PRODUCT.md`; no FORM roll or historical seed was run. Original transparent samurai paintings coexist with the established landscape and roster systems. The game-feel pass retains this world while refining stride continuity, painted body volume, cached skill pictures, battle results and title lighting. Combat statistics and skill timing are unchanged.

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
- **Reward total / label:** the three parallel earned-result columns use the default font at the frontmatter sizes. Their parchment, gold and spirit theme roles distinguish defeated enemies, gold and XP.

No custom line height or tracking scale is established. Battlefield label variations carry ink outlines; reuse those theme variations instead of inventing scene colors.

## Layout

The design viewport is 1920 by 1080 with `canvas_items` stretch and expanded aspect. This is a landscape game, not a CSS breakpoint layout. Title navigation occupies the left column; moon, rock and portrait anchor the right. Backdrop parallax and the moon anchor accommodate wider views. The main menu has an 8 px vertical container separation, 520 by 132 px primary target and 520 by 122 px secondary targets. Painting may sit inside the full native Button hit area.

The title portrait is 540 design pixels high and grounded on its outcrop with both sandals touching rock. Its placement follows the moon/ledge anchor. Gameplay feet remain anchored to the existing fixed-length rig and planted-foot IK; visual transforms do not change collision or reach.

Results center a 1440 design-pixel content column over the visible battlefield, with three earned-total columns separated by 60 px, a 920 by 18 px XP track and one native action row with 20 px separation. Result actions use the frontmatter height. The Next action has a 430 px minimum width and expands from measured label width. All brush-button labels reserve 56 px at the trailing edge so focus chevrons remain clear. These are Godot layout measurements, not browser breakpoints; desktop and wide-phone captures exercise the same landscape layout.

## Elevation & Depth

World depth comes from pale distant washes, darker near silhouettes, parallax, rim lighting and low fog. Native panels have a soft `StyleBoxFlat` shadow (size 16, black at 50% alpha) and a 2 px gold border. This soft UI shadow is retained; the title action itself is a brush impression. Effects such as spirit glows are native world devices, not a general card treatment.

The title's painted rock shares weathered ink detail with the portrait. Dusk grading compresses bright cloth, warm rim light follows the scene and cool bounce darkens the soles. Small layered contact shadows sit directly under both fixed sandals. Results use open ink/crimson washes and a dimmed battlefield rather than a large bordered panel.

## Shapes

Procedural silhouettes use filled, brush-tapered shapes and scarce interior detail. The approved samurai instead uses transparent painted layers with weathered folds and torn edges. Preserve the slim identity, gathered hakama, independent wrapped legs and sandals, long ponytail and low-held katana. Fuller torso, thigh and calf presentation comes from widening painted layers across their bone axes; head scale and bone lengths stay fixed. No helmet or bulky shoulder armor on this samurai.

Native controls use small radii: buttons 4 px, panels 6 px, cards 8 px. The title primary action has an irregular polygon edge; secondary title rows remain open. Gold focus diamond and chevron are drawn geometry, not text glyph icons.

## Components

### Title navigation

`InkMenuButton` paints one crimson primary impression and open parchment rows. Hover/focus warms row text to gold, reveals geometric markers and subtly tints the row. Active feedback settles over 0.18 s. Pressing uses paper text; disabled labels use the disabled tone. Saved-stage captions sit beneath the primary label. Menu entries fade and slide in sequentially; retain full native focus/input behavior. Its shared label measurement and trailing reserve also govern result actions.

### Native buttons and panels

`InkThemeBuilder` generates `assets/ui/ink_theme.tres`: charcoal buttons, parchment text, gold borders on hover/focus and darker pressed fills. The separate `PrimaryButton` variation used outside the title uses a 12% gold blend over button charcoal; do not confuse it with the title's crimson action. Danger buttons use warning text and crimson borders. Panels have 24 px insets; upgrade cards have 14 px insets and a dim locked variant.

### Painted samurai

`SamuraiSpriteArt` shares cached `AtlasTexture` regions and rigid transforms across high-resolution `body_trunk.png`, `body_arms.png`, `body_legs.png`, `body_details.png` and `body_flow.png` sheets. The separate `assets/art/roster/samurai_head.png` retains the identity reference; the legacy atlas supplies the blade. `InkFigure` applies linear mipmapped anisotropic sampling to the samurai as a whole, and both head and body imports generate mipmaps. This keeps the face and cloth sampling coherent at battle scale. Painted sleeve and sash strips follow anchored cloth chains; the head overlap keeps the neck compact and connected. Fixed bone lengths, planted-foot IK, gripping hands, skill equipment and Bow/War Cry transitions retain the existing gameplay contract.

The title uses one coherent full-body `title_key_art.png` painting, without the stowed yumi. `PortraitMotion` is a `Node2D` drawing a shared static UV mesh; its three weight channels affect only free hair, sash and hem. Shader uniforms advance subtle wind and a blade glint. Face, hands, torso, legs and soles stay pinned: there is no limb rig or whole-body breathing. `title_art.gd` uses a positive uniform scale without mirroring, preserving the painting's native right-hand katana grip and relaxed other hand. Preserve the approved slim, bareheaded identity and contact with the rock.

Free-edge wind is stronger in the game-feel pass while remaining confined to those masks. The portrait shader supplies dusk ambient grading, warm rim light and cool ground bounce. `title_rock.png` is the painted foreground beneath the fixed soles; its contact shadows follow the ledge placement, never the free-edge wind.

### Grounded locomotion

`LegGait` advances by distance travelled, with speed-matched step extent. Light figures interpolate the stride multiplier from 0.65 to 1.75; heavy and limping figures retain 0.65 to 1.2. Reach is capped at half the summed thigh/shin lengths. Swing travel uses smoothstep and vertical lift uses a squared sine arc, with gentle heel roll before touchdown. Both foot trajectories contribute continuously to horizontal hip shift; `InkFigure` derives the pelvis envelope from both legs instead of switching a selected support foot. `UnitVisual` waits for gait settlement before returning to upright idle. Preserve planted anchors, fixed-length IK, forward knees and existing combat states.

**The Grounded Stride Rule.** Settle the swing before upright idle, and fit the pelvis continuously to both legs; add body volume across the painted bone axes without changing bone lengths.

### Compact figure skill pictures

`SkillIcon` uses cached `FigureSkillArt` pictures in compact round frames at the frontmatter size. The cache bakes the game's figures once into 256 px textures, then frees the render targets; the HUD does not keep live figure rigs. Preserve the lower-right key badge, cooldown sweep and seconds, ready glow, and locked dim/lock overlays. Stance swaps charge/hold figure art. Existing upgrade and touch-control figure art retain their own established presentation. The restored skill pictures supersede the intervening glyph presentation.

### Battle results

`ResultCelebration` draws a crossed-katana crest and open brush washes over the battlefield. The three large earned totals lead; enemy/bonus breakdowns, replay gold reduction, cumulative progress, level-up, new ally and save status stay readable below them. The XP track uses the shared native theme. `InkMenuButton` supplies Next, Retry, Upgrades and Main Menu actions, with the primary action and focus chosen from the result state. Combat HUD is cleared at actual battle end before this overlay is shown. Save failure keeps the explicit reward-loss warning; defeat retains its warning-color heading and retry emphasis.

Full motion presents one short crest burst and an XP fill reveal over 0.8 s. Reduced decorative motion sets both immediately to their resting values; it does not defer reward truth or input.

### Ultimate portrait medallion

`HudUltimateRing` draws the dedicated `hud_bust.png` three-quarter head-and-shoulders painting through a circular UV polygon with linear mipmapped sampling. The shared texture is reused directly; there is no live character rig or `SubViewport`. The existing clockwise gold charge ring, bright READY halo, READY/percentage plate, key badge and low-health red rim remain the state language. The bust changes portrait art, not the HUD layout or Ultimate behavior.

### Character secondary motion and preference

`SecondaryMotion` keeps loose parts anchored in world space and resets chains after teleports. All six allies retain distinct cloth responses: brisk ashigaru tails, light archer ribbons, soft healer cloth and hair, restrained guardian cords, flowing onmyoji ribbons and a weighted Hatamoto banner. Body poses, feet and chain simulation advance at the full visual update rate; only cosmetic cloth repaint outside the samurai is capped at 30 Hz. Samurai hair and cloth repaint remain at the full visual update rate (60 Hz in the recorded sequences).

`SettingsPanel` exposes Motion: Full / Reduced, persisted by `SettingsStore` and applied through `GameSettings`. Reduced mode uses 15% decorative wind/glint amplitude in the title portrait and 15% amplitude in relevant secondary-motion drivers, and resets hair/tail chains to their rest shapes rather than retaining inertial whip. Combat poses and planted-foot animation remain active.

**The Painted Continuity Rule.** Keep joints connected and all exposed samurai cloth painted; no solid geometric filler over the approved texture.

Current scope evidence is in `docs/game_feel/`: `main_menu.png`, `hud.png`, `samurai_detail.png`, `gait_strip.png`, `samurai_motion_sheet.png`, `victory.png`, `victory_first_clear.png`, `defeat_save_error.png`, `phone_results.png` and `crowded_battle.png`, with actual renderer-frame sequences in `before.webp`, `after.webp`, `gameplay.webp` and `menu.webp`. This record samples the menu, HUD, first-clear and wide-phone results captures against their native drawing/layout code, and checks gait, pelvis, idle settlement, painted sampling and title shader sources. Earlier roster evidence remains relevant to unchanged ally motion. Captures support visual review; they do not certify continuous smoothness or device performance. No Godot build or benchmark was run for this documentation pass; performance budgets are not established here. Native Godot has no DOM/CSS detector.

## Do's and Don'ts

### Do:

- **Do** preserve the existing sunset landscape, menu hierarchy and native control behavior.
- **Do** keep the samurai slim, lightly robed and grounded, with painted cloth and connected joints.
- **Do** reuse the shared theme and cached painted textures; keep appearance independent of gameplay statistics.

### Don't:

- **Don't** extend the approved samurai and title-rock raster exceptions to unrelated world art without a new decision.
- **Don't** replace painted samurai cloth with flat filler or omit equipment required by a gameplay skill.
- **Don't** treat static captures as proof of animation smoothness or performance.

Not canonized or repaired: the incumbent system-font display stack conflicts with the generic craft-floor font preference; it is retained as an established project choice, not a recommendation for future visual worlds. Historical ART_BIBLE references to the samurai helmet/armor in generic motion text are stale; the approved direction and shipped painted figure govern this character.
