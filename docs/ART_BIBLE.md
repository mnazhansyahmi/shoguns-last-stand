# Art Bible — Shogun's Last Stand

Every visual in the game is drawn by code: polygons, gradients and particles generated at
runtime. There are no image files, downloaded assets or third-party art. This document is the
reference for anyone adding to or changing that art. The palette lives in code as
`InkPalette` (`scripts/visuals/ink_palette.gd`), so this document and the game share one
source of values.

## Style in one line

**Japanese ink silhouette at dusk.** Characters are solid near-black cut-outs with clean,
brush-tapered shapes and **one** accent colour each. They stand in front of a pale, layered
ink-wash landscape (misty mountains, bamboo, drifting fog) lit by a warm moon.

The picture should read like a sumi-e painting where only the fighters are fully inked.

## Palette

All values are sRGB hex. The `InkPalette` constant name is in brackets.

### Ink (characters, structures)

| Use | Hex | Constant |
| --- | --- | --- |
| Silhouette fill: bodies, weapons, armour | `#121018` | `INK` |
| Far-side limbs and back layers (depth without outlines) | `#2A2633` | `INK_BACK` |
| Interior detail: armour lacing, plate gaps, cloth folds | `#3B3646` | `INK_DETAIL` |
| Paper highlight: blade edge glint, hit flash | `#EFE6CF` | `PAPER` |

Never use pure black `#000000` or pure white `#FFFFFF`. Ink is slightly violet so it sits in
the indigo world. Paper is slightly warm so it reads as rice paper, not a screen.

### Character accents (exactly one per character)

| Character | Accent | Hex | Constant | Where it appears |
| --- | --- | --- | --- | --- |
| Samurai (player) | Crimson | `#D7372B` | `SAMURAI_RED` | Scarf (two trailing tails) and sash knot |
| Ashigaru | Gold | `#E2B23E` | `ASHIGARU_GOLD` | Jingasa hat rim, sash, spear tassel |
| Yumi Archer | Teal | `#2BB3A3` | `ARCHER_TEAL` | Hachimaki headband tails, quiver fletching, sash |
| Hollow Soldier | Violet glow | `#B56CFF` | `HOLLOW_PURPLE` | Two glowing eyes only (additive halo) |
| Oni Brute | Ember glow | `#D8281E` | `ONI_EMBER` | Eyes, mouth, chest cracks, faint aura (additive) |

Defenders wear their accent as **cloth** (flat, opaque). Enemies wear theirs as **light**
(glowing, additive). So friend vs foe reads even before colour does.

### Shared effect colours

| Use | Hex | Constant |
| --- | --- | --- |
| Spirit energy: Spirit Slash, summon glints, energy bar | `#8FE3FF` | `SPIRIT` |
| Steel glint on blades | `#C9CED6` | `STEEL` |
| Warm lantern and moon light | `#F3DDA4` | `MOON` |

### Backdrop: Bamboo Outskirts (dusk)

Back to front:

| Layer | Hex | Constant |
| --- | --- | --- |
| Sky, zenith | `#1E2238` | `SKY_TOP` |
| Sky, horizon | `#77768F` | `SKY_HORIZON` |
| Moon disc / halo | `#F3DDA4` / `#E9B866` | `MOON` / `MOON_HALO` |
| Far mountains | `#5D6079` | `MOUNTAIN_FAR` |
| Mist (all fog layers) | `#A3A1B4` | `MIST` |
| Mid hills | `#666A84` | `MOUNTAIN_MID` |
| Far bamboo (hazy) | `#757D93` | `BAMBOO_FAR` |
| Near bamboo (frame only, never behind the fight) | `#30364A` | `BAMBOO_NEAR` |
| Ground, top edge (wet wash) | `#807E94` | `GROUND_TOP` |
| Ground, bottom | `#1B1A22` | `GROUND_BOTTOM` |

### UI

| Use | Hex | Constant |
| --- | --- | --- |
| Panel background (92% opaque) | `#1C1A1F` | `UI_CHARCOAL` |
| Button, normal | `#2A272E` | `UI_BUTTON` |
| Button, hover / focus | `#38333C` | `UI_BUTTON_HOVER` |
| Button, pressed | `#141216` | `UI_BUTTON_PRESSED` |
| Primary text | `#EADFC4` | `PARCHMENT` |
| Secondary text | `#B8AD94` | `PARCHMENT_DIM` |
| Disabled text | `#7A7266` | `UI_DISABLED` |
| Borders, highlights, rewards | `#C9A24A` | `GOLD` |
| Focus ring, title | `#E8C46A` | `GOLD_BRIGHT` |
| Danger buttons (border) | `#B8322A` | `CRIMSON` |
| Warning / defeat text on charcoal | `#E8795F` | `EMBER_TEXT` |
| Success / cleared text on charcoal | `#8FCB9B` | `JADE` |
| Spirit energy bar fill | `#2F86B8` | `SPIRIT_DEEP` |

## Value and contrast rules (phone readability)

The game is played on a 6-inch phone at arm's length, so **value contrast is the main
readability tool**, not colour.

1. **The action band is light; the fighters are dark.** Every backdrop colour that can sit
   behind a character (screen y ≈ 560–880 at 1080p) has a contrast ratio of at least
   **3:1** against `INK` (WCAG formula). Mist and ground-edge colours reach **4.5:1** or more.
   A unit test (`tests/unit/test_art_style.gd`) checks this from `InkPalette`.
2. **Dark layers stay out of the fight.** Near bamboo (`BAMBOO_NEAR`) is only drawn at the
   far left (behind the gate) and far right (past the spawn), never in the middle of the field.
3. **Feet stay visible.** The ground's top edge is a pale wash (`GROUND_TOP`) with a mist
   strip just above it, so feet and dropped weapons don't merge into the dark soil.
4. **Accents pop against ink.** Each accent has a contrast of at least 3:1 against `INK`.
5. **UI text** (`PARCHMENT` on `UI_CHARCOAL`) is at least 7:1. Secondary text is at least 4.5:1.
6. **Fog in front of the fighters** is at most 18% opaque and only covers the ground below
   their knees.

## Proportions

Heights are in design pixels at 1920×1080 (on iPhone 16 landscape, 1080 px ≈ 393 pt). Feet
are at the node origin, and every figure faces +x (right) and is mirrored for left.

| Figure | Height | Key proportions | Silhouette hooks |
| --- | --- | --- | --- |
| Samurai | 110 (+ crest) | Head ≈ 1/6.5 H; layered sode on both shoulders; tapered dō (broad chest, narrow waist); hakama flares to a triangle ≈ 0.55 H wide at the hem; katana 0.78 H | Kabuto with a crescent maedate, triangle hakama, saya at the left hip, two scarf tails, long katana |
| Ashigaru | 100 | Hat brim 0.66 H wide; yari spear 1.25 H | Wide flat cone hat, long level spear |
| Yumi Archer | 96 | Bow 1.05 H, grip below centre (asymmetric yumi) | Tall bow, quiver over the back shoulder |
| Hollow Soldier | 110 | Hunched (spine leans 0.28 rad); head forward of chest; long arms | Hunch, broken helmet crest, ragged hem, notched sword |
| Oni Brute | 190 | Shoulders 0.62 H; tiny head; horns 0.13 H; kanabo club 0.8 H | Mass, horns, studded club |

**Silhouette test:** every figure must be identifiable as a pure black shape 40 px tall.
If two figures could be confused at that size, change the shape, not the colour.

## Shape and line rules

- **No outlines.** Shapes are filled polygons. Depth comes from two ink values: front
  (`INK`) and back (`INK_BACK`) for the far arm, far leg and objects behind the body.
- **Brush tapering.** Limbs, scarves, blades, bamboo leaves and hair end in points or rounded
  tapers, never square cuts. Use `InkBrush.limb()` / `InkBrush.stroke()`.
- **Minimum feature size: 4 px** at 1080p (≈1.5 pt on the phone). Anything thinner flickers
  when it moves. The exceptions are deliberate thin lines of at least 1.5 px: the steel glint
  along a blade, a bow string, and `INK_DETAIL` lines inside a silhouette.
- **Interior detail is rare.** `INK_DETAIL` lines (armour lacing, plate gaps) take at most
  about 15% of a figure's area. If you need more, simplify the shape.
- **Accent only in its spots.** A figure's accent colour appears only where the accent table
  says. It's never used for big areas of the body.
- **Glow is for spirits and demons.** Additive blending is used only for enemy eyes and
  auras, Spirit Slash, spirit sparks and the moon/lantern halos.

## Animation rules

All animation is procedural (`UnitVisual`). Gameplay only calls `play_state()`; the visual
blends toward that state's pose every frame. Gameplay never reads the visuals, and damage
never comes from them.

| State | Motion | Timing |
| --- | --- | --- |
| idle | Breathing: torso rises and falls about 1.5%, slight weapon sway | ≈ 0.3 Hz, offset per unit so crowds don't breathe in sync |
| run | Body bob, forward lean, legs stride, scarf and cloth trail | Stride cycle follows move speed |
| windup | Weapon pulled back, body coils | Eases in. The Oni is visibly slow (it telegraphs) |
| strike | Weapon snaps through. The slash trail covers the arc | ≤ 60 ms to reach the pose |
| cast | Katana raised overhead, blade glows `SPIRIT` | Eases in |
| dash | Hard forward lean, low crouch, ink afterimages | Instant |
| hurt | Recoil back, head snaps, then recovers | ≈ 120 ms out, 200 ms back |
| dead | Falls backward around the feet, then dissolves into ink | Fall 350 ms, dissolve by 0.8 s (corpse time) |
| spawn | Allies rise from an ink splash; enemies emerge from violet smoke | 0.4–0.7 s (data `spawn_duration`) |

Combo hits alternate: a downward cut, a rising cut, then a level thrust.

## Effects (VFX)

| Effect | Look | Rules |
| --- | --- | --- |
| Katana slash trail | Crescent along the blade arc. Paper-white core with the wielder's accent at the edge | Fades in 0.18 s. Heavy attacks are wider |
| Hit sparks | 6–10 short paper/gold sparks and a small ink blot. Defender hits use crimson sparks | 0.25 s, capped like damage numbers |
| Spirit Slash | Glowing `SPIRIT` crescent with an additive halo and trailing wisps | Visual only; the hitbox is unchanged |
| Summon | Ink splash on the ground with spirit glints; the ally rises out of it | 0.5 s |
| Enemy spawn | Violet smoke puff at the feet | 0.5 s |
| Death | Body falls, then breaks into ink droplets that drift up and fade | Done within corpse time |
| Oni slam | Ground-level ink shockwave ring | 0.3 s |

Effects never deal damage, never block input, and free themselves.

## UI

- One theme, `assets/ui/ink_theme.tres`, set as the project's custom theme, so every
  Control uses it. It's generated by `tools/make_ui_theme.gd` from `InkPalette`: edit the
  script, then re-run it.
- Panels: charcoal, a 2 px gold border, small corner radius (4 px), soft shadow.
- Buttons: charcoal, parchment text, gold border on hover and focus, and a darker press state.
  Touch targets keep their existing minimum sizes (see ARCHITECTURE.md).
- Text always has a dark outline when it sits on the battlefield (HUD, damage numbers).
- Named variations (`theme_type_variation`) replace per-scene colour overrides:
  - Labels: `TitleLabel` and `HeaderLabel` (serif, gold), `GoldLabel`, `DimLabel`, `WarningLabel`, `SuccessLabel`, `SpiritLabel`.
  - Battlefield labels with an ink outline: `HudLabel`, `HudDimLabel`, `HudTitleLabel`, `HudBannerLabel`, `HudMessageLabel`.
  - Buttons: `PrimaryButton` (the screen's main action), `ToggleButton` (lit gold when on), `DangerButton` (reset progress).
- Titles use a serif system font (Yu Mincho / Hiragino Mincho / Noto Serif / Georgia, whichever the device
  has). Nothing is downloaded; if none is installed, Godot falls back to its default font.
- Drawn widgets (HUD bars, touch buttons, joystick, world health bars, damage numbers) take their colours
  from `InkPalette`. Touch buttons are charcoal discs with a gold rim and the action's colour as a ring.
- **Title screen:** the Bamboo Outskirts backdrop with a dark wash behind the menu column, an ink rock
  outcrop, and the samurai silhouetted against the moon, scarf in the wind, with bamboo leaves drifting
  past. The menu screens reuse the backdrop behind a charcoal veil.

## Performance rules

- Static shapes are built once into an `InkBatch` (one draw call) and replayed. Never rebuild
  geometry every frame unless the shape really changes (cloth, hem).
- Characters animate by moving their part nodes, not by redrawing. Keep the number of parts
  per figure low (about a dozen): merge shapes that share a transform into one part.
- Shapes that animate on their own (cloth, hems) should cycle through a few cached shapes when
  they can; only the cloth tails are redrawn every frame.
- New effects free themselves and stay short (≤ 0.6 s). Anything spawned per hit is capped.

## Adding new art

1. Add any new colour to `InkPalette` first, and to the tables above.
2. Draw it with `InkBrush` helpers in a figure or backdrop painter.
3. Check it against the silhouette test and the contrast rules. Run the tests, then render
   screenshots with `tools/capture_screenshots.gd` and look at them at phone size.
