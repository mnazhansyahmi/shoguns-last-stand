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
- **Visuals:** `UnitVisual` is the animation interface for units (`set_facing`, `play_state`, `flash_hit`, `set_blinking`, `set_tint`). Gameplay code only calls these methods, so the art can change without touching combat logic. Since Phase 9 everything is drawn by code (see the Art section and `docs/ART_BIBLE.md`).
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
- `UnitRig` builds the per-instance collision shapes shared by enemies and allies.
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
- **Auto touch mode:** on Windows, `DisplayServer.is_touchscreen_available()` only mirrors the project's `emulate_touch_from_mouse` setting (verified: true with emulation on, false with it off), so it can't detect real hardware. `GameSettings.detect_touchscreen()` therefore trusts it only on mobile and web. On desktop, touch controls appear after the first **real** touch: an `InputEventScreenTouch` whose device isn't `DEVICE_ID_EMULATION` (−1, which Godot uses for touches emulated from the mouse). That is remembered for the session.
- **Keeping the battle visible:** while touch controls are shown, the battlefield moves its Camera2D down by `TouchLayout.ground_lift()`, so the ground line (and with it the gate, allies, enemies and spawn portal) sits 24 units above the joystick and action clusters. That's 210 units at 100% UI scale and 350 at 140%. Touch widgets are drawn at 60% opacity, and fully opaque while held.
- **HUD** (`GameHud`, which replaces the debug HUD):
  - `FillBar` shows samurai HP, Spirit Energy (5 segments = one Ashigaru each), gate HP, and keyboard-mode ability cooldowns. Each bar shows its value as a fill plus a number.
  - Touch buttons show cooldown as a shrinking pie plus seconds, and "can't afford" as a crossed-out button plus "need N". None of this relies on color alone.
  - The HUD also has a top-right pause button, keeps its margins inside the safe area, and scales its corner clusters around their corners.
- **Pause:** `PauseMenu` (Resume, Restart, Settings, Main Menu) replaces Esc-to-menu. The battlefield reads the `pause` action each frame. Esc closes the settings first, then resumes. On the result screen, Esc goes to the main menu.
- **Settings:** `GameSettings` (RefCounted) is saved by `SettingsStore` to `user://settings.cfg`, a versioned ConfigFile written as temp then renamed. Each invalid key falls back to its default.
  - `SettingsPanel` is shared by the main menu and the pause menu. Every option is a full-size toggle button (124 units tall) that spells out its state ("Vibration: On", "[ Always ]"). There are no small switches or dropdowns. Changes apply live and are saved on close.
  - The volume settings drive the Music/SFX buses from `default_bus_layout.tres`. **There is no audio content yet**, so the sliders have nothing audible to control.
  - `BattleFeedback` handles screen shake (camera offset) and vibration (`Input.vibrate_handheld`, mobile only), each behind its setting.
  - Still no autoload: each scene loads settings when it starts, and audio bus state is global anyway.

## Quality and performance (Phase 6)

- **Signal connections:** nothing is disconnected by hand on purpose. Every connection goes either to the node's own children or between nodes freed together with the scene, and Godot 4 removes a connection when either end is freed. With no autoloads, the only long-lived emitter is the root viewport (`size_changed`). A test checks that freeing the battlefield leaves the viewport's connection count unchanged.
- **Stored references** (targets, projectile sources, exported sibling nodes) are checked with `is_instance_valid` on the member before use. See CLAUDE.md.
- **Stuck input:** `TouchControls` releases every held action on pause, on hide and in `_exit_tree`, so a finger held during Restart/Retry/Main Menu doesn't stay pressed into the next scene.
- **Backgrounding:** the battlefield opens the pause menu on `NOTIFICATION_APPLICATION_FOCUS_OUT` / `NOTIFICATION_APPLICATION_PAUSED` (home gesture, phone call, alt-tab).
- **Performance** (headless, `--fixed-fps 60`, debug build, AMD Ryzen 7 250; scripts and physics only, no rendering):
  - Setup: 30 enemies via F1 plus 12 allies, 30 s of combat (12 enemies killed).
  - Frame time: avg 2.5 ms, p95 4.3 ms, max 6.8 ms. The empty field is about 0.5 ms. The 60 FPS budget is 16.7 ms.
  - Enemy separation and target scans are O(n²) over group members, which is fine at this scale.
  - **No object pooling:** the numbers don't call for it.
  - Existing caps stay: `EnemySpawner.max_alive` = 40 (including dying corpses) and `SummonManager.max_allies` = 6.
  - Not measured: GPU and rendering cost, and anything on a real iPhone.

## Game feel (Phase 7)

- **Audio autoload (the only autoload):** `Audio` = `scripts/systems/audio_manager.gd` (`AudioManager`).
  - **Why it's justified:** a sound owned by a scene is cut off the moment that scene changes (the click on "Start", "Retry"), and the victory/defeat stings must play while the tree is paused. The manager uses `PROCESS_MODE_ALWAYS` and a pool of 12 `AudioStreamPlayer`s on the **SFX** bus, so the SFX volume setting applies.
  - Gameplay calls the static `AudioManager.play(id)`, which does nothing when no manager exists, so scenes and tests don't depend on the autoload.
  - It connects to `SceneTree.node_added`, so every `BaseButton` gets a click sound (opt out with the `no_click_sfx` meta).
  - `shutdown_audio()` stops all players before quitting, so Godot doesn't report still-playing streams as leaked.
- **Sound data:** `SfxLibrary`/`SfxEntry` in `data/audio/sfx_library.tres` give each id a stream, volume, pitch variation and minimum repeat interval (so 20 hits in one frame play once).
  - The placeholder WAVs come from `tools/generate_sfx.gd`: deterministic synthesis, 16-bit mono, 22050 Hz, about 240 KB total.
  - Replace a sound by overwriting its WAV or editing its entry.
- **Hit reporting:** `HitData` now carries `heavy` (from `AttackProfile.heavy`, set on the samurai's heavy attack and the Oni Brute's slam) and `killed`.
  - After applying a hit, `HurtboxComponent` calls the static `BattleFeedback.report_hit(victim, position, hit)`. The battlefield's `BattleFeedback` registers itself as `active` while in the tree, and outside a battle the call does nothing.
  - Player, gate and enemy sounds and feedback now all go through this one path. The battlefield no longer listens to `HealthComponent.damaged` for feedback.
- **BattleFeedback** (`PROCESS_MODE_ALWAYS`):
  - **Hit sounds** by victim type.
  - **Damage numbers** (`DamageNumber`, a self-freeing Node2D under `World/Effects`, at most 40 at a time).
  - **Screen shake** behind its setting.
  - **Vibration**, only if `can_vibrate(setting, OS.has_feature("mobile"))`.
  - **Hit-stop:** `Engine.time_scale = 0.02` for 50 ms of real time on heavy hits and kills. It's ended by real-clock checks in `_process`, and also when the node leaves the tree, at battle end, and in `SceneRoutes.go_to()`, so a freeze can never carry into another scene or the result screen.
- **Balance:** see the GDD. Kill gold went from 5/30 to 8/40, the clear bonus from 100 to 150, and upgrade cost growth from ×1.5 to ×1.2. A test simulates full progression and checks about 2 upgrades per clear.

## Stages and regions (Phase 8)

- `RegionData` (`data/regions/bamboo_outskirts.tres`) lists `StageData` in order. `StageProgression` decides unlocks from `PlayerProgress.stages_cleared` (already in the save, so unlocks persist with no format change). Stage 1 keeps the id `stage_1`, so older saves keep their clear.
- Stage 2–5 resources are generated by `tools/make_region_1.py` (a table of waves/entries/rewards). Stage 1 is hand-tuned.
- `StageData` gained `replay_gold_multiplier` (0.5), `description`, and helpers (`get_enemy_total`, `count_enemy`, `get_full_clear_gold`). `RewardCalculator.calculate(..., replay)` multiplies gold (not XP) on replays; `BattleReward.replay` drives the result screen text.
- Scene flow: main menu Start and upgrade menu Battle → **stage select** → `SceneRoutes.go_to_battle(tree, stage)`, which stores the stage in the static `SceneRoutes.battle_stage` (also used by Retry/Restart). The battlefield applies it to the WaveDirector before starting; with no stage set it falls back to stage 1.
- The battlefield records whether the stage was cleared before the battle. A first-clear victory shows **Next Stage** (`ResultScreen.next_stage_requested`); replays don't.
- `tools/balance_sim.gd` has `zero` (every stage, no upgrades) and `curve` (whole region with one save, cheapest-upgrade buying) modes.

## Art (Phase 9)

All art is drawn by code; there are no image files. `docs/ART_BIBLE.md` is the style guide, and `InkPalette` (`scripts/visuals/ink_palette.gd`) holds every colour it lists.

- **Figures:** `InkFigure` draws one character `Kind` (Samurai, Ashigaru, Yumi Archer, Hollow Soldier, Oni Brute) as an ink silhouette. It solves a small skeleton each frame (hips, two-bone IK legs and arms, torso, head, weapon) from a `FigurePose` and motion values. `FigureKinds` holds each kind's proportions and key poses, and `FigurePainter` draws each kind's costume, weapon and single accent colour. Glowing parts (eyes, the Oni's cracks, the spirit blade) go on an additive child layer.
- **Animation:** `UnitVisual` keeps the `play_state()` interface and blends the live pose toward the current state's key pose every frame (strikes snap in under 60 ms; the Oni's windup is deliberately slow). On top of that it adds breathing, a run cycle, combo cuts (down, rising, thrust), hurt recoil, a death fall then dissolve (done within the 0.8 s corpse time), a spawn rise, and the hit flash. While a figure is see-through it is drawn inside a `CanvasGroup`, so it fades as one shape instead of showing its overlapping parts. The group is only used while fading.
- **Data:** `EnemyData.figure` / `AllyData.figure` pick the kind, and the figure is drawn at `body_size.y`. The old colour, weapon-length and headgear fields are gone.
- **Backdrop:** `scenes/backdrops/bamboo_outskirts.tscn` stacks eleven `BackdropLayer`s, back to front: sky, moon, distant and far mountains, high mist, hills with a pagoda, far bamboo, low mist, near bamboo, ground and front fog. `BambooOutskirtsPainter` draws each one once, seeded so it's the same every time. The battlefield places the backdrop under `World` in place of the old polygons; the ground's collision body is unchanged.
  - **Parallax:** a layer at depth d follows the camera by (1 − d) (`BackdropLayer.parallax_offset`). The camera only moves for the touch-controls lift and screen shake, so far layers shift and shake less than the battlefield. This is done by hand rather than with Parallax2D so the maths is explicit and unit-tested.
  - **Fog** layers drift sideways. Their art repeats every `FOG_TILE` px and is drawn three times, so the drift wraps without a seam. The front fog layer has `z_index` 5, so it passes in front of the fighters' feet. It stays faint (≤ 13% per wisp), as the art bible's contrast rules require.
  - New regions get their own painter and backdrop scene.
- **Gate and portal:** `GateVisual` draws the gate tower, palisade wall and two flickering lanterns. `VillageGate` passes it the damage ratio (cracks at 1/3 and 2/3) and `set_destroyed()` (lanterns out, darkened). `SpawnPortalVisual` is a ruined torii with a violet vortex. The old "GATE"/"SPAWN" labels are gone. `PlaceholderVisual` is deleted.
- `InkBrush` sends shapes to the RenderingServer as triangles, so a degenerate polygon mid-animation is skipped instead of logging a triangulation error (which would fail the tests).
- `tools/capture_screenshots.gd` renders a figure sheet (every kind in every state), the title screen, stage select and a staged battle. It needs a real renderer, so run it without `--headless`.

## Tests

Run `godot_console --headless --path . -s res://tests/run_tests.gd`. It covers HealthComponent, hitbox/hurtbox rules, the cooldown timer, Spirit Energy and summon validation, and WaveDirector flow (completion on death, completion when an enemy is freed, no double counting, and the break between waves). It also covers Region 1 data (5 stages, rising difficulty, boss wave), unlock order and saved unlocks, replay rewards, Next Stage after first clears only, stage select locks, the region economy curve, sound effects (files, SFX bus, throttling, button clicks), hit-stop (triggering, ending, never leaking), shake vs setting, damage numbers, vibration rules, the upgrades-per-clear balance, enemy target selection (priorities, range, gate fallback), the gate defeat condition (including the battlefield defeat flow), auto-pause on focus loss, connection cleanup, settings round-trip and validation, touch layout mirroring, the safe area, minimum touch target sizes (including every menu control), multitouch move + attack, and release on pause. It also covers rewards, upgrade purchases, upgrades reaching battle units, and SaveManager round-trip, backup, corruption fallback, validation and reset (using `user://test_saves/`). It also covers units whose target, or a projectile whose source, is freed mid-fight, and the art: palette contrast rules, units drawing the figure their data names, every figure playing every state, strike timing, combo cuts, death dissolving within corpse time, fading as one shape, parallax by depth, backdrop layer order, fog wrap, and the gate's damage and lantern state. The runner registers a `Logger`, and any test that logs an engine or script error fails, even if its assertions passed.

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
