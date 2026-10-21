# Asset licences

The full list of third-party assets in the game: where each came from, its licence, and where the game uses it.
This file is a record for the project. It is NOT shown in the game and NOT included in exports.

What the game shows on its Credits screen is `docs/CREDITS.md`, and that holds only the credits a licence REQUIRES
(plus the creator line). Rule: record every third-party asset here; add it to `docs/CREDITS.md` only if its licence
requires attribution. Most art is drawn by code. The painted character art is original AI-generated artwork made
for this project, not third-party stock; see "AI-generated artwork" below.

## AI-generated artwork

- What: original painted character art generated for this game with an AI image generator. It is not third-party
  stock and carries no attribution licence, so it is NOT on the Credits screen (`docs/CREDITS.md`).
- Tool: the built-in `image_gen` image generator, as `assets/art/samurai/provenance.json` and
  `assets/art/roster/provenance.json` record (generated in the Codex session that made commit 37999aa).
- Date: 2026-10-21 (all files).
- Prompts: recorded in the two `provenance.json` files. The PNGs themselves carry no embedded text.
- Files and where they are used:
  - `assets/art/samurai/slim_menu.png`: the approved slim-swordsman cutout (the concept the samurai is built from).
  - `assets/art/samurai/slim_parts.png`: the samurai's body-part atlas, on his skeleton in battle and on the title
    screen (`SamuraiSpriteArt`).
  - `assets/art/roster/samurai_head.png`: the samurai's head (`SamuraiSpriteArt`). No prompt was recorded for it.
  - `assets/art/roster/ashigaru.png`, `yumi_archer.png`, `shrine_healer.png`, `spear_guardian.png`, `onmyoji.png`,
    `hatamoto.png`, `hollow_soldier.png`, `oni_brute.png`, `fallen_daimyo.png`: one body-part atlas per ally and
    enemy (`RosterSpriteArt`; regions from `tools/register_roster_art.py`), made with `slim_parts.png` as the style
    reference.
  - `assets/art/roster/equipment.png`: the painted weapons, shield, sashimono flag and quiver (`PaintedEquipment`).
    No prompt was recorded for it.

## Music: Free Japanese Fantasy Music Pack by Momiziba

- Source: https://music.storyinvention.com/en/
- Licence: free to use, also in commercial games, as long as the credit line is shown. The credit IS required:
  "Music: Free Music : MOMIZizm MUSiC - https://music.storyinvention.com/en/" stays on the Credits screen.
- Files used (`assets/audio/music/`, the looping versions):
  - `Voice of Evening Calm.mp3`: the main menu and the upgrade shop.
  - `Honobono Teahouse_Loop.ogg`: the stage select screen.
  - `Mountain God's Shrine_Loop.ogg`: battles.
  - `Shamisen Samurai Rock_Loop.ogg`: the boss fight (The Fallen Daimyo).

## Sound effects: Kenney (Impact Sounds, Interface Sounds, RPG Audio)

- Source: https://www.kenney.nl
- Licence: Creative Commons Zero (CC0), https://creativecommons.org/publicdomain/zero/1.0/. No attribution is
  required. The licence texts are in `assets/audio/sfx_kenney/licenses/`.
- Files used (`assets/audio/sfx_kenney/`):
  - Sword hits on allies and the samurai: `impactMetal_light_000` to `impactMetal_light_003` (Impact Sounds).
  - Heavy hits on allies and the samurai: `impactMetal_heavy_000` to `impactMetal_heavy_002` (Impact Sounds).
  - The village gate being hit: `impactWood_heavy_000` to `impactWood_heavy_002` (Impact Sounds).
  - Button clicks: `click_001` to `click_003` (Interface Sounds).
  - Summoning an ally: `impactBell_heavy_000` (Impact Sounds).

## Sound effects: Pixabay

- Source: https://pixabay.com
- Licence: the Pixabay Content License, https://pixabay.com/service/license-summary/. Free to use, also in
  commercial projects. No attribution is required.
- Files used (`assets/audio/sfx_gore/`):
  - The katana swing: `Katana swings.mp3`, `Katana swings2.mp3`.
  - Hits on enemies (picked at random): `Sword Blade Slicing Flesh.mp3`, `Violent Sword Slice.mp3`,
    `Violent Sword Slice 2.mp3`.
  - The heavy hit on an enemy: `Heavy attack.mp3`.
  - The Spirit Slash: `Spirit Slash.mp3`.
  - Enemy death groans (picked at random; an Oni's and the boss's are pitched down): `zombie_groan_1.ogg` to
    `zombie_groan_6.ogg`, cut from the Pixabay recordings `zombie1.mp3`, `zombie2.mp3` and `zombie3.mp3`.

## Sound effects: Sonniss GDC 2024 Game Audio Bundle

- Source: the Sonniss GDC 2024 Game Audio Bundle (https://sonniss.com), a royalty-free bundle.
- Licence: the bundle's own licence: royalty-free, commercial use allowed, no attribution required. Keep the
  licence text that came with the bundle with the originals.
- Files used (`assets/audio/sfx_sonniss/`, each cut from the original named in brackets):
  - `roar.ogg` (`GRWL ROAR ANGRY.wav`): the Oni and the boss arriving; the boss changing phase.
  - `slam_1.ogg` (`Bluezone_BC0294_modern_cinematic_impact_boom_003.wav`) and `slam_2.ogg`
    (`Bluezone_BC0294_modern_cinematic_impact_022.wav`): an Oni's or the boss's slam.
  - `stone_1.ogg` (`Bluezone_BC0297_stone_impact_015.wav`) and `stone_2.ogg` (`Bluezone_BC0297_stone_impact_041.wav`):
    the layer under every heavy hit, and under a hit on the gate.
  - `explosion.ogg` (`EXPLReal_Medium Realistic Explosion 15_DDUMAIS_NONE.wav`): the Onmyoji's fireball exploding.
  - `gate_destroyed.ogg` (`WOODCrsh_Designed Wood Crash And Debris 13_DDUMAIS_NONE.wav`): the gate falling.
  - `boss_summon.ogg` (`DSGN VORTEX IN.wav`): the boss calling minions.
  - `whoosh.ogg` (`WHOOSH PASS SF LOW.wav`): the layer under the Spirit Slash.
  - `ultimate_ready.ogg` (`Short_PowerUp_005.wav`): the Ultimate becoming ready.
  - `eerie_1.ogg` (`DSGNErie_Eerie02_InMotionAudio_SinisterTexturesVolume2.wav`) and `eerie_2.ogg`
    (`DSGNErie_Eerie06_InMotionAudio_SinisterTexturesVolume2.wav`): the quiet loop under the boss music.

## How the recordings were prepared

The originals are large (one wav is 36 MB, one zombie recording is 65 seconds) and are not kept in the project.
`tools/make_sfx_ogg.py` cuts each to the part the game uses, fades it, resamples it to at most 44.1 kHz, matches
the loudness (the loud part of every file sits at -20 dB RMS, peaks below -1 dB; the eerie loops at -24 dB) and
writes Vorbis. The eerie loops are cross-faded into themselves so they repeat without a click. To rebuild the
files, put the originals in one folder and run `python tools/make_sfx_ogg.py --src <folder> --out assets/audio`.
Each sound's final level in the mix is its `volume_db` in `data/audio/sfx_library.tres`.

## Generated by the game's code

The dash, healing, magic, the war cry, the victory and defeat stings, and the fallback for every sound above are
synthesised by `tools/generate_sfx.gd` (`assets/audio/sfx/`). A recorded sound that is missing falls back to its
generated one.

## Samurai detail refinement — 2026-10-21

The following original painted layers replace the battle samurai's low-density body cells. Exact prompts are also embedded in the PNG metadata and recorded in `assets/art/samurai/refinement_prompts.json`.

### body_trunk.png

- File: `assets/art/samurai/body_trunk.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai face/costume as references; no third-party stock or additional attribution requirement.
- Exact prompt:

> Production-ready high-resolution 2 by 2 character-part atlas, four separate parts ONLY, true transparent background, each part has generous margins and occupies most of its quadrant. Render at the highest available native resolution, with each part at the same fine painted ink/watercolour detail as the attached isolated head (style authority). The other attached atlas is the costume/layout reference ONLY. This is the SAME slim fast young unarmoured Japanese swordsman: charcoal black kimono, ivory inner collar, grey tied sash, gathered hakama, wrapped shins and sandals, restrained red waist cloth. Precise anatomical volume, clean crisp ink contours, refined cloth fibres and readable large folds, no blurred paint, no pixel noise, no armour. No text, no grid lines, no backing paper, no assembled figure, no scenery, no cut-off edges. Preserve separate layer roles for the existing bone rig. Top left: headless torso ONLY, from short collar/shoulders to waist, slim and vertically elongated, approx width 55% of height, no arms, no dangling skirt, CLOSED fabric at shoulder pivot seams (no empty hollow sockets). Top right: separate hip skirt of black overlapping robe panels, grey sash tied across the top, bottom ends above knees, with refined ragged fabric edges. Bottom left: separate long black ponytail, complete tie/root on RIGHT, tapering wisps flowing LEFT, not a head. Bottom right: single long restrained dark red flowing waist sash, attachment/knot RIGHT and tapering organic ends LEFT.

### body_arms.png

- File: `assets/art/samurai/body_arms.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai face/costume as references; no third-party stock or additional attribution requirement.
- Exact prompt:

> Production-ready high-resolution 2 by 2 character-part atlas, four separate parts ONLY, true transparent background, each part has generous margins and occupies most of its quadrant. Render at the highest available native resolution, with each part at the same fine painted ink/watercolour detail as the attached isolated head (style authority). The other attached atlas is the costume/layout reference ONLY. This is the SAME slim fast young unarmoured Japanese swordsman: charcoal black kimono, ivory inner collar, grey tied sash, gathered hakama, wrapped shins and sandals, restrained red waist cloth. Precise anatomical volume, clean crisp ink contours, refined cloth fibres and readable large folds, no blurred paint, no pixel noise, no armour. No text, no grid lines, no backing paper, no assembled figure, no scenery, no cut-off edges. Preserve separate layer roles for the existing bone rig. Four HORIZONTAL detached arm layers with shoulder/elbow pivot on LEFT and elbow/wrist/hand on RIGHT. Upper left: near-side upper arm in light black kimono sleeve, broad natural shoulder volume with no hollow cut socket, shoulder pivot center near left at mid-height, elbow at right mid-height. Upper right: near-side wrapped forearm ending in a natural hand with clearly modeled curled fingers gripping an INVISIBLE horizontal katana hilt in a firm closed grip (no sword drawn). Bottom left: far-side upper arm, same black sleeve slightly darker. Bottom right: far-side wrapped forearm and hand, modeled curled fingers closing around invisible hilt. No fingers or sleeve cropped off. Fingers, wrist and cloth equally detailed as the head reference.

### body_legs.png

- File: `assets/art/samurai/body_legs.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai face/costume as references; no third-party stock or additional attribution requirement.
- Exact prompt:

> Production-ready high-resolution 2 by 2 character-part atlas, four separate parts ONLY, true transparent background, each part has generous margins and occupies most of its quadrant. Render at the highest available native resolution, with each part at the same fine painted ink/watercolour detail as the attached isolated head (style authority). The other attached atlas is the costume/layout reference ONLY. This is the SAME slim fast young unarmoured Japanese swordsman: charcoal black kimono, ivory inner collar, grey tied sash, gathered hakama, wrapped shins and sandals, restrained red waist cloth. Precise anatomical volume, clean crisp ink contours, refined cloth fibres and readable large folds, no blurred paint, no pixel noise, no armour. No text, no grid lines, no backing paper, no assembled figure, no scenery, no cut-off edges. Preserve separate layer roles for the existing bone rig. Four HORIZONTAL detached leg layers, proximal pivot LEFT, distal pivot RIGHT, both approximately centered vertically. Top left: near thigh in gathered black hakama, roomy fabric volume but lean athletic anatomy. Top right: near calf with layered charcoal ankle wraps, knee at left, ankle at right, NO foot. Bottom left: far thigh with the same gathered fabric volume, a little darker. Bottom right: far calf and ankle wraps, NO foot. These are substantial athletic legs, not sticks. Keep fixed-length bone endpoints clean, pivot overlap, and visibly separated thigh/calf pieces.

### body_details.png

- File: `assets/art/samurai/body_details.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai face/costume as references; no third-party stock or additional attribution requirement.
- Exact prompt:

> Production-ready high-resolution 2 by 2 character-part atlas, four separate parts ONLY, true transparent background, each part has generous margins and occupies most of its quadrant. Render at the highest available native resolution, with each part at the same fine painted ink/watercolour detail as the attached isolated head (style authority). The other attached atlas is the costume/layout reference ONLY. This is the SAME slim fast young unarmoured Japanese swordsman: charcoal black kimono, ivory inner collar, grey tied sash, gathered hakama, wrapped shins and sandals, restrained red waist cloth. Precise anatomical volume, clean crisp ink contours, refined cloth fibres and readable large folds, no blurred paint, no pixel noise, no armour. No text, no grid lines, no backing paper, no assembled figure, no scenery, no cut-off edges. Preserve separate layer roles for the existing bone rig. Top left: near-side sandal, foot and short wrapped ankle, toes point RIGHT, perfectly level ground sole, natural toes and straps, no leg above ankle. Top right: far-side sandal, foot and short wrapped ankle, same size/toe direction and perfectly level sole. Bottom left: near-side loose sleeve flap ONLY, softly shaded black cloth hanging from narrow attachment at TOP, natural curved and frayed edges, no arm or hand. Bottom right: far-side sleeve flap, slightly darker, same organic cutout edge. Refined skin/cloth shading and sharp painted contours at the same detail as the head.

### body_flow.png

- File: `assets/art/samurai/body_flow.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai face/costume as references; no third-party stock or additional attribution requirement.
- Exact prompt:

> Two isolated production cutout flowing accessories for the SAME lean black-robed samurai shown in the references. Match the detailed ink/watercolour of his isolated head. Wide 2-row composition, ONE accessory per row, generous transparent empty gap between rows and generous margins all around. No other objects, no face, no body. Top row: one long black ponytail with complete small tie and attachment on RIGHT, richly painted flowing wisps tapering LEFT. Bottom row: one long dark RED waist sash, knot/attachment on RIGHT, restrained curved cloth tapering LEFT into natural frayed ends. Both accessories predominantly HORIZONTAL. Crisp refined hair and cloth detail, broad readable shadow planes, charcoal highlights, no blur or halo or detached black debris. Genuine transparent alpha background. No typography, grid, paper or shadows behind objects. These parts will follow cloth curves in a game; each must be fully separate with no other accessory pixels anywhere inside its rectangular bounds.


## Painted title illustration — 2026-10-21

### initial_candidate

- File: `builds/samurai_consistency/title_candidate.png (superseded, not shipped)`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai identity/costume and then the initial candidate as edit references; no third-party stock or additional attribution requirement.
- Exact prompt:

> One finished full-body PAINTED TITLE ILLUSTRATION of the SAME lean Japanese swordsman as the attached head and costume reference. Image one is identity/face authority; image two is costume/material authority, NOT a collage layout. This is a single coherent anatomical painting with naturally connected arms/hands, not a sprite sheet, not puppet parts.
Full standing figure, calm relaxed stance, three-quarter view facing LEFT toward the menu, upright athletic posture, short natural neck and proportionate head. Slim fast unarmoured young man, black layered kimono, ivory inner collar, grey waist sash, gathered black hakama, substantial wrapped calves, sandals. Both soles on ONE flat horizontal line, slight natural stance; complete feet and hair remain inside canvas. Flowing black ponytail and restrained RED sash trail to the RIGHT, free cloth hem gently lifts to the right.
RIGHT HAND holds one katana LOW beside the right thigh: four distinct curved fingers visibly wrapped around the MIDDLE of the dark hilt, thumb opposing, hand well below the chest, guard visible beyond the knuckles, pommel visible behind the hand. The hand must NOT touch the blade or guard. Blade points diagonally down LEFT, its tip still above the sole line. LEFT hand loose beside the body or resting naturally on a dark scabbard at the left hip. No sword or hilt crossing chest, no crossed arms, no floating wrist, no deformed fingers. Elegant modest guard, no ornate giant medallion.
Fine crisp ink/watercolour contours, sculpted skin planes and cloth folds matching the face, charcoal blacks and warm grey highlights, restrained red cloth, no armour, no helmet. Light from behind/upper left so figure reads against the game's pale moon. Character ONLY on a genuinely transparent background: the game supplies moon, rock and sunset scenery. No painted ground/rock/shadow/moon, no typography, border or paper backing. Tall portrait composition with generous transparent margins around the entire figure and sword.

### final_grip_edit

- File: `assets/art/samurai/title_key_art.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the existing project samurai identity/costume and then the initial candidate as edit references; no third-party stock or additional attribution requirement.
- Exact prompt:

> Edit the attached full-body samurai illustration. Preserve his face, identity, costume, stance, sword angle, hair and cloth arrangement and the whole full-body composition. Correct ONLY his sword-holding RIGHT HAND: compact natural CLOSED fist around the middle of the dark hilt, with four short fingers curled across the FRONT of the cylindrical handle and thumb opposing them. Show a clear knuckle ridge and curled fingertips, not long straight fingers laid along the handle. The wrist connects naturally to the wrapped forearm. Leave visible handle on BOTH sides of the fist, with guard separated from the hand. Keep the sword low and avoid any hilt crossing chest. The free left hand stays relaxed. Also remove any ambient haze, shadow or coloured fog behind the character: genuine transparent background and clean soft painted alpha edges only. No white outline. Preserve complete figure and sword inside the canvas.


## Painted HUD bust — 2026-10-21

- File: `assets/art/samurai/hud_bust.png`
- Tool: OpenAI built-in image_gen; date: 2026-10-21.
- Original generated artwork, using the project samurai head and new title painting as identity/style references; no third-party stock or additional attribution requirement.
- Exact prompt:

> A purpose-painted HEAD AND SHOULDERS HUD BUST of the SAME young lean samurai in the two attached references. Exact same face, dark eyes, black hair tied in a ponytail, no helmet, short natural neck, charcoal black kimono with ivory crossed collar, small restrained red tie. THREE-QUARTER view facing slightly RIGHT toward the health bar, calm focused expression. Face centered and large, strong readable eyes and brow, clean jaw silhouette, soft dimensional skin planes. Head occupies about 60 percent of the picture height, shoulders fill the bottom, ponytail curves compactly behind the LEFT side inside the square. This image must read clearly when circularly cropped and displayed at 120 px: broad composed ink values, crisp intentional contour, less tiny hair noise than a large painting, no blur. Match detailed painted ink/watercolour materials and identity of the full-body illustration. Fit the full head and hair tie inside a central circle, shoulders may be cropped at bottom by the frame. Genuine transparent background; no painted circle, frame, moon, words, symbols, halo, drop shadow or backing paper. One square portrait asset only.


## Existing roster PNG provenance metadata — 2026-10-22

ssets/art/roster/samurai_head.png and quipment.png are existing project assets retained from main at 848ed4. Their original exact generation prompts are absent from the current provenance record. This pass embeds that origin statement without claiming a new generation; decoded RGBA SHA-256 hashes were verified identical before and after the metadata write. Existing use and licensing are unchanged.
