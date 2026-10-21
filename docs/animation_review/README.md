# Character motion refinement — 2026-10-21

The menu samurai now breathes, with independent wind weights for hair and loose
robe edges on a shared UV mesh. Both soles have zero motion weight. The original
alpha artwork and menu composition are retained; this is deformation of the
approved portrait, not a replacement illustration or a whole-image bob.

The gameplay head uses a shorter neck crop and lower placement. A head-anchored
world-space ponytail chain bends through turns and stops, with interpolated
ribbon geometry. Painted sleeves and sash retain cloth follow-through. Frozen
HUD/skill portrait bakers seed hair and cloth on their first frame.

All six allies have live cloth anchors and different responses:

| Ally | Motion |
| --- | --- |
| Ashigaru | Brisk gold hat cords and existing light breathing/hem |
| Yumi Archer | Light teal headband ribbons and cloak |
| Shrine Healer | Soft jade ribbons, sleeves and hair sway |
| Spear Guardian | Short, restrained azure waist cords and tabard |
| Onmyoji | Flowing magenta hat ribbons and loose sleeves |
| Hatamoto | Weighted pole sway with the flag attached, orange waist tails |

Body poses, feet and chain simulation retain their full update rate; cosmetic
ally cloth repaint is capped at 30 Hz. Samurai hair and cloth repaint remain at
the full rate. Ribbon triangle indices are shared by chain size. Combat stats,
controls, skill timings and campaign data were not changed.

**Settings → Motion: Full / Reduced** saves the preference. Reduced mode softens
decorative displacement and removes inertial hair/tail whip while retaining
combat poses and foot animation. [Settings capture](settings_motion.png).

## Recorded clips

These are animated WebP files made from actual Godot renderer frames, not
animations generated from still pictures. Simulation runs at 60 Hz; captures
sample every fourth rendered frame, giving 15 fps at 1280x720. Open each file to
play. WebP encoding uses quality 90; source PNGs remain in the ignored build folder.

- [Menu, 6 seconds](menu.webp): breathing, hair and robe movement, planted soles.
- [Samurai, 10 seconds](samurai.webp): idle, run, reversal, stop, heavy strike,
  Bow and War Cry. Enlarged figure for inspection; weapons stay within the frame.
- [Six allies, 6 seconds](allies.webp): idle, movement, attack and settle.
- [Battlefield, 10 seconds](battle.webp): staged enemies/allies in the real battle
  scene with live movement, attacks and skills. This is not a complete playthrough;
  the stopped wave director does not count manually staged enemies in the HUD.

Source command:

```
godot_console --fixed-fps 60 --path . -s res://tools/record_motion.gd -- --mode=menu --out=<frame-directory>
python tools/encode_motion.py <frame-directory> <clip.webp>
```

Use `samurai`, `allies` or `battle` for the other modes. The encoder requires Pillow;
the bundled workspace Python was used. All runs use isolated saves/settings under
`user://motion_review`, `user://screenshots`, `user://perf` or test-save folders.

## Verification

The full suite passes **434 tests, 434 passed, 0 failed**. Added checks cover pinned
portrait weights, independently moving hair/robe regions, live cloth on all six
allies, anchored roots and idle feet, fixed hair lengths through turning and
teleport, first-frame cached portraits, and reduced-motion persistence with combat
poses intact. Existing IK, ground-clearance, planted-foot and pose tests remain.

Real-renderer recording logs are clean, with zero frame-save errors. The recorder
also fails its exit status on engine/script errors. Animated files were decoded to
verify all frames and dimensions; provenance is retained in adjacent JSON sidecars
and in the Settings PNG. The provenance scan reports 5 rasters, 0 missing.

Visual review checked ordered rendered samples through idle, run, reversal, stop,
windup, strike, bow and recovery. That and the mechanical tests support the
reported pose/anchor checks; they do not constitute human judgement of continuous
playback smoothness or an iPhone/gamepad device playtest. The final independent
review's scope and performance measurements are recorded below.

Import and verbose boot/shutdown checks both exit 0, without engine/script errors
or leak messages. Final raw logs are in [logs/](logs/).

## Crowd performance

Native Compatibility renderer, RTX 5060 Laptop GPU; exactly 30 enemies and 6
allies, 120 warm-up frames plus 900 measured frames, fixed 60 Hz simulation and
uncapped renderer. Baseline commit `c15e496` was unpacked into an ignored directory
and imported with the same current project settings and unchanged audio cache.

The three baseline measurements below precede the final three measurements.
These are separate run sets, not an interleaved final paired experiment.

| Run | Baseline average | Final average | Baseline p95 | Final p95 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 8.54 ms | 8.85 ms | 11.15 ms | 11.34 ms |
| 2 | 8.52 ms | 8.75 ms | 10.74 ms | 11.29 ms |
| 3 | 8.46 ms | 9.00 ms | 10.97 ms | 11.56 ms |
| Mean | **8.51 ms** | **8.87 ms** | **10.95 ms** | **11.40 ms** |

A single touch comparison measured **8.70 → 9.17 ms** average and **11.08 →
11.33 ms** p95. A single comparison is limited evidence. Keyboard results show
about +0.36 ms in these run sets; touch about +0.47 ms. Timing varies with the
machine, and these figures do not establish device frame pacing.

**Every final run still fails the original strict average < 8 ms gate.** This
phase does not claim to resolve that pre-existing target, or to meet the older
+0.2 ms UI allowance as a total animation-cost allowance. The motion is complete;
the strict performance target remains outstanding.

Intermediate timings before the ribbon-cache/redraw correction are retained in
the ignored build folder. They are not the final figures above.

## Scope and review

PRODUCT.md, DESIGN.md, its sidecar and the Art Bible describe the authorized
animated menu and secondary motion. Historical still-character reports remain
unchanged. No new character art, gameplay balance or campaign content was added.
The region generator was never run. Existing unrelated project settings and
unused music files are excluded from the commit.

The fresh finish reviewer scored both requested fixes **resolved**: persistence
records and accurate performance reporting. Its final disposition is **ship** at
that scope. Refreshed rendered samples showed no visible regression; neither
review pass claimed real-time human playback or a whole-surface/device pass.
