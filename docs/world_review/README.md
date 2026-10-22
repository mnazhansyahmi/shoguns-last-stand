# Painted world review

Local work on `v0.2`, 2026-10-22. No publishing; Region 1 generator never run.
Existing unrelated `project.godot` ordering edit is preserved outside these commits.

## 1. Painted region backgrounds

Five authored painted layers per region replace the geometric scenery. Original
parallax depths, drifting fog, light rays, falling leaves/embers and wind sway
remain. Each region owns its gate damage art and portal. Fire uses a painted
texture deformed by a shader, with six bounded scenery flames; no backdrop
geometry or flame geometry is rebuilt each frame. Generated sources preserve
alpha; authored atlas bounds are sampled directly in Godot. All five image
prompts/tool/date records are in `docs/ASSET_LICENSES.md` and beside the assets.

Full suite: **503 passed, 0 failed**. Import and boot passed.
[Tests](part_1/tests_1.log), [import](part_1/import_1.log), [boot](part_1/boot_1.log).
[Bamboo battle](part_1/region_1.png), [Burning Village battle](part_1/region_2.png).

Region 2 30-enemy probe, 120 warmup + 900 measured frames, fixed 60 Hz simulation,
uncapped Compatibility renderer, RTX 5060 Laptop GPU. Fresh isolated baseline
snapshot, three sequential runs per version, no simultaneous tests/simulations:

| Version | Run averages | Mean average | Mean p95 |
| --- | --- | ---: | ---: |
| Existing world | 10.33 / 10.15 / 10.24 ms | 10.24 ms | 12.56 ms |
| Painted world | 10.16 / 10.29 / 10.76 ms | 10.40 ms | 13.31 ms |

The painted-world mean stays below the requested historical **10.75 ms** ceiling.
The fresh baseline is 0.16 ms faster; these separate short samples do not prove
zero regression. Final measurements after all parts will recheck the full build.
Raw logs are in this folder. Region 2 staged art renders include the General
even on stage 8, to review effects; they are not normal stage 8 wave compositions.

## 2. Readable new enemies

Flying Spirits now use a complete painted onryo with a 130 px human-sized body,
80 px hover, a soft ground shadow, bob and flowing robe shader. The segmented
body is hidden and its redundant cloth solver is disabled; air targeting and
damage filtering remain. Death/spawn opacity still wraps the whole painting.

The General is 310 px tall (Oni: 190), with painted fire on both shoulders and
the odachi, 16 bounded rising embers, glowing painted eyes and local heat haze.
Fire trails accompany attacks; pillars now use painted flames with their old
damage hitboxes. His entrance adds a fire burst, settings-respecting camera
shake and a name card. The boss health bar is positioned below the actual
player/wave cluster extents at all tested UI scales.

Full suite: **506 passed, 0 failed**. [Tests](part_2/tests_2.log).
[Entrance](part_2/boss_entrance.png), [boss and onryo](part_2/boss_battle.png).
The full onryo image and exact prompt are recorded in the asset licence ledger.

## 3. Briefing cards and settings tabs

Interactive battles pause before wave 1 for one painted portrait/name/counter
card per enemy type, including the boss. Any key, mouse click, touch or gamepad
button dismisses the panel; dismissal input is consumed before combat resumes.
Pause has an Enemy briefing button, returning to Pause on dismissal. Headless
simulators and staged render/perf fixtures intentionally opt out of the modal.

NEW is based on persisted `seen_enemies`, recorded before combat so a loss does
not repeat the tag. Old saves infer known foes from cleared stages. The save
version remains compatible and all existing progression data is preserved.

Settings uses adjacent connected tab plates, matching selected/content colour,
an open bottom border, clear underline and a section heading. Setting buttons
retain their separate style, targets and behavior; reset confirmation remains.

Full suite: **509 passed, 0 failed**. [Tests](part_3/tests_3.log).
[Briefing](part_3/enemy_briefing.png), [Audio](part_3/settings_audio.png),
[Display](part_3/settings_display.png), [Gameplay](part_3/settings_gameplay.png).
