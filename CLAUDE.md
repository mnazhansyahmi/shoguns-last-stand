# CLAUDE.md

Guidance for Claude Code working in this repo.

## Project

Godot 4.7.2 game, typed GDScript. The full spec is `docs/MASTER_PROMPT.md`. Work one phase at a time, and stop after each phase for user confirmation.

## Commands

- Godot CLI on this machine: `godot_console`
- Import / parse check: `godot_console --headless --import`
- Boot check: `godot_console --headless --quit`
- Tests: `godot_console --headless --path . -s res://tests/run_tests.gd` (add new test files to `TEST_SCRIPTS` in `tests/run_tests.gd`)

## Conventions

- Use static typing everywhere practical (`var x: int`, `func f() -> void`).
- Files and folders are `snake_case`; `class_name` is `PascalCase`.
- A scene's own script sits next to it (`scenes/<area>/<name>.gd`). Reusable code goes in `scripts/` (`components/`, `systems/`, `resources/`, `ui/`).
- Data assets (`.tres`) live in `data/`, and art and audio live in `assets/`.
- Systems talk through signals; avoid hardcoded cross-scene node paths.
- Avoid autoload singletons unless a later phase justifies one (document it in `docs/ARCHITECTURE.md`).
- Visuals are placeholder geometric shapes (Polygon2D/ColorRect). No third-party assets.
- Text files use LF line endings (enforced by `.gitattributes`).
- Commit `*.uid` files; ignore `.godot/`.
- Stored node references (targets, projectile sources) can be freed at any time. Check `is_instance_valid(member)` on the member itself before using it or passing it on: passing a freed object into a typed parameter is a script error. Clear the reference when it's invalid.
- Battlefield, upgrade menu and main menu expose `save_path` (and battlefield/main menu also expose `settings_path`). Automated runs must point them at test files under `user://` so they never touch the player's real save or settings.
- Godot 4.7 has built-in classes with common names (e.g. `VirtualJoystick`). A `class_name` that collides is a parse error, so check before naming a class.
- Touch input: widgets call `Input.action_press/release` on the existing Input Map actions. Gameplay reads input state only. Events injected with `Input.parse_input_event` use window pixels, not canvas units.
- Never report test or validation results that weren't actually run. The test runner fails any test that logs an engine or script error.
