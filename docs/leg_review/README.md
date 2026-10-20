# Leg animation review — 21 October 2026

**Latest follow-up:** 372 tests pass; import, headless/windowed shutdown and audio ownership
checks are clean. Three paired runs improved mean frame time from 9.14 to 8.08 ms and mean
run p95 from 12.07 to 10.46 ms. Only one final run passed the unchanged 8 ms gate, so sustained
performance below 8 ms remains outstanding. See the follow-up sections below for the full results.

All ten character kinds share `LegIK` and the distance-driven `LegGait`. Ink geometry,
costumes, colours, rim light and gameplay hitboxes remain procedural.

## Behaviour

- Thighs and shins retain their authored lengths. The forward knee solution is chosen
  before facing is mirrored. A short target raises the pelvis; a distant target lowers
  it into straight-leg reach. Maximum flexion is 115 degrees, including attack spring overshoot.
- Separate feet remain flat during support. World-space contact anchors compensate for
  actor translation, torso bob and pose offsets. Swing feet follow an arc and approach heel first.
- Travel distance determines cadence; speed determines stride extent, lift and run lean.
  Walking has overlapping support, running has brief flight. The pelvis lowers after contact,
  passes over support and rises before the next contact, with small torso counter-rotation.
- Human idle knees stay nearly straight, with a small weight shift. Only the upper body
  squashes during spawn, so the visible leg lengths stay fixed.
- Oni and Daimyo keep longer support and slower stomping strides; Hollow uses asymmetric
  support timing and a shorter, lower trailing step. Samurai and allies use the light gait.
- Weapon ground queries use cached convex hulls. Arm solutions are cached while local
  grips stay unchanged; unused costume slots are skipped.

## Before / after renders

Rows: Samurai, Hatamoto, Oni Brute, Hollow Soldier. Columns in the character sheet:
idle, movement, windup, strike, heavy windup, cast, hurt, dash. Walk strips sample eight
equally spaced points in a complete cycle, after two cycles of settling. Cloth/breath clocks
are deterministic. The baseline is the original commit before `Two-bone leg IK`.

| Evidence | Before | After |
| --- | --- | --- |
| Character sheet | [before_characters.png](before_characters.png) | [after_characters.png](after_characters.png) |
| Eight-frame walk strip | [before_walk.png](before_walk.png) | [after_walk.png](after_walk.png) |

Reproduce final renders with a real renderer:

```powershell
godot_console --path . -s res://tools/capture_legs.gd -- --tag=after
```

These PNGs are review evidence, excluded from Godot import/export by `.gdignore`.

## Leg implementation validation (historical)

| Check | Result |
| --- | --- |
| Part 1 full suite | 362 passed, 0 failed |
| Part 2 full suite | 362 passed, 0 failed |
| Skills / Settings full suite | 364 passed, 0 failed |
| Final full suite | 370 passed, 0 failed |
| Final headless import / parse | Passed, no script/engine errors |
| Headless boot | Booted; existing audio shutdown leak described below |
| Real-renderer captures | Four PNGs saved successfully; inspected character and walk sheets |

New tests cover solved and drawn bone lengths, all authored combo/heavy keys, transitions
through every animation state, forward knee direction, flexion limit, human idle flexion
under 15 degrees, soles above ground, planted drift at most 2 pixels in both facings at
45/120/250/0 px/s, support versus flight, heel approach and stopping. Existing silhouette
tests still require two visible legs for every kind. The suite uses isolated test saves.

### Leg implementation performance (historical; follow-up results below)

Unmodified 30-enemy workload, 120 warmup + 900 measured frames, fixed simulation at 60 FPS,
seed 1337, all visuals/effects/HUD enabled, native OpenGL Compatibility renderer on the
NVIDIA RTX 5060 Laptop GPU. The normal desktop window is 1280 × 720 with a 1920 × 1080 design canvas.

| Version | Average | p95 | Maximum | Renderer CPU | GPU |
| --- | ---: | ---: | ---: | ---: | ---: |
| Original game | 9.02 ms | 12.43 ms | 23.21 ms | 2.92 ms | 0.68 ms |
| Final code | 9.60 ms | 12.49 ms | 25.31 ms | 3.30 ms | 0.79 ms |

Both runs retained 30 enemies and finished with 6 allies. Intermediate native-driver runs
ranged from 9.23 to 9.60 ms after optimisation. The probe now explicitly reports failure and
exits nonzero when the average exceeds 8 ms; no rendering, effects or figures are disabled
to pass the budget. The follow-up improves this result, but does not yet sustain the target.

```powershell
godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd
```

### Other observations

- The seeded stage-1 bot balance smoke run won before and after: 82 seconds, gate 100%,
  one player death. Allies summoned/lost: 12/6 before, 13/7 after. This is one smoke run,
  not a statistical balance claim. `balance_sim.gd` now seeds its probes for repeatability.
- The leg implementation originally retained the pre-existing menu MP3 shutdown leak.
  The follow-up audio fix below resolves it. The full suite also had a separate orphan
  `SpiritEnergy` fixture; verbose diagnostics identified it as distinct from the MP3 leak.
- Bow Damage adds 10% per level (five levels); War Cry Duration adds 1 second per level
  (five levels). Both live under Skills, persist purchases and apply through copied
  player stats. Their prices preserve the existing region economy test.
- Reset Progress is in Settings, with the confirmation retained. The owning menu/battle
  supplies its save path. Successful reset during a battle exits to the main menu to
  prevent stale battle progress being saved again. Cancellation and save isolation are tested.
- Existing untracked audio files were preserved and excluded from all commits.
  `tools/make_region_1.py` was never run.

## Follow-up: audio ownership and shutdown

`AudioStreamPlayer.stop()` queues playback retirement on the audio mixer. The previous
helper awaited three main-loop frames, then slept, then quit before another collection
frame. Ordinary engine quits bypassed that helper entirely. AudioManager now stops players,
clears their stream references, kills/releases music and ambience tweens, lets the mixer
retire playback for 100 ms of wall time, and then awaits collection frames. Its exit-tree
fallback also drains pending playback; shutdown rejects late play requests. This changes
teardown only, not playback, crossfade timing, volume or effects during the game.

The async ownership probe checks weak references to the actual menu stream and playback,
including a crossfade with ambience, paused players, repeated stop calls, manager destruction,
and autoload shutdown. All references were released. No asset, decoder or audio driver was
replaced and no leak diagnostics were suppressed.

Observed after the audio fix:

- `godot_console --headless --import`: exit 0, no errors.
- `godot_console --headless --path . -s res://tests/run_tests.gd`: **371 passed, 0 failed**,
  with no shutdown leaks/errors. The orphan fixture is now owned by the test's cleanup list.
- `godot_console --headless --path . -s res://tools/check_audio_shutdown.gd`: all ownership
  and shutdown checks passed; no leaked resources.
- `godot_console --headless --verbose --quit`: exit 0, no leaked instances/resources.
- `godot_console --verbose --quit`: exit 0 with the real renderer, no leaked instances/resources.

Godot's [player cleanup](https://github.com/godotengine/godot/blob/master/scene/audio/audio_stream_player_internal.cpp)
and [mixer retirement](https://github.com/godotengine/godot/blob/master/servers/audio/audio_server.cpp)
were consulted during diagnosis; the ownership and exit results above were measured locally
on Godot 4.7.2, rather than inferred from those sources.

## Follow-up: measured crowd optimisation

### Actual bottlenecks and retained changes

Godot's local script profiler was run on the complete crowd with
`--debug --profiling`. The first startup snapshot was excluded. Subsequent snapshots
are sampled once per second, rather than an exhaustive trace of all 900 frames; profiling
adds overhead, so its timings are diagnostic and are **not** used for the 8 ms gate.
The [profile summary](profile_followup.json) records the sampled function costs.

| Function / work | Before | Final | Interpretation |
| --- | ---: | ---: | --- |
| `BloodStain._draw`, inclusive ms per sampled frame | 0.718 | Not observed in final snapshots | Static stains were rebuilt about 14 times per sampled frame. They now retain their drawing; setup still builds each newly spawned stain. |
| `UnitVisual.set_facing`, self ms per sampled frame | 0.149 | 0.012 | Unchanged direction no longer sets the same scale and invalidates the character transform hierarchy. |
| `InkFigure.refresh`, inclusive ms per sampled frame | 1.469 | 1.265 | Posing the complete figures remains a material CPU cost; the leg solver and animation rate are preserved. |
| Enemy physics, inclusive ms per sampled frame | 0.745 | 0.721 | Gameplay and collision avoidance are preserved. |

Inclusive timings overlap and must not be summed. Before/final profiles contain 10/8
post-startup snapshots, so these figures identify costly work rather than exact paired
frame-by-frame savings. Final native renderer CPU time remains 2.91–3.05 ms per frame;
GPU time is 0.46–0.48 ms. Together with the script profile, this identifies a predominantly
CPU-side posing/draw-submission limit, rather than GPU saturation.

BloodStain now creates one cached InkBatch containing the original blot and every spot,
using the same 64-segment circles, flattened to the same ground ellipses. Its existing
opacity function drives `self_modulate` without per-frame triangulation or command rebuilds.
The delay, fade curve, nine-second lifetime, cap, random shapes, layering and colours are
unchanged. Real-renderer comparisons against the original painter sampled two sizes, both
directions and six ages: **all 24 images were pixel-identical (maximum channel error 0)**.
The unit regression also checks the actual rendered alpha, retained geometry and lifetime.

The second retained change guards redundant facing assignments. Godot's
[Node2D setter](https://github.com/godotengine/godot/blob/master/scene/2d/node_2d.cpp)
updates the native transform even for an equal scale. The pixel comparison also verifies
the cached stain matches the native [circle geometry](https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_canvas_cull.cpp).
No gameplay, IK, stride timing, visual update rate, effect counts or renderer settings changed.

Exploratory runs informed these choices; they were not substituted for the paired runs:

| Candidate | Average / p95 | Decision |
| --- | --- | --- |
| Retain original stain commands, fade opacity; guard facing | 8.42 / 11.41 ms | Retained; removes the measured redraw/invalidation work. |
| Also batch each stain into one cached draw | 8.17 / 10.39 ms; 8.01 / 10.19 ms | Retained after exact pixel comparison and full-workload repeat. |
| Also cache costume definitions / guard backdrop transforms | 8.56 / 11.34 ms | Reverted; no demonstrated gain beyond variation. |

### Comparable repeated measurements

Three baseline/final pairs were run sequentially, alternating versions, with one Godot
process measuring at a time. Baseline is commit `504f735`: it already has the new legs
and audio cleanup, but neither performance change. The isolated baseline snapshot used
the same project settings and audio files as the working game. The performance probe is
unchanged apart from clarifying its comment about random variation.

All six runs used native OpenGL Compatibility, the RTX 5060 Laptop GPU, the configured
1280 × 720 desktop window / 1920 × 1080 design canvas, fixed simulation timesteps at
60 FPS, global seed 1337, 120 warmup frames and 900 measured frames. Every run retained
30 enemies and finished with six allies. All figures, effects, blood, backdrop and HUD
were enabled; no diagnostic feature-disabling flags were supplied. The units and effects
still use their own randomized variation, so this is a repeated comparable workload,
not a claim of bit-identical scene state.

| Pair | Baseline average | Baseline p95 | Final average | Final p95 | Final 8 ms gate |
| --- | ---: | ---: | ---: | ---: | --- |
| 1 | 9.06 ms | 11.99 ms | 8.12 ms | 10.53 ms | FAIL |
| 2 | 9.25 ms | 12.20 ms | 8.17 ms | 10.47 ms | FAIL |
| 3 | 9.11 ms | 12.03 ms | 7.95 ms | 10.38 ms | PASS |
| Mean of run statistics | 9.14 ms | 12.07 ms | 8.08 ms | 10.46 ms | Not reliably met |

The average improved **11.6%**; mean run p95 improved **13.4%**. The p95 summary is the
mean of three run p95s, not a pooled percentile. [Per-run CSV](performance_followup.csv)
also records maximum frame time, renderer CPU/GPU times, counts and gate results.
The existing strict `< 8.0 ms` average gate was preserved: two final runs returned exit 1,
and one returned exit 0. **Sustaining an average below 8 ms remains outstanding.**

### Final validation on the committed implementation

| Check | Actually observed |
| --- | --- |
| Full suite | **372 tests passed, 0 failed**; no engine/script errors or shutdown leaks |
| Headless import / parse | Exit 0, no errors |
| Ordinary headless boot / quit, verbose | Exit 0, no leaked instances or resources |
| Ordinary real-renderer boot / quit, verbose | Exit 0, no leaked instances or resources |
| Audio ownership probe | All checks pass; stream and playback weak references released |
| Stain reference render probe | 24 comparisons, maximum channel error 0 |
| Performance probe, final three paired runs | 8.12/8.17/7.95 ms average; 10.53/10.47/10.38 ms p95 |

Reproduce the final checks:

```powershell
godot_console --headless --import
godot_console --headless --path . -s res://tests/run_tests.gd
godot_console --headless --verbose --quit
godot_console --verbose --quit
godot_console --headless --path . -s res://tools/check_audio_shutdown.gd
godot_console --path . -s res://tools/check_stain_render.gd
godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd
```

For diagnosis only, add `--debug --profiling` to the performance command. Raw logs and the
isolated baseline snapshot are retained locally under `builds/validation_followup/` and
are not exported or committed. The checked-in summaries contain only observed measurements.
Existing audio files remain untouched. `tools/make_region_1.py` was never run.
