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
