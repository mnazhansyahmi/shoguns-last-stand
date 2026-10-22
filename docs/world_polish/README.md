# World polish — v0.2

Work on `v0.2`, 2026-10-22. No publishing or uploads. Region generator not run.

## Part 1 — sharp backgrounds

Ten separately generated textures replace the five-band atlases. Actual native
dimensions: sky, mountains and scenery 2172×724; ground and grass 1536×1024.
Tiles retain aspect ratio, mirror at shared boundaries and cover the full scroll
bounds. No offline or runtime upscaling. At 1920×1080 and 1.5 camera zoom:

| Layer | Native-to-world scale | Texels per screen pixel |
| --- | ---: | ---: |
| Sky | 1.00 | 1.000 |
| Mountains | 0.82 | 1.119 |
| Scenery | 0.65 | 1.207 |
| Ground | 0.60 | 1.111 |
| Foreground | 0.45 | 1.457 |

One continuous dirt painting replaces the stretched surface/near-ground crops.
Its upper edge feathers into the scenery. Lossless imports preserve native size,
generate mipmaps and fix alpha borders; anisotropic linear filtering is used on
world layers. Grass wind, fog, rays, leaves and depth transforms are retained.

Import and boot clean. **512/512 tests passed**, including leg/IK/hilt contracts.
Both crowded regions rendered at 1920×1080 and inspected; corrected missing
mirrored sections found in the first draft. Final images:
[Bamboo](part1/region1_crowd_a.png), [Village](part1/region2_crowd_a.png).

Current-machine baseline, three sequential 30-enemy Region 2 runs:
8.86 / 8.74 / 8.70 ms mean; p95 10.77 / 10.44 / 10.36 ms.
Mean of means **8.77 ms**. Historical probe still prints its older 8.5 ms gate;
this task's explicit Region 2 target is ≤9.5 ms.

## Part 2 — natural village fires

Fire roots use measured roof, window and fence UV anchors on the actual scenery
tiles, including mirrored copies. Each stage theme selects different sites,
scales and independent phases/speeds. Four small ground fires use ground depth.
Painted smoke rises above larger fires; additive glows warm their surroundings.
Existing drifting embers remain at their own depths. Geometry is built once:
three retained texture batches per depth, no fire particle nodes or per-frame
mesh rebuild. Off-screen quads are clipped by the renderer. Reduced motion is
passed to the fire/smoke/glow shaders only when the setting changes.

Import/boot clean; **513/513 tests passed**. New checks cover anchored mirrored
placement, deterministic stage variation, different sizes/phases, bounded site
counts, small ground fires and retained glow geometry. The old synchronized
parent-alpha test now checks that the shared pulse is absent.

| Region 2, 30 enemies | Before | Natural fires |
| --- | ---: | ---: |
| Run 1 mean / p95 | 8.86 / 10.77 ms | 8.53 / 10.37 ms |
| Run 2 mean / p95 | 8.74 / 10.44 ms | 8.90 / 11.04 ms |
| Run 3 mean / p95 | 8.70 / 10.36 ms | 8.74 / 10.64 ms |
| Mean of run means | 8.77 ms | **8.72 ms** |

All three runs meet this task's ≤9.5 ms Region 2 budget. The probe now reports
that explicit budget; Region 1 retains its existing 8 ms target.
[Village fire render](part2/region2_crowd_a.png) and
[100% crop](part2/region2_crowd_a_100pct.png).

## Part 3 — character-only menu motion

The character was extracted with image_gen; the landscape behind him was
repainted. The background and menu wash have no motion shader, camera drift or
moving cloud/leaf overlay. One alpha character mesh carries breathing, a small
weight shift, independently delayed hair/sash/hem sway, a rare slight head turn
and an occasional blade glint. Soles are pinned; the character keeps its source
aspect ratio. Reduced motion scales decorative movement to 15%.

Import/boot clean; **513/513 tests passed**. Fixed-time renderer captures:
[0 s](part3/menu_t000.png), [1 s](part3/menu_t010.png),
[2 s](part3/menu_t020.png), [4 s](part3/menu_t040.png),
[blade glint](part3/menu_t113.png), [head turn](part3/menu_t140.png),
[reduced](part3/menu_reduced_t020.png),
[inpainted background alone](part3/menu_background_only.png).

Read-only pixel check compares the frames against the source alpha transformed
to screen coordinates, allowing 20 px around moving tips/filtering. **Zero
changed background pixels** in all five comparisons. Reduced-motion pixel
difference sum is 1,300,921 versus 6,621,453 normally (~20%). Exact results in
`part3_pixel_check.json`; reproduce with `tools/check_menu_motion.py`.

The initial decorated Windows capture window was clamped to 1920×1061; the
capture tools now use borderless windows so final images are true 1920×1080.

## Part 4 — painted cards and readable units

StagePreview draws the same painted textures, native tile placement and
stage-specific roof fire layout as the battle, retaining stage-colored fog.
Its drawing transform is composed with each tile's mirror transform, so cards
remain clipped and correctly scaled. No vector land or sky previews remain.

Battle player, allies and smaller enemies are **8% larger visually**, about
178 screen pixels for a nominal 110 px body at 1.5 zoom, before hats/hair and
individual variation. The already-large Daimyo/General keep their original
size to avoid additional clipping in touch mode. The scale is applied around
the foot pivot, independently of gameplay roots and collision/hit shapes.
Existing IK uses the global transform and keeps its planted-foot frame.
Health-bar head positions account for the visual scale. Boss rage retains its
original multiplier. UI icon fixtures keep their previous size.

All painted figures now use anisotropic mip filtering; the equipment and
full-onryo imports also generate mipmaps, with no size limit or lossy resize.
Smoke's final pass uses two cross-faded upward flows for continuous rise.

Import and boot clean. **514/514 tests passed**, including all leg/IK/hand-hilt
checks. New scene-level checks compare collision/hurtbox sizes with source
data, verify anchored figure origins, facing/rage scale preservation, original
boss scale and unchanged UI fixture sizing. Desktop and touch renders clean.

| Validation | Tests passed |
| --- | ---: |
| Part 1 | 512 / 512 |
| Part 2 | 513 / 513 |
| Part 3 | 513 / 513 |
| Part 4, final | 514 / 514 |

Final 30-enemy Region 2 probe: 120 warm-up frames, 900 measured, six allies,
fixed 60 Hz simulation, vSync/frame cap off, default 1280×720 presentation
(1920×1080 logical canvas). Compatibility renderer, RTX 5060 Laptop, driver
617.42. Sequential runs, no other verification jobs running concurrently:

| Run | Mean | p95 | Max | Render CPU / GPU mean |
| --- | ---: | ---: | ---: | ---: |
| 1 | 9.41 ms | 11.81 ms | 27.45 ms | 2.49 / 0.78 ms |
| 2 | 8.86 ms | 10.91 ms | 23.29 ms | 2.35 / 0.68 ms |
| 3 | 8.65 ms | 10.46 ms | 28.68 ms | 2.31 / 0.66 ms |
| Mean of runs | **8.97 ms** | **11.06 ms** | — | — |

All three means meet **≤9.5 ms**. Versus the current-machine baseline mean
8.77 ms, the final mean is +0.21 ms. This is a mean-frame target, not a promise
that every frame is below 9.5 ms. Raw logs: `final_perf_r2_1.log` through `_3.log`.

### Final visual evidence

Crowds are staged visual fixtures, not a claim that stage 8 naturally spawns
the General. Every full final image is 1920×1080. Crops are exact source pixels,
with no resampling or extra zoom.

| View | Full image | 100% crop |
| --- | --- | --- |
| Bamboo battle | [Full](final/region1_crowd_a.png) | [Crop](final/region1_crowd_a_100pct.png) |
| Village battle | [Full](final/region2_crowd_a.png) | [Crop](final/region2_crowd_a_100pct.png) |
| Touch battle | [Full](final/touch_crowd_a.png) | [Crop](final/touch_crowd_a_100pct.png) |
| Bamboo, left bound | [Full](final/world_stage3_left.png) | [Crop](final/world_stage3_left_100pct.png) |
| Bamboo, right bound | [Full](final/world_stage3_right.png) | [Crop](final/world_stage3_right_100pct.png) |
| Village, left bound | [Full](final/world_stage8_left.png) | [Crop](final/world_stage8_left_100pct.png) |
| Village, right bound | [Full](final/world_stage8_right.png) | [Crop](final/world_stage8_right_100pct.png) |

[Bamboo stage cards](final/stages_open.png) ·
[Village stage cards](final/stages_village.png) ·
[Menu 0 s](part3/menu_t000.png) / [2 s](part3/menu_t020.png) /
[4 s](part3/menu_t040.png).

Generated asset files and exact prompts are recorded in
[`docs/ASSET_LICENSES.md`](../ASSET_LICENSES.md); replacement world layers are
under `assets/art/world/sharp/`, and the two menu layers under `assets/art/world/`.
Only local commits were made. Existing `project.godot` editor ordering changes
were preserved and excluded. The forbidden region generator was never run.
