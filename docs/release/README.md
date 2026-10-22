# Windows public playtest 0.1.0

Prepared 22 October 2026. Five Bamboo Outskirts stages, six allies, saved
progression and upgrades. This release gathers feedback before new regions.

Published at **https://mnazhan.itch.io/shoguns-last-stand** under the user's
NAZHAN account. Public visibility was saved and confirmed after reloading the
itch.io editor. The uploaded Windows ZIP is marked executable for Windows;
no payments are enabled, and comments are enabled. The download button reached
itch.io's "Thanks for downloading" confirmation and its counter increased to one.
The automated browser could not return a completed downloaded file, so no
round-trip download hash is claimed; the local ZIP integrity/hash checks passed.

## Build

- ZIP: `builds/releases/ShogunsLastStand-0.1.0-windows-x64.zip`
- Size: 88,712,468 bytes (84.60 MiB).
- SHA256: `7371bc8bae86773eb37c93293253631f4a203ec3172c12f9e0500e16ce4ba0c5`
- Windows x64, Godot 4.7.2 stable, Compatibility renderer (OpenGL 3.3).
- Contents: EXE, PCK, player README, required credits, engine/dependency notices.
- Public saves: `%APPDATA%\ShogunsLastStand`, separate from editor saves.
- Binaries/templates/ZIP remain in ignored `builds/`; no binary archive is committed.

Rebuild instructions are in the root README. The selected Windows templates come
from the official Godot release over HTTPS. ZIP-member CRC checks and local SHA256
hashes were recorded; a full upstream archive signature was not checked.

## Validation actually performed

| Check | Result | Evidence |
| --- | --- | --- |
| Import and Windows release export | Clean | Local `builds/release_validation/import.log`, `export.log` |
| Full regression suite | 449 passed, 0 failed | [tests.log](validation/tests.log) |
| Packaged resource checks | 29 passed, 0 failed | [smoke.json](validation/smoke.json), [log](validation/pack_smoke.log) |
| Standalone optimized Windows EXE | Main menu and stage-one enemy spawning observed | Local `builds/release_validation/release_ui.log` |
| Campaign progression simulator | All five first clears and five replays won | [campaign.log](validation/campaign.log) |
| ZIP extraction/integrity | Five expected files, CRC passed, extracted binaries match tested copies | [package.json](validation/package.json) |

The 29 scripted packaged-resource checks use the matching **editor runtime with
the exact exported PCK**, since standard release templates disable external
`--script` overrides. These verify fresh isolated save/settings files, upgrade
purchase/reload, movement, Spirit Energy summoning, pause/resume, enemy spawning,
credits/music, victory routing and saved unlocks. Victory in this smoke check is
forced to test the route; campaign wins are checked separately by the simulator.
The optimized executable was inspected independently through its normal UI.

The simulator uses sequential persistent progression and buys inexpensive
upgrades between battles. It is a bot proxy, not human playtesting:

| Stage | First clear gate / deaths | Replay gate / deaths |
| --- | --- | --- |
| 1 | 100% / 1 | 100% / 1 |
| 2 | 100% / 1 | 100% / 0 |
| 3 | 100% / 3 | 100% / 3 |
| 4 | 100% / 5 | 100% / 5 |
| 5 | 82% / 10 | 100% / 5 |

Physical-controller testing and wider Windows hardware coverage remain pending.
Movement and balance can still improve. The earlier strict 8 ms performance
target remains unmet; this release preparation does not claim a new benchmark.
The region generator was never run.

## Store materials

- [Description](itch_page.md), [page settings](itch_settings.json), [player README](player_readme.txt).
- [Cover](media/cover.png): 630 x 500 native Godot composition of existing licensed
  game assets, made with `tools/capture_store_art.gd`; no new AI image generation.
- [Battle](media/battle.png), [menu](media/menu.png), [stages](media/stages.png),
  [upgrades](media/upgrades.png): 1280 x 720 captures rendered from the exported PCK.
  The validation helper sets up an isolated test profile; these are actual game
  views rather than painted gameplay mockups.
- Required music credit, Godot/dependency notices and AI-use disclosure included.

Use Games / Downloadable / In development / No payments / Windows. Enable
comments for feedback. Review a draft page and test its download before publishing.
Collect stage reached, combat impressions, confusing controls, difficulty spikes
and reproducible bugs. Decide the next update after feedback.

## Reference documentation

- [itch.io creator setup](https://itch.io/docs/creators/getting-started)
- [itch.io quality guidelines](https://itch.io/docs/creators/quality-guidelines)
- [Godot Windows exports](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)
- [Godot command-line reference](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- [Official 4.7.2 templates](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
