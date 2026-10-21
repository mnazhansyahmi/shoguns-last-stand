# Shogun's Last Stand

A Godot 4.7.2 side-view action and gate-defence game for players who fight as a
swordsman while summoning an allied force. The existing game supports keyboard,
touch and gamepad controls, campaign stages, skills and persistent upgrades.

The implementation specification is [docs/MASTER_PROMPT.md](docs/MASTER_PROMPT.md).
This record describes the existing product; it does not authorize new features.

## Approved character refinement — 2026-10-21

The user selected the slim, fast ink swordsman concept and confirmed “yesss,
thats the one”. The approved concept is in `docs/slim_samurai/approved_concept.png`.
The scope replaces the samurai's appearance in the menu, battle and cached skill
art: lean unarmoured anatomy, light black robes, long ponytail, ankle wraps,
sandals and restrained red waist cloth. Combat speed, damage, skill timing,
progression and the other character kinds remain governed by the existing game.

The user-approved refined menu hierarchy and sunset ink landscape are retained.
The menu hero reuses original painted artwork; the battle hero uses painted
parts on the existing animated skeleton and planted-foot IK.

## Approved motion refinement — 2026-10-21

The user requested breathing, independently moving hair and robes in the menu,
visible secondary motion during gameplay, a shorter samurai neck, and appropriate
motion for all six allies. The menu artwork now uses a pinned deformable mesh;
gameplay uses anchored hair and cloth chains. Recorded motion evidence and the
scope are in `docs/animation_review/`. Reduced decorative motion is configurable
without removing combat poses. This approval supersedes the static menu choice.

Burning Village, more stages, new enemy counters and additional allies belong to
a later phase. Stop after this character refinement for user review.
