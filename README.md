# Shogun's Last Stand

A 2D side-scrolling samurai defense game made in Godot 4. You play a samurai holding a village gate against waves of undead and supernatural enemies. You fight with a katana, summon allies with Spirit Energy, and spend your rewards on upgrades between battles.

- Engine: **Godot 4.7.2** (Compatibility renderer)
- Language: typed GDScript
- Target: iPhone 16 / iOS 26, landscape, 1920×1080 base resolution. Developed and tested on Windows.

## Project status

**MVP complete (phases 1–6).** The full spec is in [docs/MASTER_PROMPT.md](docs/MASTER_PROMPT.md).

| Area | State |
|---|---|
| Combat | Samurai with a 3-hit combo, heavy attack, dash (i-frames, 3 s cooldown) and Spirit Slash. Hollow Soldier and Oni Brute enemies with a state machine. |
| Defense | Village gate (1000 HP). Ashigaru and Yumi Archer summons using Spirit Energy (max 150, +5/s). Stage 1 has 3 data-driven waves. |
| Loop | Victory/defeat screens, gold and XP rewards, 6 upgrades with 5 levels each, a versioned JSON save with backup and recovery, and a reset option. |
| Mobile | Multitouch joystick and buttons, safe-area layout, 44 pt touch targets, a pause menu, saved settings, and left-handed mode. |
| Quality | 92 headless tests, a manual [smoke test](docs/SMOKE_TEST.md), and a stress-tested frame budget. |

**Known limitations**
- **Art:** placeholder geometric art only.
- **Audio:** none yet. The volume settings drive the audio buses, but there are no sounds to hear.
- **iOS:** never built or run on a device ([guide](docs/IOS_EXPORT.md), untested).
- **Balance:** not tuned.

## How to run

**Editor:** open Godot 4.7.2, choose **Import**, select `project.godot`, then press **F5**.

**Command line** (on this machine the Godot binary is `godot_console`):

```bash
godot_console --path .
```

**Headless checks:**

```bash
godot_console --headless --import
```

```bash
godot_console --headless --path . -s res://tests/run_tests.gd
```

The test runner exits with code 1 on any failure, or if a test logs an engine or script error.

## Controls

### Keyboard

| Action | Keys |
|---|---|
| Move | A / D or ← / → |
| Attack (3-hit combo) | J |
| Heavy attack | K |
| Dash | L |
| Spirit Slash | U |
| Summon Ashigaru (30 SE) / Yumi Archer (45 SE) | 1 / 2 |
| Pause / back | Esc (or the **II** button) |
| Debug spawns (editor/debug builds only) | F1 Hollow Soldier, F2 Oni Brute |

### Touch

| Control | Where |
|---|---|
| Joystick (move) | bottom-left (bottom-right when left-handed) |
| Attack, Heavy, Dash, Spirit Slash | bottom-right (bottom-left when left-handed) |
| Summon Ashigaru / Archer (cost and cooldown shown) | bottom-center |
| Pause | top-right |

Touch controls appear automatically on phones and tablets. On a Windows touchscreen they appear after your first touch. To test them with a mouse, use **Settings → Touch controls → Always**.

## Project layout

```
scenes/   main menu, battlefield, player, enemies, allies, gate, UI (HUD, touch, pause, settings, results), upgrade menu
scripts/  components (health, hitbox, hurtbox, ...), systems (waves, summons, saves, settings, ...), resources, ui
data/     .tres data: enemies, allies, stages/waves, upgrades, player stats
tests/    headless test runner + unit tests
docs/     design, architecture, smoke test, iOS export guide
```

## Docs

- [Game design](docs/GDD.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Smoke test checklist (15 min)](docs/SMOKE_TEST.md)
- [iOS export guide (untested)](docs/IOS_EXPORT.md)
