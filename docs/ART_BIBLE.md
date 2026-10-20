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
| Shrine Healer | Jade `#5FD4A0` | `HEALER_JADE` | Hair ribbon, obi, the paper streamers of the gohei wand |
| Spear Guardian | Azure `#4F86E0` | `GUARDIAN_AZURE` | Helmet cord, the rim of the shield, the spear tassel |
| Onmyoji | Magenta `#D65DB1` | `ONMYOJI_MAGENTA` | Hat ribbons, belt, the seal on the talisman |
| Hatamoto | Orange `#F08A2E` | `HATAMOTO_ORANGE` | The banner on his back, sash, helmet cord, naginata tassel |
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

### Atmosphere: a sunset theme per stage

The backdrop is a sunset, and each stage has its own colour theme (`AtmosphereTheme`, files in
`data/atmosphere/`, named by `StageData.atmosphere`). A theme holds every backdrop colour, the sun, the
clouds, the reeds, the leaves, the rays, the rim light and the wind. Painting code never uses a
hard-coded backdrop colour; it reads the current theme (`Atmosphere.current()`).

| Stage | Theme | Sky, top to horizon | Sun | Leaves and wind |
| --- | --- | --- | --- | --- |
| 1 The Village Gate | Golden Sunset | indigo, crimson, gold | pale gold disc | red maple, medium wind |
| 2 Bamboo Path | Rose Dusk | violet, rose, peach | pink disc | rose petals and red leaves, light wind |
| 3 Misty Grove | Misty Grove | deep teal, olive, pale gold | cream disc | amber leaves, calm |
| 4 Broken Shrine | Broken Shrine | charcoal violet, blood red, ember | big red-orange disc | red and ash, strong wind |
| 5 Oni's Hollow | Oni's Hollow | near-black indigo, crimson, ember | an eclipse: dark disc, burning ring | embers and red leaves, strongest wind |

Rules every theme must keep (a test checks them): the sky gets lighter toward the horizon; everything
that can stand behind a fighter (`sky_low`, `sky_horizon`, both mountain colours, far bamboo, reed
stalks) is at least **3:1** against `INK`, and the mist and the ground's edge **4.5:1**; the reed
plumes and the rim light are light colours; leaves are at least 2:1. The tables below are the original
dusk values, kept in `InkPalette` as the fallback and for the title screen's base colours.

### Backdrop: Bamboo Outskirts (original dusk values)

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

## Atmosphere in motion

- **Wind** (`Atmosphere`): one wind drives everything. Its strength is the theme's base level plus slow,
  uneven gusts (a few sine waves of different lengths), and a gust travels along the field as a wave, so
  neighbouring stalks bend one after another instead of together.
- **Pampas grass and reeds** (`ReedsBack`, `ReedsFront`): pale stalks with feathery plumes standing on the
  ground line behind the fighters (light, so the dark fighters read in front), low grass below the
  fighters' feet and tall pampas framing both edges in front. They are static geometry bent by a vertex
  shader (`reed_sway.gdshader`): each vertex carries a sway weight (0 at the root, 1 at the tip) in its
  colour alpha, so the tip leans most. Front grass never rises above the fighters' ankles in the middle of
  the field.
- **Falling leaves and petals** (`AtmosphereLeaves`): about 40 in two layers: small, dim ones behind the
  fighters and a few big, fast, fully lit ones passing in front. They tumble (flip as they spin), sway,
  sink and are carried downwind by the same gusts; one that leaves the screen is reborn above or upwind.
- **Sky:** indigo to crimson to gold, with a sun (or an eclipse) and two drifting layers of layered
  clouds: a shaded body with a gold-lit underside, flat below and lumpy above.
- **Light rays:** nine thin additive beams fanned from the sun across the fog, fading with distance. The
  layer breathes slowly and brightens a little in a gust. They only ever add light, so they lift the
  backdrop behind the fighters and never lower the contrast.
- **Rim light:** a thin, soft sliver of sunlight on the sun-facing (upper-right) edge of every character part.
  It must look like sunlight, never like a selection outline: it is the theme's own warm sun colour (gold,
  orange or rose, `AtmosphereTheme.rim_color`, never a picked contrast colour) at half opacity
  (`Atmosphere.RIM_STRENGTH` 0.5), about 1.3 world pixels thick (`RIM_THICKNESS`). Each part's triangles are
  drawn twice in one command (`InkBatch.with_rim()`): first a copy flagged in the UVs, which the shared
  `rim_light.gdshader` pushes toward the sun (in world space, so it stays on the sun's side however the part
  turns or the figure is mirrored) and tints, then the part itself on top. Only the edge that sticks out
  shows. The ground shadow and the spirit glow are not lit.
- **Hit flash:** 0.08 s, and only a partial lightening (`InkFigure.FLASH_MODULATE` 2.4x): a hit figure stays a
  dark silhouette against the sky. It never turns pale or white.

## Characters with life

The Hollow Soldier is the reference: uneven, torn shapes, cloth that moves, a light that flickers, a way of
standing that tells you who it is. Every character now has the same things (original designs, nothing copied).

- **Torn, fluttering cloth** (`FigureTatters`): each character has a strip, skirt, cloak or flag with a torn free
  edge. The shape of the tear is fixed per kind; only the ripple changes. Every shape is built once per kind,
  flutter phase and wind level (12 x 3) and cached, so a figure only swaps between a few cached batches about a
  dozen times a second (the same trick as the Hollow Soldier's hem). The cloth follows the figure's own clock,
  so no two soldiers ripple together.

  | Kind | Cloth |
  | --- | --- |
  | Samurai | torn under-robe strip trailing from his hip |
  | Ashigaru | ragged tabard under the do |
  | Yumi Archer | short cloak from the shoulders |
  | Shrine Healer, Onmyoji | torn hem under the hakama |
  | Spear Guardian | torn tabard over the legs |
  | Hatamoto | the banner's flag, torn along its free edge (the pole and mon stay solid) |
  | Oni Brute | strips of hide under the loincloth |

- **One glowing detail each**, flickering (two uneven sine waves, each figure on its own phase, never in step):
  samurai the blade's point (calm), ashigaru the tassel, archer the fletching, healer the gohei streamers, guardian
  the shield rim, onmyoji the seal on the talisman (a candle), hatamoto the mon on the banner, Hollow its eyes,
  Oni its cracks and eyes.
- **Allies are a lighter tone.** The six allies are drawn in a blue-slate ink (`ALLY_INK`, `ALLY_INK_BACK`,
  `ALLY_INK_DETAIL`: `FigurePainter.tone_batch()` swaps the three inks when the part is built), the enemies and
  the samurai in the near-black ink. The ally tones keep at least 3.5:1 (near) and 2.8:1 (far limbs) against
  every theme's backdrop. The accents are untouched.
- **Idle personality** (`FigureKinds.Spec` `breath_*`, `idle_*`): the samurai is calm (slow deep breathing, a still
  blade, a slow turn of the head), the Oni restless (fast heaving breath, stomping from foot to foot, a twitching
  club), the healer gentle (slow sway, soft head tilt), the ashigaru nervous, the archer alert, the Hollow unquiet,
  the guardian stoic, the onmyoji serene (the talisman drifts), the hatamoto proud. Standing poses are stronger: a
  braced ashigaru, a planted guardian, a hunched Oni.
- **No two soldiers alike** (`UnitVisual.enable_variation()`, used by every enemy and ally, not the player): a
  random animation, stride, cloth and flicker phase, +-6% size, +-10% walking speed, a small vertical offset
  (-4 to +1.5 px), and now and then a head turn or (while running) a stumble. Enemies also keep a random,
  irregular distance from the one in front (0.8 to 1.25 times the usual), so a column never marches as one line.
- **Allies are drawn apart.** Each ally is drawn in its own sideways lane (`Ally.LANES`, up to 63 px either
  side, handed out in turn), and its health bar goes with it, so a group standing on one spot reads as separate
  people. Only the picture moves: bodies, hitboxes, reach and summoning are exactly as before. Physically
  spreading the allies (formation offsets, summon spacing, pushing each other apart) was tried and made them
  clearly weaker in `tools/balance_sim.gd` (allies-only stage 1: about 215 s and 35 allies summoned became about
  280 to 300 s and 50), because stacked allies fight better, so it was not kept.
- **Health bars** of a hurt enemy hide 2 s after the last hit (fading over the last 0.4 s) and come back on the
  next one, so a crowd is not a row of bars.
- **Leaves** never fly over the HUD or the touch controls (`AtmosphereLeaves.keep_out`).

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
| Samurai | 110 (+ crest) | Head ≈ 1/6.5 H; four-lame sode fanned on both shoulders; tapered dō of overlapping lamellar bands (broad chest, narrow waist); five hanging kusazuri over a pleated hakama that flares to ≈ 0.5 H at the hem; katana 0.78 H | Kabuto with a crescent maedate and layered shikoro, A-line hakama, saya at the left hip, two long scarf tails, long katana |
| Ashigaru | 100 | Hat brim 0.66 H wide; yari spear 1.25 H | Wide flat cone hat, long level spear |
| Yumi Archer | 96 | Bow 1.05 H, grip below centre (asymmetric yumi) | Tall bow, quiver over the back shoulder |
| Shrine Healer | 98 | Ponytail swept back; wide flared miko hakama; long sleeves (cloth flaps); gohei wand 0.6 H | Long wand with two zigzag paper streamers raised above her head, ponytail |
| Spear Guardian | 108 | Broad do and big sode; tall tate shield on the back arm (0.5 H tall); yari 1.2 H | A tall dark slab (the shield) in front of the body, a blade-like crest on the helmet, a very long spear |
| Onmyoji | 104 (+ hat) | Tall eboshi cap (0.2 H); broad kariginu shoulders; sleeves; paper ofuda 0.3 H | Tall leaning cap, pale talisman slip held up |
| Hatamoto | 106 (+ banner) | The samurai's armour, hakama and skirt; kuwagata horns in a V; naginata 1.1 H | A banner pole on his back rising well above his head with an orange flag, two horns, a curved blade |
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
- **Armour is layered plates, not boxes.** Do, sode, kusazuri and shikoro are overlapping lames, each a little tilted (the front edge lower than the back) with a pale `INK_DETAIL` seam along its lower edge and short lacing ticks. Never stack bare rectangles.
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

### Samurai motion (springy figures)

The samurai (and any kind with `Spec.springy`) is driven by `PoseSpring` instead of a plain blend:

- **Anticipation.** Every wind-up raises or draws the blade the other way first (raised blade and coiled body for the downward cut, low blade for the rising cut, point drawn to the hip for the thrust, a deep crouch for the heavy). The spring overshoots the wind-up pose a little.
- **Acceleration.** The strike is a stiff, lightly damped spring (about 0.4–0.5 damping), so the blade accelerates into the cut instead of moving at a constant rate: about 60% of the cut is covered within four frames.
- **Follow-through.** The blade overshoots the strike pose, then settles. While the strike state lasts the aim drifts back toward guard, so the body relaxes instead of freezing.
- **Arcs.** The hand moves on an arc around the shoulder (`FigurePose.pivot`), so the arm keeps its length and the blade sweeps rather than slides.
- **The blade never passes through his body.** Every pose keeps the katana, from the hands out, in front of him and clear of the helmet, crest, armour and hakama, and every grip is within the arm's reach (26) so arms never stretch. `FigureKinds.samurai_body_zones()` describes the solid body and `tests/unit/test_samurai.gd` checks every key pose and the paths between them. When you add or move a pose, run the tests.

### Secondary motion

Loose parts lag behind the body (`SecondaryMotion`, stepped from `InkFigure.refresh()`):

- **Scarf tails, headband tails and sleeve flaps** are `ClothChain`s: Verlet chains in world space with a fixed link length and a soft pull toward a rest shape. They trail when he runs, whip when he turns, and swing past and settle when he stops. The scarf is drawn over the neck guard so its red always reads.
- **Hakama legs, the armour skirt (with the scabbard and sash) and the shoulder lames** swing on damped springs driven by the body's forward speed, so the hem trails while he runs and overshoots when he stops.
- Nothing here affects gameplay, and an off-screen figure is not stepped. A long gap or a teleport restarts the cloth instead of whipping it.

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
| Ultimate slash | One short, bold crescent in front of the samurai at chest height (reach 30% of the screen width, never a line across the whole screen): crimson glow edge, bright crimson body, pale core and a few crimson drops. No dark ink, no wash, no flash, so the battle stays visible | Laid down in 0.11 s, a 0.15 s freeze as it lands, fades in 0.25 s (0.4 s in all). Real time, screen space |

Effects never deal damage, never block input, and free themselves.

## UI

- One theme, `assets/ui/ink_theme.tres`, set as the project's custom theme, so every
  Control uses it. It's generated by `tools/make_ui_theme.gd` from `InkPalette`: edit the
  script, then re-run it.
- Panels: charcoal, a 2 px gold border, small corner radius (4 px), soft shadow.
- Buttons: charcoal, parchment text, gold border on hover and focus, and a darker press state.
  Touch targets keep their existing minimum sizes (see ARCHITECTURE.md).
- Text always has a dark outline when it sits on the battlefield (HUD, damage numbers). Damage
  numbers are 40 px with a solid 12 px ink outline.
- Enemy health bars only appear once the enemy is hurt, are short, and stack when they overlap.
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
  they can; only the cloth tails and sleeve flaps are redrawn every frame (each is one small strip).
- New effects free themselves and stay short (≤ 0.6 s). Anything spawned per hit is capped.
- The atmosphere costs almost nothing per frame: the sky, clouds, rays and reeds are static geometry
  (the reeds are moved by a vertex shader, the rays by a modulate), the rim light is one shared material
  and one draw command per part, and only the ~40 leaves are simulated and redrawn (one batch each).
  Measured with `tools/perf_battle.gd` (30 enemies, 6 allies): about +0.3 ms. Keep the 30-enemy test
  under 8 ms.

## Adding new art

1. Add any new colour to `InkPalette` first, and to the tables above.
2. Draw it with `InkBrush` helpers in a figure or backdrop painter.
3. Check it against the silhouette test and the contrast rules. Run the tests, then render
   screenshots with `tools/capture_screenshots.gd` and look at them at phone size.

## The Fallen Daimyo (stage 5 boss)

A corrupted samurai lord in the same ink style, bigger than the Oni (250 px tall against 190). Original design:
a hunched, broad dō with uneven tassets (some broken off), a rope sash with a frayed end, one cracked-away shoulder
plate, a battered kabuto with one tall bent horn and one snapped stump and ragged neck lames, and a long torn cloak
streaming from his shoulders (`FigureTatters`). His one accent is the cursed green-yellow `DAIMYO_CURSE` (`#B4EC3C`):
the cracks in his armour, his eyes and the cutting edge of his two-handed odachi, all with a flickering glow (the blade's
glow runs along its whole length). `DaimyoFigurePainter` builds him; he wears the enemies' near-black ink.

- **Phases look different** (`UnitVisual.set_rage()`, `InkFigure.rage`): lights burn brighter in each phase, a burning
  aura appears around his whole body in phase 2 and a bigger one in phase 3, and he is 3.5% bigger per phase.
- **Poses are readable wind-ups** (`FigureKinds._daimyo`): `windup` coils the blade high behind him and crouches (sweep, leap),
  `heavy_windup` raises it overhead (slam; also in the air during the leap), `cast` holds it straight up and glowing (wave,
  summon), `strike` swings it flat (sweep) or down (heavy).
- **Warnings** (`AttackTelegraph`): an outline always visible plus a fill that grows over the wind-up, in the accent colour,
  on the ground where the attack lands: an oval for the sweep, slam, leap and each summoned soldier, a fainter strip for the
  wave. They are visual only.
- **Cursed wave** (`CursedWave`): a dark crescent with a cursed edge racing along the ground; it fades over its last 160 px.
