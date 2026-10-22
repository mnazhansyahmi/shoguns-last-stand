# v0.2 playtest fixes

Local work on `v0.2`. No publishing or uploads. The Region 1 generator is never run.

## 1. Oni arm and archer bow

Oni shoulder caps now sample solid torso paint. His two-handed poses stay within
arm reach, with a connected shoulder and the upper arm behind the face. The same
ordering and shoulder checks cover the Daimyo and Burning General. Their death
grip also remains reachable.

Both archers now grip equal-length bow limbs at their visual centre, and their
string fingers track the exact cached draw step. A separate fist layer keeps the
string hand visible. Bow clearance includes the full centred silhouette.

- Full suite: **490 passed, 0 failed**. [Tests](part_1/tests.log).
- [Oni, Daimyo, General and both archers: eight poses](part_1/motion_after.png).
- [Import log](part_1/import.log).

## 2. Oni super armor

Light hits still deal damage but no longer knock the Oni backwards or interrupt
his attack. Only the player's Heavy, Spirit Slash and Ultimate pierce this armor;
ally heavy/spirit attacks do not. Walk speed is 52 -> 65, recovery 0.90 -> 0.55 s,
and cooldown 1.00 -> 0.65 s. The readable 0.80 s wind-up is unchanged.
No wave counts or rewards were changed: the upgraded campaign remains viable.

Continuous pose checks also caught the club rotating backwards between run and
wind-up. The carry angle now transitions forwards, and both heavy hands remain
within arm reach during blends, including the Daimyo and Burning General.

Three bot runs per stage, no upgrades, progressive ally unlocks:

| Stage | Wins before -> after | Gate % before -> after | Seconds before -> after | Deaths before -> after |
| --- | --- | --- | --- | --- |
| 1 | 3/3 -> 3/3 | 100 -> 100 | 82 -> 82 | 1.0 -> 1.0 |
| 2 | 3/3 -> 3/3 | 100 -> 100 | 111 -> 112 | 1.0 -> 1.0 |
| 3 | 3/3 -> 3/3 | 100 -> 100 | 161 -> 171 | 3.0 -> 4.0 |
| 4 | 3/3 -> 3/3 | 100 -> 100 | 259 -> 261 | 5.7 -> 7.7 |
| 5 | 2/3 -> 3/3 | 51 -> 74 | 340 -> 397 | 11.3 -> 11.7 |
| 6 | 3/3 -> 3/3 | 100 -> 100 | 298 -> 293 | 7.3 -> 8.3 |
| 7 | 3/3 -> 3/3 | 100 -> 100 | 307 -> 295 | 11.0 -> 11.3 |
| 8 | 3/3 -> 3/3 | 100 -> 100 | 338 -> 350 | 9.7 -> 10.7 |
| 9 | 3/3 -> 3/3 | 100 -> 100 | 423 -> 410 | 13.0 -> 12.3 |
| 10 | 1/3 -> 0/3 | 23 -> 0 | 485 -> 461 | 19.7 -> 19.0 |

The final stage's zero-upgrade stress result worsened. The normal purchased
campaign in Part 3 won all 20 clear/replay battles, so the final stage still
expects progression; these three stress samples do not establish human balance.

- [Before](part_2/before_all.log), [after](part_2/after_all.log).
- Armor checkpoint: **494 passed**; final transition/integration check:
  **499 passed**, including the subsequently prepared settings and cap tests.
  [Armor tests](part_2/tests.log), [integration tests](part_2/tests_final.log).
- [Final heavy/archer motion sheet](part_2/motion_after.png).

## 3. Progress-gated upgrades

Original tiers cap at level 2 with 0-1 stages cleared, 3 with 2-3, 4 with 4,
and the full original cap with 5. Existing Region 2 extensions open at stages
6 and 9. Gate Armour and Fire Resistance open one level at stages 6, 7, 8 and
10. Cards explain the next required clear. Older saves retain all purchased
levels and their effective bonuses, even above the current purchase cap.

The full catalog remains **112 levels / 26,240 gold**. The real bot economy curve
buys the cheapest available upgrade after each battle, clears every stage then
replays it once, and carries the same save forward. All **20 battles won**;
the full set finishes on the stage 10 replay with **820 gold** left (previous
ungated curve: 829). Three is the retry limit, not three complete campaigns.

| After stage replay | Levels owned | Gold left |
| --- | --- | --- |
| 1 | 8 | 30 |
| 2 | 16 | 92 |
| 3 | 25 | 43 |
| 4 | 38 | 71 |
| 5 | 56 | 30 |
| 6 | 69 | 33 |
| 7 | 81 | 56 |
| 8 | 92 | 102 |
| 9 | 102 | 183 |
| 10 | 112 | 820 |

- [Economy curve](part_3/economy.log).
- Full suite: **499 passed**, including the prepared settings changes.
  [Tests](part_3/tests_final.log).

## 4. Cleaner settings

Audio, Display and Gameplay have separate tabs. Audio holds music/SFX; Display
holds UI scale, motion, shake and blood; Gameplay holds touch, handedness,
vibration, Controls and Reset Progress. Reset still requires its confirmation.
Keyboard/gamepad focus and Controls return select the correct page. Targets
remain at least 124 logical pixels (the existing 44 pt minimum at UI scale).

Hover/focus is silent. A press plays one short click, limited to 0.10 s, reduced
from -6 to -16 dB. The old hover library event is removed.

- Full suite: **499 passed**. [Tests](part_4/tests_final.log).
- [Audio](part_4/settings_audio.png), [Display](part_4/settings_display.png),
  [Gameplay](part_4/settings_gameplay.png).

## 5. Region 2 performance

The extra cost is primarily the live cloth on the Spectral Archer, Shield
Bearer and Flying Spirit, followed by figure transforms and their dynamic
draws. The burning backdrop is already retained static art with bounded ember
counts; hiding it saved much less than disabling secondary animation. The
General's aura was also a smaller contributor. Diagnostic flags deliberately
alter the picture and are **never** used for the final measurements.

Retained changes:

- Reuse cloth integration coefficients while their inputs match, and use local
  packed-array aliases with the original in-place update semantics.
- Cache immutable tail/tatter definitions and stop refreshing procedural hems
  hidden behind painted artwork.
- Cache ribbon texture coordinates, calculate both edges with one tangent,
  and batch the two painted tails into one ordered triangle submission.
- Assign each active part's final transform once; permanently hidden old
  mane/pauldron layers keep their tool nodes without per-frame work.
- Copy poses directly instead of interpolating all fields and re-solving the
  grip arc just to copy its endpoint.

The simulation rate, cloth repaint rate, particles, artwork, fire and visible
effects are unchanged. Full cloth trajectory tests compare variable timesteps,
turns, stiffness/damping changes and caller aliases against the previous solver.
Ribbon tests compare curled/degenerate and tapered geometry with the previous
builder. The 40-pose rendered comparison has **0 changed pixels**.

- **501 tests passed**, 0 failed. [Tests](part_5/tests.log).
- [Import](part_5/import.log), [boot](part_5/boot.log),
  [pixel comparison](part_5/pixel_check.log).
- Motion sheet [before](part_5/motion_before.png),
  [after](part_5/motion_after.png): Oni, Daimyo, General and both archers.
- Staged battles: [Region 1, stage 3](part_5/region_1.png),
  [Region 2, stage 8](part_5/region_2.png). The latter deliberately includes a
  General for art review, rather than showing the normal stage 8 wave roster.

### Attribution and bounded optimization trials

Initial 600-frame diagnostic averages (ms; exploratory, not paired final results):

| Diagnostic | Average |
| --- | ---: |
| No secondary cloth simulation | 8.10 |
| No props | 10.57 |
| No General aura | 10.74 |
| No backdrop | 10.55 |
| No ember leaves | 11.38 |
| No fire layer | 11.18 |
| Frozen figures | 5.43 |
| Hidden figures | 8.08 |

The preliminary full runs were 10.95 / 10.81 / 10.85 ms. These diagnostics
overlapped headless balance work and include machine noise; the small differences
between backdrop/prop variants are not reliable savings estimates. The large
cloth/frozen-figure deltas guided the isolated CPU probe. In sequential CPU-only
pose probes, Spectral Archer changed 0.049 -> 0.039 ms, Shield Bearer
0.049 -> 0.038 ms, Flying Spirit 0.058 -> 0.043 ms. These exclude rendering
and are not interchangeable with frame times.

| Cumulative trial | Hypothesis | Single full-probe average (ms) |
| --- | --- | ---: |
| 1 | Cloth coefficients/definitions; skip invisible hem work | 10.99 |
| 2 | Shared ribbon UVs and edge calculations | 10.77 |
| 3 | One final active-part transform | 11.13 |
| 4 | Direct pose copy | 10.88 |
| 5 | Batch each pair of tails | 10.84 |

Individual trials do not establish a gain beyond machine noise. The final
comparison below uses three alternating baseline/optimized pairs with no
headless tests or simulators running. The frozen baseline is a plain local
project snapshot made after Parts 1-4; both sides use the same probe script,
fresh probe-only saves/settings, fixed 60 Hz simulation, uncapped rendering,
120 warmup + 900 measured frames, exactly 30 enemies, and up to six allies.
Godot 4.7.2 Compatibility / NVIDIA RTX 5060 Laptop GPU, driver 617.42.

Reproduce the final current-build probe:

```text
godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd -- --region2
```

Region 2's requested average gate is **8.5 ms**; Region 1 retains its 8 ms gate.
These are local editor/debug runs, not release-build performance claims.

### Final paired Region 2 results

| Pair | Before average | After average | Before p95 | After p95 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 11.42 ms | 10.45 ms | 14.11 ms | 13.29 ms |
| 2 | 11.63 ms | 10.86 ms | 14.48 ms | 13.34 ms |
| 3 | 11.73 ms | 10.95 ms | 14.85 ms | 13.82 ms |
| Mean | **11.59 ms** | **10.75 ms** | **14.48 ms** | **13.48 ms** |

The paired average improves by **0.84 ms / 7.2%**. Worst frame across these
runs: 30.68 -> 26.77 ms. Render CPU averages 2.89 -> 2.71 ms; GPU averages
0.82 -> 0.78 ms. **The 8.5 ms target remains unmet: 0/3 optimized runs pass.**
Further work needs a larger animation/rendering change; five safe optimization
trials were checked without reducing visual quality or hiding effects.

Raw paired logs: before [1](part_5/final_before_1.log),
[2](part_5/final_before_2.log), [3](part_5/final_before_3.log);
after [1](part_5/final_after_1.log), [2](part_5/final_after_2.log),
[3](part_5/final_after_3.log).

The one-pair Region 1 check measured **7.94 -> 7.89 ms average**, p95
10.53 -> 10.40 ms. Both pass its 8 ms average gate; this single pair does not
establish a meaningful Region 1 speedup. [Before](part_5/final_region_1_before.log),
[after](part_5/final_region_1_after.log).

All work remains local on `v0.2`; released `main` remains `cc72a35`.
Nothing was published or uploaded, and `tools/make_region_1.py` was never run.
Stopped after the five requested commits. Outstanding: Region 2's 8.5 ms
performance target and the harder stage 10 zero-upgrade stress result.
