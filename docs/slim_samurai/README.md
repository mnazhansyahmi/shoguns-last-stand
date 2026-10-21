# Slim samurai — 2026-10-21

Implemented the user-approved lean, fast-looking ink swordsman in the title menu,
battle figure, HUD portrait and cached skill icons. Light robes, long ponytail,
wrapped ankles and sandals replace the helmet and armour. Shared original painted
layers follow the existing skeleton; textured cloth follows the existing chains.
The title portrait is static. Combat statistics, movement speed and skill timing
were not changed. The other character kinds retain their existing artwork.

## Renders

- [Approved concept](approved_concept.png)
- [Menu, 1280x720](menu.png) and [wide menu, 2341x1061](menu_wide.png)
- [Close-up poses](detail.png), [pose sheet](pose_sheet.png), [sampled run strip](run_strip.png)
- [Battle](battle.png), [Bow draw](bow.png), [War Cry](war_cry.png)
- [Cached skill icons](skill_icons.png)

The host window caps requested 1080-high captures at 1061 pixels. The close-up and
sheet captures are 1920x1061. Skill plates hold hostile actors still to show the
actual BOW/WAR_CRY states without combat interruption; they are staged evidence.

## Validation

- `godot_console --headless --import`: exit 0.
- `godot_console --headless --verbose --quit`: exit 0; no engine/script errors or
  resource leak messages.
- `godot_console --headless --path . -s res://tests/run_tests.gd`:
  **429 tests, 429 passed, 0 failed**. Includes fixed-length IK, knee direction,
  planted feet, ground clearance, body/weapon poses and original asset/caching checks.
- Real-renderer menu, pose/run sheets, battle skills and icon captures: clean logs.
  Curling cloth uses explicit textured strip triangles, avoiding self-crossing
  polygon triangulation errors found during renderer validation.
- PNG provenance scan: **12 rasters, 0 missing** across production art and this
  review folder. Production prompts live inside both PNGs and in
  `assets/art/samurai/provenance.json`.
- A fresh Impeccable finish reviewer scored all four listed fixes **resolved**:
  persistence record, neck/collar joins, painted cloth and menu sandal contact.
  Its `ship` verdict covers those four fixes, not a complete animation review.

All automated runs use isolated save/settings paths. Static renders and sampled
frames do not substitute for a human judgement of animation smoothness.

## 30-enemy performance

Native renderer, RTX 5060 Laptop GPU, fixed simulation timestep, 30 enemies,
6 allies, 120 warm-up frames and 900 measured frames per run. Prior commit
`fb3e168` was unpacked into an isolated ignored baseline folder and given the same
current `project.godot` settings. Its unchanged imported audio cache was reused
after an initial uncached import crashed; the retry succeeded. The three final
after runs below were measured after the cloth renderer correction, with clean logs.

| Run | Before average | Final average | Before p95 | Final p95 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 8.79 ms | 8.76 ms | 10.99 ms | 11.16 ms |
| 2 | 8.90 ms | 8.49 ms | 11.50 ms | 10.66 ms |
| 3 | 8.81 ms | 8.86 ms | 11.36 ms | 11.61 ms |
| Mean | **8.83 ms** | **8.70 ms** | **11.28 ms** | **11.14 ms** |

Command: `godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd`.
The difference is small relative to variation between runs. **All three final
runs still fail the original strict average < 8 ms gate.** This character phase
does not claim to resolve that pre-existing target. Measurements are keyboard mode.

Raw final validation logs are in [logs/](logs/). Intermediate failed captures and
benchmark experiments remain in the ignored `builds/slim_samurai/` folder.

The region generator was never run. Burning Village and further gameplay phases
have not been started. Existing project settings changes and unused music imports
were excluded from this phase's commit.
