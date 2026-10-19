# Shogun's Last Stand

A 2D side-scrolling samurai defense game made in Godot 4. You play a samurai holding a village gate against waves of undead and supernatural enemies.

- Engine: Godot 4.7.2 (Compatibility renderer)
- Language: typed GDScript
- Target: iPhone 16 / iOS 26, landscape 1920×1080. Developed on Windows.

## Status

Phase 5 (mobile) is done.
- **Touch controls:** a virtual joystick and Attack/Heavy/Dash/Spirit Slash buttons, plus summon buttons that show cost and cooldown. Multitouch works, so you can move and attack at once, and the buttons press the same Input Map actions as the keyboard.
- **HUD:** a pause button, bars that show values by fill and text, and a layout that respects the safe area.
- **Pause menu:** Resume, Restart, Settings and Main Menu.
- **Saved settings:** volume, vibration, screen shake, UI scale, left-handed layout, and when to show touch controls.

On Windows, set **Settings → Touch controls → Always** and play with the mouse. Earlier phases added waves, summons, rewards, upgrades and saving. The full plan is in [docs/MASTER_PROMPT.md](docs/MASTER_PROMPT.md).

## Running

1. Open Godot 4.7.2 and import `project.godot`, then press F5. Or, from the command line:

   ```bash
   godot_console --path .
   ```

2. Headless validation:

   ```bash
   godot_console --headless --import
   ```

3. Tests:

   ```bash
   godot_console --headless --path . -s res://tests/run_tests.gd
   ```

## Controls (keyboard)

| Action | Keys |
|---|---|
| Move | A / D, ← / → |
| Attack | J |
| Heavy attack | K |
| Dash | L |
| Spirit Slash | U |
| Summon Ashigaru / Yumi Archer | 1 / 2 |
| Pause | Esc (or the II button) |

## Docs

- [Game design](docs/GDD.md)
- [Architecture](docs/ARCHITECTURE.md)
