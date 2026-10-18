# CLAUDE CODE MASTER PROMPT — SHOGUN'S LAST STAND

You are a senior Godot 4 game developer, technical architect, 2D combat designer, mobile game UX engineer, and automated testing specialist.

Your task is to **build a fully functional, playable 2D side-scrolling samurai defense game** called **Shogun's Last Stand**.

This is an original modern spiritual successor inspired by the gameplay genre of Samurai vs Zombies Defense. Do not copy any original game's source code, sprites, sound effects, music, UI, trademarks, characters, or proprietary assets.

## 1. Development environment

- Operating system: Windows 11
- Game engine: Latest stable Godot 4.x available locally
- Programming language: GDScript with static typing where practical
- Target platform: iPhone 16 running iOS 26
- Development/testing platform: Windows
- Orientation: Landscape
- Design resolution: 1920 × 1080
- Target frame rate: 60 FPS
- Renderer: Compatibility
- Network requirement: None
- Monetization: None
- Architecture: Modular, component-based and data-driven

Use only Godot 4-compatible APIs. Check the installed Godot version before implementing features.

## 2. Core objective

Build an engaging 2D samurai defense game in which the player controls a samurai protecting a village gate from waves of undead and supernatural enemies.

The player can move horizontally, perform katana attacks, dash, use special abilities, and summon allied units.

Enemies advance from the right side of the battlefield and attempt to destroy the gate on the left.

The player wins by eliminating every enemy in all scheduled waves and loses when the village gate is destroyed.

## 3. Mandatory project architecture

Create a complete Godot project containing:

- Main menu
- Battlefield scene
- Player scene
- Enemy scene
- Allied unit scene
- Village gate
- Wave director
- Combat system
- Summoning system
- HUD
- Touchscreen controls
- Pause menu
- Victory screen
- Defeat screen
- Upgrade menu
- Save/load manager

Use reusable components for health, damage, hitboxes, hurtboxes and attack cooldowns.

Use Godot signals for communication between systems.

Define configurable enemy, ally, stage and upgrade data using custom Resource classes.

Avoid unnecessary autoload singletons and tightly coupled scene dependencies.

## 4. Player mechanics

Create a samurai character with:

- Smooth horizontal movement
- Left/right facing
- Three-hit attack combo
- Heavy attack
- Dash with cooldown
- Spirit Slash special ability
- Health and damage
- Knockback and brief damage invulnerability
- Death animation/state
- State-based animation handling

Initial statistics:

- Health: 200
- Basic damage: 20
- Movement speed: 210 pixels/second
- Dash distance: 135 pixels
- Dash cooldown: 3 seconds

All movement and combat must be frame-rate independent.

## 5. Enemy AI

Implement a finite-state machine with these states:

- Spawn
- Advance
- Acquire target
- Attack
- Recover
- Hurt
- Dead

For the MVP, implement:

Hollow Soldier:
- 75 health
- 12 attack damage
- Basic melee behavior

Oni Brute:
- 350 health
- 35 attack damage
- Slow movement
- Area melee attack

Enemies must choose targets according to configurable priorities and attack the village gate when no valid defender blocks their advance.

Implement collision avoidance so units do not stack unnaturally.

## 6. Allied unit system

Implement summonable allies:

Ashigaru:
- 120 health
- 14 damage
- 30 Spirit Energy cost
- Melee attack

Yumi Archer:
- 70 health
- 12 ranged damage
- 45 Spirit Energy cost
- Projectile attack

Spirit Energy:
- Maximum: 150
- Regeneration: 5 per second

Allies should automatically move toward enemies and attack valid targets.

The summon manager must validate available energy, cooldowns, maximum unit count, and valid spawn positions.

## 7. Wave system

Create a reusable WaveDirector.

Initial stage:

Wave 1:
- Four Hollow Soldiers

Wave 2:
- Six Hollow Soldiers

Wave 3:
- Six Hollow Soldiers
- One Oni Brute

Use configurable spawn intervals.

Do not begin a new wave until the current wave's completion condition is satisfied.

Prevent softlocks caused by enemies being deleted unexpectedly.

## 8. Village gate

The village gate must:

- Have 1,000 maximum health
- Display a health bar
- Receive enemy damage
- Trigger defeat at zero health
- Persist throughout the battle

## 9. Combat and collision

Implement:

- Collision layers and masks
- Hitbox/hurtbox interaction
- Faction identification
- Attack cooldowns
- Damage application
- Knockback
- Death handling
- Attack interruption rules
- Invulnerability windows
- Projectile cleanup

Prevent duplicate damage from a single attack instance.

Avoid applying combat damage directly from animation visuals without authoritative hit validation.

## 10. Interface

Create a landscape mobile HUD with:

Top-left:
- Player health
- Spirit Energy

Top-center:
- Current wave
- Remaining enemies

Top-right:
- Pause button

Bottom-left:
- Virtual movement joystick

Bottom-right:
- Attack button
- Dash button
- Skill button

Bottom-center:
- Allied unit summon buttons
- Spirit Energy costs

Controls must support mouse simulation on Windows and multitouch on iOS.

Use anchors, responsive containers and safe-area-aware layout.

Keep essential touch targets approximately 44 points or larger on the target device.

## 11. Progression and saving

Create an offline progression system.

Rewards:
- Gold
- Experience

Upgrades:
- Samurai maximum health
- Samurai attack damage
- Ashigaru health
- Ashigaru damage
- Archer damage
- Spirit regeneration

Implement a versioned save format using user://.

Validate save data before loading.

Use temporary files and backup recovery to reduce the risk of corrupted saves.

Provide a reset-progress option with confirmation.

## 12. Art and audio

Use original placeholder assets initially.

If production artwork is unavailable, create readable geometric or simple vector-style placeholders with distinct silhouettes.

Never block development because finished artwork is missing.

Implement animation interfaces that allow placeholder assets to be replaced without rewriting combat logic.

Create organized folders for:
- Character sprites
- Backgrounds
- Effects
- UI
- Audio
- Animation resources

Do not download unverified third-party assets automatically.

## 13. Automated testing

Create tests for:

- Damage and healing
- Death signal emitted once
- Spirit Energy consumption
- Insufficient energy rejection
- Wave completion
- Enemy target selection
- Gate defeat condition
- Reward calculation
- Save/load round-trip
- Invalid save recovery

Use headless Godot testing where possible.

Also create an interactive smoke-test checklist for features requiring visual inspection.

## 14. Performance

Optimize for stable 60 FPS on iPhone 16.

Avoid excessive allocations during combat.

Use reasonable enemy-count limits and collision filtering.

Profile before introducing object pooling or other complex optimization.

Document performance assumptions and validate them on a real device when available.

## 15. iOS preparation

Make the project portable to macOS.

Avoid Windows-only paths, dependencies and native plugins.

Document the process for:
- Opening the project on macOS
- Installing Godot export templates
- Configuring the iOS export preset
- Exporting to Xcode
- Signing the application
- Deploying to iPhone 16
- Testing on iOS 26

Do not claim to have built or tested an iOS application unless those actions have actually been performed.

## 16. Development phases

Work in this order:

Phase 1 — Foundation:
Create project structure, project.godot, main menu, battlefield, input map and placeholder visuals.

Phase 2 — Combat:
Implement player movement, attacks, enemy AI, health, damage and gate defense.

Phase 3 — Defense:
Implement summoning, allied units, Spirit Energy and wave progression.

Phase 4 — Gameplay loop:
Implement victory, defeat, rewards, upgrades and saving.

Phase 5 — Mobile:
Implement touch controls, responsive HUD and settings.

Phase 6 — Quality:
Add tests, improve animations, optimize performance and prepare iOS export documentation.

## 17. Engineering requirements

- Use typed GDScript.
- Use descriptive file and class names.
- Keep scripts reasonably small and focused.
- Avoid circular dependencies.
- Prefer signals over hardcoded cross-scene references.
- Handle missing nodes and invalid resources gracefully.
- Do not silently ignore runtime errors.
- Do not fabricate test results.
- Keep the project runnable after each completed phase.
- Do not use pseudocode in deliverable gameplay scripts.
- Avoid TODO-only implementations for required MVP functionality.
- Write documentation for architectural decisions.
- Use Git commits at stable milestones when Git is available.

## 18. Acceptance criteria

The MVP is complete only when:

1. The Godot project opens without parsing errors.
2. The player can move and attack.
3. Enemies spawn, move and attack.
4. The gate takes damage.
5. Allies can be summoned.
6. Spirit Energy regenerates and is consumed.
7. All three waves function.
8. Victory and defeat conditions work.
9. Upgrades can be purchased.
10. Save data persists between sessions.
11. The game can be played on Windows.
12. The HUD supports simulated mobile controls.
13. Automated tests pass, or remaining failures are explicitly documented.

## 19. Execution instructions

Work ONE phase at a time. Stop after each phase and wait for the user to confirm before starting the next one.

On this machine, Godot is available in PATH as `godot_console` (version 4.7.2). Use it for headless checks, for example:
- `godot_console --headless --import`
- `godot_console --headless --quit`

After each phase:
- Run Godot import and validation checks.
- Fix any errors.
- Report exactly what was created.
- Explain how to run the project.
- Identify anything that could not be tested.
- Commit to Git.

Your job is to deliver a real, playable Godot game, not merely an architectural proposal.
