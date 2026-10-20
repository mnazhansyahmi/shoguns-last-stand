# Leg animation review — 21 October 2026

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

## Validation actually run

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

### Performance: 8 ms requirement is NOT met

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
to pass the budget. This remains an outstanding acceptance criterion.

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
