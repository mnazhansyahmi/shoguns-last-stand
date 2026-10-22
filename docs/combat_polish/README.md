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
