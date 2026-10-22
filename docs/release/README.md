# Windows public playtest 0.2.0

Prepared 23 October 2026 for **manual release by the owner**. No v0.2.0 file or
page update was uploaded to itch.io during this preparation. The existing
[itch.io page](https://mnazhan.itch.io/shoguns-last-stand) still needs the owner's
upload and description update. [Previous v0.1.0 release record](v0.1.0.md).

## Upload artifact

- ZIP: `builds/releases/ShogunsLastStand-0.2.0-windows-x64.zip`
- Size: **141,114,532 bytes (134.58 MiB)**.
- SHA256: `eb97b34f458295a9720742476528727c8c42cdc3c980ba5b5092c249e58227db`
- Windows x64, Godot 4.7.2, Compatibility renderer / OpenGL 3.3.
- Built with `tools/build_windows_playtest.ps1 -Version 0.2.0`, using
  `--export-release` and the Windows release template; debug export is off.
- EXE file/product versions: **0.2.0.0 / 0.2.0**. Packaged application: **0.2.0**.
- Exactly five player files: EXE, PCK, README, credits and Godot component notices.
  No source project, developer tools, tests or internal asset provenance included.
- ZIPs, templates, extracted builds and binaries remain in ignored `builds/`.

Extract the entire ZIP, then run `ShogunsLastStand.exe` with its PCK beside it.
Keep `%APPDATA%\ShogunsLastStand` when updating from v0.1; progress and owned
upgrades are retained. The smoke fixtures use their own validation save/settings.

## What's new

- Region 2 **Burning Village**, stages 6–10, opened after clearing stage 5.
- Spectral Archer, Shield Bearer, Flying Spirit and **The Burning General** boss.
- Painted parallax worlds, gates and portals, animated village fires, smoke,
  embers, and a living painted main menu with reduced-motion support.
- Higher upgrade tiers, Gate Armour and Fire Resistance, with purchase caps tied
  to campaign progress. Existing purchases above a cap remain active.
- Pre-battle enemy briefing cards, pause-menu briefing review, tabbed settings,
  Oni super armour, weapon-grip fixes, boss sword motion and a cinematic Ultimate.
- Boss bars sit below the wave counter, clear of the player HUD.

## Validation actually performed

| Check | Result | Evidence |
| --- | --- | --- |
| Import and project startup | Exit 0, no engine/script errors | [Import](validation/v0.2.0/import.log), [boot](validation/v0.2.0/boot.log) |
| Full regression suite | **525 passed, 0 failed** | [Tests](validation/v0.2.0/tests.log) |
| Optimized Windows export | Exit 0, clean | [Export](validation/v0.2.0/export.log) |
| Exact PCK extracted from ZIP | **47 passed, 0 failed** | [Report](validation/v0.2.0/smoke.json), [log](validation/v0.2.0/pack_smoke.log) |
| Extracted release EXE, headless and rendered startup/shutdown | Both exit 0; logs clean | [Headless](validation/v0.2.0/release_headless.log), [rendered](validation/v0.2.0/release_rendered.log) |
| ZIP integrity and contents | CRC passed; five expected files; all extracted hashes match export | [Package](validation/v0.2.0/package.json) |

The 47 packaged checks run the matching editor runtime with the **exact extracted
PCK**, because standard release templates disable external `--script` overrides.
They cover fresh save/settings, returning Region 1 progression, ten-stage/two-region
loading, upgrade purchase/reload/gating, movement, summoning, pause/resume,
briefing dismissal and pause review, all four Region 2 enemy spawns, music,
credits, victory routing and persisted unlocks. Victory and late-game progression
are deliberately staged to check those routes; this is not a new campaign balance
simulation or human end-to-end playthrough. The release EXE is checked separately
for normal startup, rendering and clean exit.

Captured from the extracted PCK: [menu](validation/v0.2.0/menu.png),
[Region 1 battle](validation/v0.2.0/battle.png),
[Region 2 spawn/entrance fixture](validation/v0.2.0/battle_region2.png),
[Region 1 selection](validation/v0.2.0/stages_region1.png),
[Region 2 selection](validation/v0.2.0/stages_region2.png),
[briefing](validation/v0.2.0/briefing_region2.png),
[upgrades](validation/v0.2.0/upgrades.png) and [victory](validation/v0.2.0/victory.png).

## Known limits and manual handoff

Balance, walking animation and weapon poses remain playtest work. Stage 10 expects
upgrades. Busy fights/fire effects can produce frame-time spikes. The latest
pre-release Region 2 editor probe measured 9.16 ms mean / 11.78 ms p95; this
preparation did not run a new performance benchmark or claim release-EXE timings.
The original strict 8 ms target is not consistently met. Physical-controller
testing and broad Windows hardware coverage remain pending. No browser, mobile,
macOS or Linux package is included.

Upload the ZIP above yourself, mark it Windows/executable, and use
[v0.2 page copy](itch_page.md). [Page settings](itch_settings.json) are local notes,
not applied changes. Existing `media/` store images are from v0.1; the captures
linked above show the new version. Required credits/notices and AI-use disclosure
are included. No store publication or upload was performed. The forbidden
`tools/make_region_1.py` generator was never run.
