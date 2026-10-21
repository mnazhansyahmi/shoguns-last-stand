# Playtest game-feel refinement

Completed on `main`, 2026-10-22 (Asia/Kuala_Lumpur). This is the requested playtest
correction phase; no campaign content or combat stats were changed.

## Changes and local commits

1. `01a7933` — **Grounded gait and stronger samurai proportions**. Longer light-character strides and smoother lift/contact replace rapid short stepping. Both feet contribute to continuous pelvis placement instead of hard support-foot switches. Run-to-idle waits for the swing to settle. The samurai has more torso, hakama, calf and forearm volume, with unchanged head and bone lengths. Heavy and limping gait distinctions remain.
2. `6176325` — **Restore figure skill icons**. Restores the compact 66-unit cached figure pictures requested in screenshot 3, reusing the same art as the skill shop. Cooldown sweeps, glow, key badges and locks remain.
3. `125ded7` — **Battle results celebration**. A crest, prominent reward totals, themed XP progress and crimson primary actions replace the bordered text panel. Reward breakdowns, replay reduction, ally unlocks, level-ups and save warnings remain. Reduced motion skips the burst and XP reveal.
4. **Blend title character into dusk scene**. The same coherent painting receives dusk ambient/warm rim lighting and stronger free-edge wind, with pinned face/body/soles. An original painted rock and small contact shadows replace the geometric outcrop. Final result review also clears the battle HUD and reserves room between the Next label and its focus arrow; these corrections are included with the final commit.

The generated rock is [title_rock.png](../../assets/art/samurai/title_rock.png), made
with OpenAI's built-in `image_gen`. Its exact prompt, date and reference are in
[title_rock_prompt.json](../../assets/art/samurai/title_rock_prompt.json) and
[ASSET_LICENSES.md](../ASSET_LICENSES.md). Existing character image pixels were not
repainted in this pass; their presentation registration, lighting and gait changed.

## Actual validation

| Check | Result | Evidence |
| --- | --- | --- |
| Full suite after gait/proportions | 448/448 | [log](logs/part_1_tests.log) |
| Full suite after icon restoration | 448/448 | [log](logs/part_2_tests.log) |
| Full suite after results | 449/449 | [log](logs/part_3_tests.log) |
| Full suite after menu integration | 449/449 | [log](logs/part_4_tests.log) |
| Final suite after reviewed spacing/HUD corrections | 449/449 | [log](logs/final_tests.log) |
| Import/parse and verbose boot/shutdown | Clean | [import](logs/part_4_import.log), [boot](logs/final_boot.log) |
| Production raster prompt metadata | 21 rasters, 0 missing | `assets/art/samurai` and `assets/art/roster` |

The suite retains the fixed-length, forward-knee, idle-bend, planted-foot/ground
and hand-over-hilt tests. Added coverage checks full-speed cadence, per-frame pelvis
continuity and settled idle, restored figure-picture sharing/state layers, exact
earned totals, XP progress, replay disclosure, reduced motion, save errors and
clearance for the next-stage name beside its arrow.

### Performance

One 900-frame real-renderer probe per version, fixed simulation at 60 Hz, 30 enemies
and 6 allies, on the same machine. This is a sample, not a stable speedup claim.

| Wall frame time | Before | After |
| --- | --- | --- |
| Average | 8.93 ms | 8.60 ms |
| p95 | 11.19 ms | 12.09 ms |
| Maximum | 21.61 ms | 26.41 ms |

**The original strict 8 ms average gate remains unmet in both probes.**
See [before](logs/perf_before.log) and [after](logs/perf_after.log). The probe exits
with status 1 for that budget failure; no engine/script error is reported.

Commands used:

```powershell
godot_console --headless --import
godot_console --headless --path . -s res://tests/run_tests.gd
godot_console --headless --verbose --quit
godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd -- --frames=900
godot_console --fixed-fps 60 --path . -s res://tools/capture_screenshots.gd -- --only=results --size=1280x720 --out=res://builds/game_feel/results
godot_console --fixed-fps 60 --path . -s res://tools/capture_screenshots.gd -- --only=results --size=2341x1080 --out=res://builds/game_feel/phone_results
```

The same capture tool also ran its `mainmenu`, `hud`, `samurai` and `crowd` modes.
`tools/record_motion.gd` recorded the `samurai`, `battle` and `menu` modes. Frames
were encoded with `tools/encode_motion.py`, without generating or repainting frames.

## Renderer evidence

- [Main menu](main_menu.png) and [six-second menu playback](menu.webp) (recorded before the sole-contact follow-up below).
- [Restored figure HUD](hud.png).
- [Victory replay](victory.png), [first clear with ally unlock/Next](victory_first_clear.png), [defeat with save error](defeat_save_error.png), [wide phone results](phone_results.png).
- [Samurai detail](samurai_detail.png), [motion sheet](samurai_motion_sheet.png), [run/stop strip](gait_strip.png), [crowded battle](crowded_battle.png).
- Matched ten-second diagnostic sequence: [before](before.webp) / [after](after.webp).
- [Ten-second actual gameplay sequence](gameplay.webp), including movement at game speed, reversal, stopping and attacks.

The matched close-up diagnostic uses a 360 px display figure moved at 130 px/s; it
shows a slow walk at that magnification, not the player's normal run speed. The
gameplay clip exercises real player movement through the input actions. Each clip
contains consecutive native renderer frames at 15 fps with fixed 60 Hz simulation.
Stills and selected frames support appearance/pose review; continuous smoothness
remains for the user to judge in playback.

Result and crowd captures use staged fixtures, not balance simulations. Result
numbers exercise presentation and do not claim a newly completed campaign run.
The crowd's manually populated wave counter is not a balance result.

The fresh finish review found one material issue (Next label/arrow spacing), then
confirmed its correction on desktop and phone with no visible regression. That
clearance covers the scored fix. No further world/style redesign was performed.

## Sole-contact follow-up — 2026-10-22

Closed the remaining small title-foot gap by lowering the painting four design
pixels. Both contact shadows now derive from measured sole pixels in the source
painting instead of estimated screen offsets. The title test samples the rock's
actual alpha under each sole and fails if a foot is over transparent sky.
All 449 tests pass again: [log](logs/sole_contact_tests.log). The linked main-menu
image is refreshed after this correction; the earlier menu clip remains historical.

`tools/make_region_1.py` was never run. Commits are local; stopped after this phase.
