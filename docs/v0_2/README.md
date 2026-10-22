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
