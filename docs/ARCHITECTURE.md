# Architecture

## Folder layout

```
assets/          art and audio (placeholders for now)
  sprites/characters, backgrounds, effects, ui, audio/{music,sfx}, animations
scenes/          .tscn scenes plus the scene's own script beside it
  main_menu/, battlefield/, player/, enemies/, allies/, gate/, ui/
scripts/         reusable code that isn't tied to one scene
  components/    health, hitbox, hurtbox, cooldown, faction, placeholder visual
  systems/       enemy spawner, wave director, summon manager, spirit energy,
                 progression (save manager, rewards, upgrades, scene routes)
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
- **No autoloads so far.** Scene changes go through `SceneRoutes.go_to()`. Each scene that needs progression (main menu, upgrade menu, battlefield) loads it through its own `SaveManager` and saves right after changing it, so no global state is needed. Systems find each other through groups (`player`, `allies`, `gate`, `enemies`) and signals, not node paths.
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

## Progression and saving (Phase 4)

- **Rewards:** `EnemyData.gold_reward`/`xp_reward` (Hollow Soldier 5/10, Oni Brute 30/50) and `StageData.clear_gold_bonus`/`clear_xp_bonus`/`defeat_reward_ratio` (100 / 50 / 0.5). `RewardCalculator.calculate(kills, stage, victory)` returns a `BattleReward`. A victory pays the full kill rewards plus the clear bonus; a defeat pays floor(kill rewards × 0.5) and no bonus. The battlefield counts every enemy that dies, including debug spawns. Leaving with Esc pays nothing.
- **Progress:** `PlayerProgress` holds gold, XP (level L needs 100·L·(L−1)/2 XP), upgrade levels by id, cleared stage ids, and battle stats. `record_battle()` applies a reward and returns how many levels were gained.
- **Upgrades:** `UpgradeData` (target SAMURAI/ALLY/SPIRIT_ENERGY, stat, amount per level, max level, base cost × growth^level rounded to 5) lives in `data/upgrades/upgrade_catalog.tres`. `UpgradeShop.purchase()` returns OK, NOT_ENOUGH_GOLD or MAX_LEVEL and changes nothing on failure. At battle start, `UpgradeApplier` builds upgraded **copies** of PlayerStats, each AllyData (matched by `AllyData.id`) and the spirit regen. The battlefield applies them through `Player.apply_stats()`, `SummonManager.ally_slots` and `SpiritEnergy.regen_per_second`. The shared `.tres` files are never modified.
- **Saving:** `SaveManager` writes versioned JSON (`version`, `saved_at_unix`, `data`) to `user://savegame.json`.
  - Each save writes `.tmp` and re-reads it to check it is valid. Only then does the previous main file become `.bak` (only if that file is itself valid, so a corrupt main never overwrites a good backup), and the temp file is renamed into place.
  - Loading validates every field (types, whole non-negative numbers, version ≤ supported) and goes main → backup → fresh. Problems are reported with `push_warning` and `last_warning`, which the menus show, and never crash. `_migrate()` is the hook for future format versions.
  - `reset_progress()` deletes the save, backup and temp files and writes a fresh save. The upgrade menu asks for confirmation first.
- **Screens:** `ResultScreen` (CanvasLayer, keeps running while paused) shows the reward breakdown, totals, level-up and save status, with Retry, Upgrades and Main Menu buttons. The upgrade menu builds one row per catalog entry (level, current → next effect, cost); unaffordable purchases are rejected with a reason. The main menu shows saved gold and level.

## Mobile controls and settings (Phase 5)

- **Touch input** (`scripts/ui/`, `scenes/ui/touch_controls.tscn`):
  - `TouchControls` is a pausable CanvasLayer. It routes `InputEventScreenTouch`/`Drag` in `_input` by **touch index**: `TouchJoystick` and each `TouchActionButton` claim one finger, so moving and attacking work at the same time.
  - Widgets call `Input.action_press/release` on the existing actions (`move_left/right` with analog strength, `attack`, `heavy_attack`, `dash`, `spirit_slash`, `summon_1/2`). Gameplay and the battlefield only read Input Map state, so keyboard and touch behave identically.
  - A tap shorter than one physics tick is held until the next tick, so `is_action_just_pressed` still sees it.
  - Pausing or hiding the controls releases every held action.
  - Controls ignore the mouse. With `emulate_touch_from_mouse` they can be tested on Windows.
- **Layout:** `TouchLayout` is pure math, so it's unit-tested.
  - It computes the cluster rects from the viewport size, the safe area (`DisplayServer.get_display_safe_area()` converted to canvas units on mobile, the full rect on desktop), the UI scale (0.9–1.4), and handedness. Left-handed mirrors the joystick and action clusters and the buttons inside the cluster. Summons stay centered and move up if they would overlap.
  - Clusters are placed with corner anchors plus offsets, and are recomputed on viewport resize.
  - **44 pt rule:** iPhone 16 landscape is 393 pt tall and the canvas is 1080 units tall, so 44 pt ≈ 121 units. The smallest touch button is 150 units × 0.9 minimum scale = 135. Every menu button and slider is at least 124 units, and a test checks every menu scene.
- **HUD** (`GameHud`, which replaces the debug HUD):
  - `FillBar` shows samurai HP, Spirit Energy (5 segments = one Ashigaru each), gate HP, and keyboard-mode ability cooldowns. Each bar shows its value as a fill plus a number.
  - Touch buttons show cooldown as a shrinking pie plus seconds, and "can't afford" as a crossed-out button plus "need N". None of this relies on color alone.
  - The HUD also has a top-right pause button, keeps its margins inside the safe area, and scales its corner clusters around their corners.
- **Pause:** `PauseMenu` (Resume, Restart, Settings, Main Menu) replaces Esc-to-menu. The battlefield reads the `pause` action each frame. Esc closes the settings first, then resumes. On the result screen, Esc goes to the main menu.
- **Settings:** `GameSettings` (RefCounted) is saved by `SettingsStore` to `user://settings.cfg`, a versioned ConfigFile written as temp then renamed. Each invalid key falls back to its default.
  - `SettingsPanel` is shared by the main menu and the pause menu. Changes apply live and are saved on close.
  - The volume settings drive the Music/SFX buses from `default_bus_layout.tres`. **There is no audio content yet**, so the sliders have nothing audible to control.
  - `BattleFeedback` handles screen shake (camera offset) and vibration (`Input.vibrate_handheld`, mobile only), each behind its setting.
  - Still no autoload: each scene loads settings when it starts, and audio bus state is global anyway.

## Tests

Run `godot_console --headless --path . -s res://tests/run_tests.gd`. It covers HealthComponent, hitbox/hurtbox rules, the cooldown timer, Spirit Energy and summon validation, and WaveDirector flow (completion on death, completion when an enemy is freed, no double counting, and the break between waves). It also covers settings round-trip and validation, touch layout mirroring, the safe area, minimum touch target sizes (including every menu control), multitouch move + attack, and release on pause. It also covers rewards, upgrade purchases, upgrades reaching battle units, and SaveManager round-trip, backup, corruption fallback, validation and reset (using `user://test_saves/`). It also covers units whose target, or a projectile whose source, is freed mid-fight. The runner registers a `Logger`, and any test that logs an engine or script error fails, even if its assertions passed.

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
