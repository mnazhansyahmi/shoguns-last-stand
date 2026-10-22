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
