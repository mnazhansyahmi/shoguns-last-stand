# v0.2 development review

Branch: `v0.2`, created from released `main`. Nothing uploaded or published.
The Region 1 generator was never run.

## Part 1 — Merge Region 2

Merged `origin/region-2-n54198` with both parents preserved. The merge applied
without text conflicts. Existing painted roster, menu illustration, HUD portrait
and export preparation stayed unchanged. Campaign routing now spans stages 1–10.
The pause-menu early-exit fix is kept once, with its last-wave regression test.

- Import: passed. [Log](part_1/import.log).
- Headless boot: passed. [Log](part_1/boot.log).
- Full suite: **477 passed, 0 failed**. [Log](part_1/tests.log).
- [Bamboo stage select](part_1/stages_open.png), [Burning Village stage select](part_1/stages_village.png).
- [Region 1 battle](part_1/region_1_crowd_a.png), [Region 2 battle](part_1/region_2_crowd_a.png).
  Battles are staged captures using isolated save files. Region 2 includes its
  four enemy types; their temporary art is replaced in Part 2.

## Part 2 — Painted enemies

Four original transparent atlases replace the tinted stand-ins: Spectral Archer,
Shield Bearer, Flying Spirit and Burning General. They retain the shared pose,
IK, joint patch and weapon grip contracts. The onryo has a visible funeral robe
and trailing ink instead of leg nodes. The painted wooden tate splits when broken.
Texture mipmaps match the existing painted roster.

- Import and headless boot passed. Full suite: **480 passed, 0 failed**.
  [Import](part_2/import.log), [boot](part_2/boot.log), [tests](part_2/tests.log).
- [Eight poses for each enemy](part_2/poses.png).
- [Painted Region 2 battle](part_2/battle.png).
- Generated with the built-in image tool on 2026-10-22. Exact prompts and source
  references are in [asset licenses](../ASSET_LICENSES.md) and
  `assets/art/roster/region_2_provenance.json`.
- The blood cleanup test now uses a known short flight velocity rather than a
  random trajectory; this removes its unrelated intermittent early-expiry failure.

## Part 3 — Region 2 upgrades

The full catalog grows from **78 levels / 12,915 gold** to **112 levels / 26,240 gold**.
All shipped upgrade IDs, purchased levels and original tier prices are preserved.
Additional tiers and the two new upgrades unlock after clearing stage 5. Locked
cards explain that requirement; the purchase service also enforces it.

| Existing upgrade | Cap before → after | First additional tier |
| --- | --- | --- |
| Samurai HP / Damage | 5 → 7 / 5 → 7 | 350 / 400 g |
| Ashigaru HP / Damage | 5 → 7 / 5 → 7 | 300 / 300 g |
| Archer Damage | 5 → 7 | 350 g |
| Spirit Regeneration / Capacity | 5 → 7 / 4 → 6 | 400 / 275 g |
| Healer Blessing / Guardian HP | 4 → 6 / 4 → 6 | 300 / 350 g |
| Onmyoji / Hatamoto Damage | 4 → 6 / 4 → 6 | 400 / 400 g |
| Command | 3 → 4 | 500 g |
| Bow Damage / War Cry Duration | 5 → 7 / 5 → 6 | 250 / 250 g |

Further added tiers grow by 35%, rounded to 5 gold. Dash, Spirit Slash and Ultimate
retain their useful 40% reduction caps.

- **Gate Armour:** four levels, 7.5% less gate damage per level (maximum 30%).
- **Fire Resistance:** four levels, 10% less fire damage per level for the hero,
  allies and gate (maximum 40%). Only the Burning General's pillars and flame wall
  are fire; ordinary arrows and the Daimyo's curse retain their damage type.
- Both start at 225 g and grow by 35%. At maximum, a 100-damage fire hit deals
  60 to a hero/ally, or 42 to an armoured gate. Mitigation applies once per hit.
- Full suite: **487 passed, 0 failed**, including legacy-save prices, locks,
  damage stacking, summoned allies, shop cards and the stage 10 affordability budget.
  [Tests](part_3/tests.log), [defence upgrade cards](part_3/upgrades_defences.png).

Import and boot also passed: [import](part_3/import.log), [boot](part_3/boot.log).
The [final battle capture](part_3/battle.png) uses roster mipmaps and hides only
the opening briefing in the capture helper so the enemies can be reviewed.
This is a staged crowd on the stage 8 backdrop, including the General for art
review; the campaign boss encounter remains stage 10.

### Economy measurement method

Both runs use `tools/balance_sim.gd`, seed 1337, bot mode, a fresh isolated save,
one full clear plus one replay of each stage, and cheapest-first purchases after
each battle. `runs=3` is the retry limit, not three independent campaigns. The
revised purchasing policy skips tiers until their stage requirement is met.
This is a progression sample; combat deaths can vary between runs.

The affordability regression separately sums full-clear rewards and replay gold:
the full set costs more than the stages 1–9 budget and fits inside the stage 10
budget. The battle simulation verifies the budget can actually be earned.

### Economy results

Each row is after that stage's replay. All **20/20 battles were wins in both
campaign runs**. Every Region 2 battle ended with the gate at 100% in both runs.

| Stage | Before: levels / 78 | Before: gold left | After: levels / 112 | After: gold left |
| --- | ---: | ---: | ---: | ---: |
| 5 | 56 | 39 | 56 | 39 |
| 6 | 68 | 222 | 69 | 42 |
| 7 | 78 | 510 | 81 | 65 |
| 8 | 78 | 4,296 | 92 | 171 |
| 9 | 78 | 8,322 | 102 | 192 |
| 10 | 78 | 14,154 | 112 | 829 |

The old set completes on stage 7's replay. The new set completes on stage 10's
replay; its first clear has 109/112 levels and 535 gold. No stage rewards or enemy
stats were changed for this economy pass.

Logs: [before](part_3/economy_before.log), [after](part_3/economy_after.log).

Reproduce:

```text
godot_console --headless --path . --fixed-fps 60 -s res://tools/balance_sim.gd -- curve runs=3 tag=v02_after
```

### Final performance measurement

Three sequential runs per mode, after the economy simulator exited. Each uses
120 warmup frames followed by 900 measured frames, fixed 60 Hz simulation,
uncapped rendering, exactly 30 living enemies and six allies. Each sample starts
with fresh probe-only save/settings files. Godot 4.7.2 Compatibility renderer;
NVIDIA GeForce RTX 5060 Laptop GPU, driver 617.42.

| Crowd | Run averages (ms) | Mean average | Mean run p95 | Worst frame | Runs below 8 ms average |
| --- | --- | ---: | ---: | ---: | ---: |
| Standard: Hollow Soldiers / Oni | 7.52 / 7.40 / 7.70 | 7.54 ms | 9.63 ms | 27.65 ms | 3/3 |
| Region 2: all four new types | 10.89 / 10.86 / 10.85 | 10.87 ms | 13.40 ms | 29.11 ms | 0/3 |

**Remaining issue: the Region 2 crowd does not meet the 8 ms average target.**
The standard test passes its average gate; neither mode keeps every frame below
8 ms. These are local debug measurements, not a release-build performance claim.
The Region 2 probe uses the Burning Village backdrop and a synthetic mix of
Spectral Archers, Shield Bearers, Flying Spirits and a General, replenished to 30.

Logs: standard [1](part_3/perf_standard_1.log), [2](part_3/perf_standard_2.log),
[3](part_3/perf_standard_3.log); Region 2 [1](part_3/perf_region2_1.log),
[2](part_3/perf_region2_2.log), [3](part_3/perf_region2_3.log).

```text
godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd
godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd -- --region2
```

All three requested parts are complete locally on `v0.2`. The released `main`
remains at `cc72a35`. Nothing was published or uploaded to itch.io. The Region 1
generator was never run. Work stopped after the third commit and report.
