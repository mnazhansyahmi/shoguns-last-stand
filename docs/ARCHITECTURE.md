# Architecture

## Folder layout

```
assets/          art and audio (placeholders for now)
  sprites/characters, backgrounds, effects, ui, audio/{music,sfx}, animations
scenes/          .tscn scenes plus the scene's own script beside it
  main_menu/, battlefield/, player/, enemies/, allies/, gate/, ui/
scripts/         reusable code that isn't tied to one scene
  components/    health, hitbox, hurtbox, cooldown (Phase 2+)
  systems/       wave director, summon manager, save manager (Phase 2+)
  resources/     custom Resource classes for data (EnemyData, AllyData...)
  ui/            shared UI widgets
data/            .tres data instances: enemies/, allies/, stages/, upgrades/
tests/           headless tests (Phase 6)
docs/            design and architecture notes
```

## Decisions

- **Compatibility renderer.** This is the safest choice for iOS and older GPUs, and it's enough for a 2D game.
- **1920×1080 base, `canvas_items` stretch, `expand` aspect.** The UI scales cleanly, and wider or taller screens (like the iPhone 16) show extra space instead of black bars. The desktop window opens at 1280×720 for convenience.
- **Mouse emulates touch** (`emulate_touch_from_mouse`) so touch controls can be tested on Windows.
- **No autoloads in Phase 1.** Scene changes use `get_tree().change_scene_to_file()`.
- **Named physics layers** are reserved now: world, player, allies, enemies, gate, projectiles.
- **Placeholder visuals** are built from Polygon2D/ColorRect nodes, so real art can replace them later without touching game logic.

## Scene flow

```
main_menu.tscn --Start--> battlefield.tscn --Esc (temporary)--> main_menu.tscn
             \--Quit--> exit
```

In Phase 1, Esc on the battlefield returns to the menu. A real pause menu replaces this later.

## Battlefield coordinates (world space, 1920×1080)

- Ground top surface: y = 880
- Gate: x = 180 (left edge)
- Enemy spawn point: x = 1800 (right edge)
