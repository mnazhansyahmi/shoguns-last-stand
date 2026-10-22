# Combat and world polish — v0.2 — 2026-10-23

Local work only. Existing project.godot ordering preserved. No uploads or region
generator execution. Evidence uses isolated fixture saves.

## Part 1 — Region 2 readability

The native painted layers now receive region-only desaturation, compressed
contrast, darker smoke haze and light mip softness. Ground and foreground
texture are calmer. Units keep their full color/detail. Region 1 is unchanged.
Fewer fires attach to measured opaque roof/beam pixels; tight alpha bounds
remove empty base margins. Retained batches add root-pinned flame growth,
warm wall/smoke light, localized heat shimmer, rising sparks and wind-drifted
smoke. Gameplay fire pillars remain bright and readable as hazards.

| 30-enemy Region 2 run | Before mean / p95 | Readability mean / p95 |
| --- | ---: | ---: |
| 1 | 9.44 / 12.37 ms | 8.57 / 10.71 ms |
| 2 | 9.18 / 11.91 ms | 8.74 / 11.20 ms |
| 3 | 8.91 / 10.98 ms | 8.42 / 10.42 ms |
| Mean of runs | 9.18 / 11.75 ms | **8.58 / 10.78 ms** |

All three means meet ≤9.5 ms. Same fixed-60-Hz probe, 120 warm-up / 900 measured
frames, default 1280×720 window and 1920×1080 logical canvas, RTX 5060 Laptop.
Raw logs are alongside this report. No new raster asset was needed for this
part; source paintings and alpha are preserved.

Import/boot and rendered shader compilation passed. **515/515 tests passed**,
including an image-alpha check that every selected roof fire has opaque painted
timber under its root, and checks that grading never affects Region 1.

[Region 1 color](part1/region1_crowd_a.png) /
[grayscale](part1/region1_crowd_a_grayscale.png) ·
[Region 2 color](part1/region2_crowd_a.png) /
[grayscale](part1/region2_crowd_a_grayscale.png).

## Part 2 — Grips and proportions

Measured shaft/hilt registration replaces stretched bounding-box fitting on
eleven painted weapons. Uniform scaling preserves the club, spear and odachi
shapes. Both arms solve to the same rigid weapon; bows retain their tested
middle grip and drawn nock. Staff casters and shield users retain their free
casting/shield hand. Hatamoto's head is 26×30 figure units, down from 32×36.
Ground clearance includes both painted alpha and the procedural rig envelope.

**516/516 tests passed**, including new opaque-hilt/uniform-scale and full
transition reach tests. Import, boot and all thirteen rendered sheets are clean.
[All wielders, eight poses each](part2/) · [Before sheets](grips_before/).
No new raster assets were generated for this part.

## Part 3 — Boss polish

Both bosses have longer, wider armoured legs and feet, a shorter/narrower torso,
longer reachable arms and a broader planted stance. Odachi poses retain two
registered fists. Slower spring preparation, a faster weighted strike and damped
recovery replace abrupt snaps. Ground-contact signals drive short dust puffs,
quiet heavy steps and a small camera response; stationary bosses emit none.
The General carries four bounded painted fire patches across shoulders/blade.
Both bosses receive a title entrance, shake, a low musical cue using the existing
Ultimate-ready chord and the boss track. No new audio source or raster was added.

**517/517 tests passed**; import and boot passed. Six seconds of real boss AI,
captured every six fixed-60-Hz frames, are encoded at 10 fps for review:
[Daimyo motion](part3/fallen_daimyo_motion.webp) ·
[General motion](part3/burning_general_motion.webp).
Full-resolution entrance/motion/recovery stills are in [part3](part3/).

## Part 4 — Boss bars and Ultimate

The generated iron/gold frame has a live dark-crimson/ember fill, boss title and
name plate, phase marks, a 0.22-second damage hold followed by ghost drain,
phase glow/shake, and low-health cracks. Layout clears the actual player and
wave clusters at every supported UI scale. Shake respects the setting and
reduced motion. [Frame asset](../../assets/art/boss_bar_frame.png) was generated
with OpenAI built-in imagegen; the exact prompt/tool/date are recorded in
[ASSET_LICENSES](../ASSET_LICENSES.md).

Ultimate retains its existing damage, faction checks, screen range and meter
rules. After the 0.35-second raised-blade windup, a 0.95-second timeline dims the
fight, slows the world to 25%, freezes camera follow and moves the invulnerable
samurai through the visible lane. Up to eight tapered glowing slash marks
appear. At 0.52 seconds all validated hits commit in one batch, with flash,
shake, bounded ink blood and a short hit-stop. Normal control, camera and time
are restored on completion, interruption or battle end; disappearing targets
and freed actor references are tested. Total is about 1.3 seconds, with a short
impact hold inside the same effect. Blood and shake preferences still apply.

Combat text measures its real glyph/outline bounds in screen space, wraps
up/down/sideways at edges, and checks again during drift and merged-hit pops.
The cap remains six. Tests cover six long labels at each screen corner.

The final pose review also corrected the Shield Bearer's shield: its handle
stays at the back fist, turns with the falling torso and fades with the enemy.

**522/522 tests passed** after the final runtime changes. Import, boot, render
and shader logs are clean. Weapon/IK/ground checks remain green.

### Final evidence

- [Region 1 colour](final/region1_crowd_a.png) /
  [grayscale](final/region1_crowd_a_grayscale.png) /
  [100% crop](final/region1_crowd_a_100pct.png).
- [Region 2 colour](final/region2_crowd_a.png) /
  [grayscale](final/region2_crowd_a_grayscale.png) /
  [100% crop](final/region2_crowd_a_100pct.png).
- [Every wielder, eight weapon poses](final/weapon_poses/).
- [Daimyo motion with final bar](final/bosses/fallen_daimyo_motion.webp) /
  [entrance](final/bosses/fallen_daimyo_entrance.png).
- [General motion with final bar](final/bosses/burning_general_motion.webp) /
  [entrance](final/bosses/burning_general_entrance.png).
- [Boss drain/phase feedback](part4/boss_bar_ghost_phase.png) /
  [low-health cracks](part4/boss_bar_low_cracks.png).
- Ultimate timeline: [dash](part4/ultimate_t022.png),
  [suspended marks](part4/ultimate_t051.png),
  [impact flash](part4/ultimate_t054.png),
  [hits and ink](part4/ultimate_t062.png),
  [recovery](part4/ultimate_t095.png).

### Final Region 2 performance

Same 30-enemy / six-ally probe as Part 1; three independent runs. These are
average frame budgets, not maximum-frame guarantees.

| Run | Before mean / p95 | Final mean / p95 |
| --- | ---: | ---: |
| 1 | 9.44 / 12.37 ms | 8.36 / 10.18 ms |
| 2 | 9.18 / 11.91 ms | 8.61 / 10.86 ms |
| 3 | 8.91 / 10.98 ms | 8.43 / 10.38 ms |
| Mean of runs | 9.18 / 11.75 ms | **8.47 / 10.47 ms** |

**All three final averages meet ≤9.5 ms**, including the stronger bosses,
registered painted weapons, new bar and bounded floating-text layout. Raw
`final_perf_region2_*.log` files are beside this report. Perf does not trigger
Ultimate; its brief cinematic is validated separately by the timeline tests
and actual renderer captures.

The earlier verification before the last shield-pose correction also passed:
9.04, 8.93 and 8.71 ms. Run-to-run machine noise remains; the budget result is
consistent across both sets.
