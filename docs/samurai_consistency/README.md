# Samurai painting consistency

Completed on `main`, 2026-10-21/22 (Asia/Kuala_Lumpur).

## Changes

1. **Consistent samurai art** (`865e089`): repainted body plates match the existing face's fine ink detail. Logical part names, bone lengths, IK and hand/hilt ordering remain in use. Source regions and pivots register the new sheets without changing gameplay dimensions. Head and body generate mipmaps and share anisotropic filtering.
2. **Painted title key art** (`66d2602`): one coherent full-body painting replaces the menu limb rig. A static mesh moves only free hair, sash and hem; the sword has a glint. Face, body, grip and soles stay pinned. Reduced motion retains 15% decorative amplitude. Final review removed horizontal mirroring to preserve the anatomical right-hand sword and matched the rock ridge to the soles; that correction is included in the final HUD commit.
3. **Painted HUD portrait**: dedicated head-and-shoulders bust replaces the live portrait rig/viewport. The existing Ultimate ring, key badge, danger rim and READY plate remain.

Exact image prompts, dates and tools are in [ASSET_LICENSES.md](../ASSET_LICENSES.md), with machine-readable prompt records beside the production assets. Existing head/equipment PNGs received origin metadata only; their decoded RGBA hashes were verified unchanged.

## Actual validation

| Check | Result | Evidence |
| --- | --- | --- |
| Full suite after Part 1 | 446/446 | [log](logs/part_1_tests.log) |
| Full suite after Part 2 | 447/447 | [log](logs/part_2_tests.log) |
| Full suite after Part 3 | 447/447 | [log](logs/part_3_tests.log) |
| Full suite after final handedness correction | 447/447 | [log](logs/final_tests.log) |
| Godot import/parse checks | Passed each part | [final import](logs/import.log) |
| Verbose headless boot/shutdown | Clean | [log](logs/boot.log) |
| Generated raster prompt metadata scan | 20 rasters, 0 missing | `assets/art/samurai` and `assets/art/roster` |

The suite includes leg lengths, knee direction, ground contact, planted feet and hand-over-hilt coverage. A randomized pre-existing ally bar overlap exposed by the suite was corrected with a deterministic varied-height regression test. Test loading now fails on parser diagnostics instead of silently skipping a script.

Commands actually used:

```powershell
godot_console --headless --import
godot_console --headless --path . -s res://tests/run_tests.gd
godot_console --headless --verbose --quit
godot_console --fixed-fps 60 --path . -s res://tools/capture_screenshots.gd -- --only=mainmenu --size=1280x720 --out=res://builds/samurai_consistency/final_menu
godot_console --fixed-fps 60 --path . -s res://tools/capture_screenshots.gd -- --only=hud --size=1280x720 --out=res://builds/samurai_consistency/final_hud
godot_console --fixed-fps 60 --path . -s res://tools/capture_screenshots.gd -- --only=samurai --out=res://builds/samurai_consistency/final_samurai
godot_console --fixed-fps 60 --path . -s res://tools/capture_screenshots.gd -- --only=crowd --size=1280x720 --out=res://builds/samurai_consistency/final_crowd
godot_console --fixed-fps 60 --path . -s res://tools/record_motion.gd -- --mode=menu --out=res://builds/samurai_consistency/title_frames
```

## Renderer evidence

- [Main menu](main_menu.png)
- [HUD close-up with READY](hud_close_up.png) and [full HUD](hud_full.png)
- [Samurai motion sheet](samurai_motion_sheet.png), [walk strip](samurai_walk_strip.png) and [detail](samurai_detail.png)
- [Crowded battle](crowded_battle.png)
- [Menu animation clip](title_motion.webp): 90 actual renderer frames, 15 fps, six seconds; encoded from playback, not animated from a still.

The crowd capture is a manually populated visual probe with 12 allies and a large enemy group, including two Oni. Its wave counter is not a balance result. Stills establish sampled appearance; the clip is supplied for playback review. No new performance benchmark or hardware-independent frame-time claim is made in this art pass.

Final visual review cleared the corrected menu handedness and ground contact. `tools/make_region_1.py` was never run. Commits are local. Stopped after these three parts.
