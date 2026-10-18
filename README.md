# Shogun's Last Stand

A 2D side-scrolling samurai defense game made in Godot 4. You play a samurai holding a village gate against waves of undead and supernatural enemies.

- Engine: Godot 4.7.2 (Compatibility renderer)
- Language: typed GDScript
- Target: iPhone 16 / iOS 26, landscape 1920×1080. Developed on Windows.

## Status

Phase 2 (combat) is done. The samurai can move, chain a 3-hit combo, heavy attack, dash, and use Spirit Slash. Hollow Soldier and Oni Brute enemies are in, and the gate can be destroyed (defeat). Waves come in Phase 3; for now, use the debug keys **F1** (Hollow Soldier) and **F2** (Oni Brute). The full plan is in [docs/MASTER_PROMPT.md](docs/MASTER_PROMPT.md).

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
| Summon ally 1 / 2 | 1 / 2 |
| Pause | Esc |

## Docs

- [Game design](docs/GDD.md)
- [Architecture](docs/ARCHITECTURE.md)
