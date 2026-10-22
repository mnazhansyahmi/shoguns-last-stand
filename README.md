# Shogun's Last Stand

A side-view samurai action and gate-defence game made with Godot 4.7.2 and typed
GDScript. Fight the undead, summon allies and buy upgrades between battles.

## v0.2.0 public playtest

- Windows x64 release; the player does not need Godot.
- Ten campaign stages in Bamboo Outskirts and Burning Village, with two bosses.
- Spectral Archer, Shield Bearer and Flying Spirit; pre-battle counter-tip cards.
- Katana combo, heavy strike, dash, Spirit Slash, Bow, War Cry and Ultimate.
- Six unlockable allies, charge/hold commands, persistent upgrades and settings.
- Painted ink characters and worlds, animated village fires, music and recorded effects.
- Progress-gated upgrade tiers, Gate Armour and Fire Resistance; existing saves preserved.
- Keyboard, mouse-click summon portraits, controller mappings and optional touch UI.
- See [release validation](docs/release/README.md) for checks on the exported build.

Controller mappings are implemented; physical-controller hardware testing remains
pending. iOS, browser and other platform builds are not part of this release.
Balance, animation and performance continue to be refined through feedback.

## Play the Windows build

Extract the entire release ZIP and open `ShogunsLastStand.exe`, keeping the `.pck`
beside it. The upload artifact is generated under `builds/releases/` and is not
committed to Git. The ZIP includes controls, required credits and engine notices.

Public-build saves are under `%APPDATA%\ShogunsLastStand`. Editor/developer saves
retain their previous Godot app_userdata path. Updates should preserve public saves.

## Developer checks

```powershell
godot_console --headless --import
godot_console --headless --path . -s res://tests/run_tests.gd
godot_console --headless --quit
```

Tests fail on engine/script errors. Never claim checks that were not run.

## Build the playtest

Use Godot 4.7.2, Python 3 and PowerShell 7:

```powershell
python tools/fetch_windows_templates.py
./tools/build_windows_playtest.ps1 -Version 0.2.0
```

The downloader retrieves Windows x64 members of the official template archive
over HTTPS and verifies their ZIP CRCs; it records source and SHA-256 hashes under
`builds/export_templates/manifest.json`. Templates and generated binaries remain
outside Git. The preset excludes tests, tools, internal docs, review media and
unused music. `tools/make_region_1.py` must not be run for release preparation.

The standard release template disables `--script`/path overrides. To exercise
the exact exported PCK with automated checks, run the matching editor runtime
from the standalone build folder:

```powershell
godot_console --main-pack /absolute/path/ShogunsLastStand.pck --fixed-fps 60 -s /absolute/path/tools/release_smoke.gd -- out=/absolute/path/evidence
```

This pack check uses an isolated validation save. It is separate from opening
and inspecting the actual release `.exe`.

## Controls

Move: A/D or arrows. Attack: J. Heavy: K. Dash: L. Spirit Slash: U. Ultimate: I.
Bow: E (stage 1 clear). War Cry: Q (stage 2 clear). Charge/hold: F. Summon: 1–6
or click a portrait. Pause/back: Esc. Full keyboard/gamepad/touch help is in Settings.

## Project records

- [Release page copy and validation](docs/release/README.md)
- [Game design](docs/GDD.md) and [implementation spec](docs/MASTER_PROMPT.md)
- [Architecture](docs/ARCHITECTURE.md) and [design system](DESIGN.md)
- [Credits](docs/CREDITS.md) and [asset provenance/licences](docs/ASSET_LICENSES.md)
- [Playtest visual review](docs/game_feel/README.md)

Development used AI-assisted coding and AI-generated character/environment artwork.
