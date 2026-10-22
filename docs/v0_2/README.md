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
