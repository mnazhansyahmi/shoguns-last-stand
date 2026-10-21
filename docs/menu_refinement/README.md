# Main-menu refinement — 21 October 2026

## Shipped in this phase

- Start/Continue is the single crimson primary action, with its saved-stage caption.
- Stages, Upgrades, Settings, Credits and Quit use open parchment rows rather than six
  identical double-framed panels. Mouse hover and keyboard/gamepad focus retain animated
  gold markers; native hit areas, ordering, routes and saved progress are preserved.
- The title samurai is larger, upright and in a low katana guard, with restrained breathing
  and scarf movement. His stowed bow is hidden for this presentation only; the combat
  figure's default equipment and poses are unchanged.
- A lower ledge and a more consistent left-side wash separate the hero from navigation.

## Captures

| State | Image |
| --- | --- |
| Before, saved progress | [before.png](before.png) |
| After, fresh save | [fresh.png](fresh.png) |
| After, saved progress and focused Upgrades | [after.png](after.png) |
| After, wide landscape | [wide.png](wide.png) |

The normal desktop captures are 1280 x 720. The wide capture requested a 2341 x 1080
window; the desktop host constrained its drawable height to 1061, as recorded by the
resulting image. It demonstrates wide-window layout, not physical phone validation.
Capture fixtures use their own saves under `user://screenshots`, not the player's save.
This folder is excluded from Godot imports/exports by `.gdignore`.

## Validation actually run

- Godot 4.7.2 import/parse check: clean after granting access to editor settings.
- Ordinary verbose headless boot/quit: exit 0, with no engine/script errors or
  leaked-instance/resource messages.
- Full headless suite: **425 passed, 0 failed**, with access to its isolated test-save
  folders. The initial sandboxed run could not write those folders and was not accepted
  as validation.
- Real-renderer captures: fresh and existing progress, entrance and focus states, at
  desktop and wide sizes. Render commands exited cleanly without script/engine errors.
- Existing tests cover title alignment, blade/body separation, arm reach, menu target
  sizes, saved-stage captions, focus transitions and entrances.
- No battle-performance claim is made by this menu-only phase. The previous strict
  8 ms battle target remains outstanding. No physical touch/gamepad play-test was run.

Raw logs and additional captures are local under `builds/menu_refinement/`.
The pre-existing `project.godot` changes and untracked music are left out of this phase.
`tools/make_region_1.py` was never run.

## Requested next content phase

Region 2: **Burning Village**, with new levels and enemy archetypes such as flyers,
shield bearers and archers. Introduce additional allies alongside the enemy roles they
counter. This phase only records that direction; it does not create stages or alter
campaign progression.
