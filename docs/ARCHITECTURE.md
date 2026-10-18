# Architecture

## Folder layout

```
assets/          art and audio (placeholders for now)
  sprites/characters, backgrounds, effects, ui, audio/{music,sfx}, animations
scenes/          .tscn scenes plus the scene's own script beside it
  main_menu/, battlefield/, player/, enemies/, allies/, gate/, ui/
scripts/         reusable code that isn't tied to one scene
  components/    health, hitbox, hurtbox, cooldown, faction, placeholder visual
  systems/       enemy spawner, wave director, summon manager, spirit energy (later: save manager)
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
- **No autoloads so far.** Scene changes use `get_tree().change_scene_to_file()`, and systems find each other through groups (`player`, `allies`, `gate`, `enemies`) and signals, not node paths.
- **Physics layers:** 1 world, 2 player, 3 allies, 4 enemies, 5 gate, 6 projectiles, 7 `hurtbox_defenders`, 8 `hurtbox_enemies`. Bodies only collide with the world. Units pass through each other, and enemies queue in code instead of stacking.
- **Placeholder visuals:** `PlaceholderVisual` is the animation interface (`set_facing`, `play_state`, `flash_hit`, `set_blinking`, `set_tint`). Gameplay code only calls these methods, so sprites can replace the Polygon2D rig later.
- **Pausing:** the Battlefield root and HUD run with `PROCESS_MODE_ALWAYS`, and gameplay lives under `World` (`PAUSABLE`). Defeat pauses the tree.

## Combat (Phase 2)

Components in `scripts/components/`:

- `HealthComponent` stores HP and emits `health_changed`, `damaged`, `healed`, and `died`. `died` fires exactly once per life. It also holds invulnerability timers, which dash and hurt i-frames use.
- `HitboxComponent` is an Area2D used while an attack is active. `activate()` starts a new attack instance, and each target (keyed by its HealthComponent) can be hit at most once per instance. While active it polls `get_overlapping_areas()`, so it also catches targets that were already overlapping.
- `HurtboxComponent` is the authoritative hit check. It rejects hits that are friendly fire, hit a dead target, or land during invulnerability, then applies damage and emits `hit_received(HitData)` with knockback.
- `CooldownComponent` is a tickable timer used for dash, heavy attack, and Spirit Slash.
- `Faction` holds the two sides (DEFENDERS, ENEMIES). Hitbox masks only include the opposing side's hurtbox layer, and the code checks factions as well.

Visuals never cause damage. Damage only happens through hitbox → hurtbox validation, timed by each state machine.

Data (`scripts/resources/`, with instances in `data/`):

- `AttackProfile` defines an attack's windup, active time, recovery, cooldown, knockback, hitbox shape, and lunge.
- `PlayerStats` (`data/player/samurai_stats.tres`) holds the player's numbers and four attack profiles: 3 combo hits plus the heavy attack.
- `EnemyData` (`data/enemies/*.tres`) holds an enemy's stats, AI ranges, target priorities, attack, and placeholder look.

Actors:

- `Player` runs a time-based state machine: IDLE, RUN, ATTACK, DASH, SPIRIT_SLASH, HURT, DEAD. Pressing attack during a combo hit queues the next hit, which cancels the current hit's recovery. Dash can cancel an attack. Getting hit interrupts any action. The dash is distance-based, so it always covers exactly 135 px. After dying, the player respawns in 5 s (handled by the battlefield). Only the gate's destruction causes defeat.
- `Enemy` uses one generic scene configured by `EnemyData`. Its FSM is SPAWN → ADVANCE → ACQUIRE_TARGET → ATTACK → RECOVER, with HURT (skipped by non-interruptible enemies like the Oni) and DEAD. When choosing a target, it takes the nearest valid target of the first kind in its priority list that's within aggro range. The gate is the fallback once it's in range.
- `VillageGate` has 1000 HP, a world health bar, and emits `destroyed`.
- `EnemySpawner` spawns enemies and enforces a cap on how many are alive (40). It's used by the WaveDirector and by the F1/F2 debug keys.

## Summoning and waves (Phase 3)

- `SpiritEnergy` (in `World`) holds up to 150 energy and regenerates 5/s. It starts at 50 (my choice; the spec doesn't say). It emits `energy_changed`.
- `SummonManager` sits in front of the gate (x = 340). `request_summon(slot)` checks, in order: valid slot, unit cap (6), slot cooldown, enough energy, and a spawn position at least 50 px from any living enemy (it tries up to 5 offsets). Energy is spent only after every check passes. It returns a `Result` and emits `summon_failed(slot, result)`, which the HUD shows as a message. Each ally's slot is freed by its `defeated` or `tree_exiting` signal, whichever fires first.
- `Ally` uses one generic scene configured by `AllyData` (`data/allies/`). Its FSM is SPAWN → IDLE (holds its summon position) → ADVANCE → ATTACK → RECOVER, plus HURT and DEAD. It engages the nearest living enemy within aggro range, stops at attack range, and attacks. Archers (`is_ranged`) fire a single-hit `Arrow`. Melee allies queue behind each other. Allies persist between waves. Enemies already target the `allies` group.
- `UnitRig` builds the collision shapes and placeholder Polygon2D rig shared by enemies and allies.
- `WaveDirector` runs a `StageData` (`data/stages/stage_1.tres`), which lists `WaveData` resources (`data/stages/stage_1/wave_*.tres`). Each wave is a list of `WaveEntry` items (enemy, count, start_delay, spawn_interval). The phases are BREAK → SPAWNING → CLEARING → (next BREAK | COMPLETE).
  - **Softlock protection:** every spawned enemy is tracked by instance id and released by its `defeated` or `tree_exiting` signal, whichever fires first. Nothing is counted by polling, so an enemy freed by any path still completes the wave. If the spawner refuses a spawn because the enemy cap is reached, the enemy stays pending and is retried after 0.5 s.
  - The battlefield calls `start()` after connecting the director's signals.
- The battlefield shows a "Wave N" banner (and "Wave N cleared"), the wave and remaining-enemy count, and the next-wave countdown. VICTORY or DEFEAT pauses the tree. The F1/F2 debug spawns only work when `OS.is_debug_build()` is true.

## Tests

Run `godot_console --headless --path . -s res://tests/run_tests.gd`. It covers HealthComponent, hitbox/hurtbox rules, the cooldown timer, Spirit Energy and summon validation, and WaveDirector flow (completion on death, completion when an enemy is freed, no double counting, and the break between waves).

## Scene flow

```
main_menu.tscn --Start--> battlefield.tscn --Esc (temporary)--> main_menu.tscn
             \--Quit--> exit
```

For now, Esc on the battlefield returns to the menu. A real pause menu replaces this later.

## Battlefield coordinates (world space, 1920×1080)

- Ground top surface: y = 880
- Gate: x = 180 (left edge)
- Enemy spawn point: x = 1800 (right edge)
