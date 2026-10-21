# Playtest feedback validation

Validated locally on 2026-10-21 against starting commit `1ba9be7` (Dramatic HUD). Existing legs, ink art, effects and untracked music files were preserved. Review PNGs and logs are excluded from game import/export by `.gdignore`.

## Delivered changes

- Frozen actual InkFigure skill pictures shared by HUD, touch controls and the Skills upgrade tab. Two faded dash afterimages, heavy slash arc, blue crescent, drawn yumi, raised katana/gold ring, charging allies and guardian stance. The Ultimate HUD medallion is unchanged.
- Cached ally portraits rise above summon circles, with cost plates, cooldowns, key badges and unavailable dimming/messages. Keyboard summons use the same smaller clickable buttons. Safe-area, handedness, 44 pt target and ground-lift tests pass.
- Keyboard help appears only on stage 1 before its first clear. The battle debug caption is gone; debug keys retain the debug-build guard. Settings Controls covers keyboard, a touch layout picture and working gamepad bindings.
- Healer selects injured allies first, then a wounded living samurai. Samurai healing is half the upgraded normal amount, capped at maximum health, with a +N number. Existing ally blessings in progress finish as before. The new samurai path checks casting reach and priority at impact.

Commits: `d3afe52` Figure skill icons; `aba6e0b` Touch button icons and portraits; `f728b76` Controls help in tutorial and settings; `7d36603` Cache static button art. The final commit is **Healer heals samurai**, including the final validation report and review captures.

## Full-suite and lifecycle checks

| Check | Observed result |
| --- | --- |
| Part 1 suite | 417 passed, 0 failed |
| Part 2 suite | 418 passed, 0 failed |
| Part 3 suite | 420 passed, 0 failed |
| Final integrated suite | 425 passed, 0 failed |
| Headless import / parse | Exit 0, no errors |
| Headless boot / quit | Exit 0, no errors or leak messages |
| Real-renderer boot / quit | Exit 0, no errors or leak messages |
| Audio shutdown ownership probe | All checks pass, including paused music, crossfade, resource/playback release and late-playback rejection |

The complete suite logs and lifecycle logs are in [logs](logs/). Final review captures were inspected with the real Compatibility/OpenGL renderer on an NVIDIA GeForce RTX 5060 Laptop GPU. This is a desktop phone-shaped render, not an iPhone hardware performance measurement. No physical gamepad was available; bindings and page navigation are checked automatically.

## Comparable performance

The starting snapshot is the exact pre-change commit `1ba9be7`, including its existing dramatic HUD and other earlier work. Both projects run the identical probe; the only added option is `--touch`, which selects the actual touch UI without changing combat or timing. Default probe behavior, the 8 ms gate, 120 warmup frames and 900 measured frames are unchanged. Each run retains 30 enemies and 6 allies; effects, figures, HUD, music and gameplay remain enabled. Vsync/frame cap are off. Runs are serial and alternate starting/final builds, with no balance sim running.

```powershell
godot_console --path <project> --fixed-fps 60 -s res://tools/perf_battle.gd
godot_console --path <project> --fixed-fps 60 -s res://tools/perf_battle.gd -- --touch
```

| UI | Pair | Start avg ms | Start p95 ms | Final avg ms | Final p95 ms |
| --- | --- | --- | --- | --- | --- |
| keyboard | 1 | 8.41 | 10.93 | 8.34 | 10.73 |
| keyboard | 2 | 8.17 | 10.37 | 8.46 | 10.76 |
| keyboard | 3 | 8.55 | 10.99 | 8.57 | 11.28 |
| touch | 1 | 8.75 | 11.21 | 8.74 | 11.30 |
| touch | 2 | 8.96 | 11.34 | 8.80 | 11.33 |
| touch | 3 | 8.81 | 11.16 | 8.80 | 11.56 |

- Keyboard: mean frame average **8.38 → 8.46 ms** (+0.08 ms); mean of the per-run p95 values **10.76 → 10.92 ms**.
- Touch: mean frame average **8.84 → 8.78 ms** (-0.06 ms); mean of the per-run p95 values **11.24 → 11.40 ms**.

The p95 summaries above are averages of run-level p95 values, not a pooled percentile. The UI overhead fits the requested approximately +0.2 ms allowance. The strict original **average <8 ms gate still FAILS** in both starting and final builds. This is not reported as an 8 ms pass.

Static button backgrounds, portraits, frames, badges and cost plates now retain their draw commands while only the sweep/timer redraws. Text shaping and summon metadata are cached. Glow, locks, prices, cooldown state, input and effects remain functional. The icon capture probe observed **0 active bake workers** after 12 frames. One-shot figure bake viewports free themselves after copying their images; the unchanged warmup excludes startup, as it did before.

The session initially produced 17.65/17.02/17.21 ms averages (p95 23.49/19.40/21.15) before host timing settled. Those are not used to claim a speedup. An early comparison accidentally used older commit `9db132f`; it was discarded and all accepted pairs above were rerun against `1ba9be7`. Earlier cache iterations also remain local under `builds/ui_feedback/`; the accepted raw logs are `logs/perf_retained_*.log`.

### Remaining bottlenecks

A separate `--debug --profiling` run was diagnostic only, not acceptance data. Excluding its startup snapshot, nine steady snapshots averaged about 2.44 ms inclusive in UnitVisual._process, including 1.73 ms in InkFigure.refresh; enemy physics averaged 0.54 ms inclusive, including about 0.30 ms in enemy blocking checks. These inclusive times overlap and must not be added. The profiled probe reported render CPU 3.34 ms and GPU 0.71 ms. Character pose work and CPU render submission remain the main costs; the new icon textures are not a dominant steady-frame cost. See [raw profiler log](logs/profile_final.log).

## Balance

The final corrected healer is measured with three battles per stage and mode, progressive unlocks and no upgrades. Each command uses the simulator's own files under `user://balance_sim`, never player saves. Bot/allies runs are serial. Per-unit RNG is randomized, so the three-run samples show outcomes, not statistically established causation.

```powershell
godot_console --headless --path . --fixed-fps 60 -s res://tools/balance_sim.gd -- stage=res://data/stages/stage_3.tres stage=res://data/stages/stage_5.tres mode=bot runs=3
# Repeat with mode=allies.
```

| Mode / stage | Wins before → after | Gate % | Seconds | Player deaths | Allies summoned | Allies lost |
| --- | --- | --- | --- | --- | --- | --- |
| bot / stage_3 | 3/3 → 3/3 | 100 → 100 | 169 → 166 | 3.7 → 3.0 | 27.7 → 25.7 | 25.7 → 23.0 |
| bot / stage_5 | 3/3 → 3/3 | 58 → 65 | 344 → 343 | 11.3 → 11.0 | 56.7 → 56.3 | 56.0 → 55.3 |
| allies / stage_3 | 1/3 → 0/3 | 33 → 0 | 652 → 677 | 2.3 → 3.0 | 108.3 → 112.3 | 107.3 → 111.7 |
| allies / stage_5 | 0/3 → 0/3 | 0 → 0 | 436 → 440 | 3.0 → 3.3 | 72.3 → 73.0 | 71.7 → 72.3 |

All values are averages as printed by the simulator, except win counts. Gate averages include losses at 0%. Bot wins remained 3/3 on both stages; the allies-only stage 3 sample fell from 1/3 to 0/3 and stage 5 remained 0/3. These mixed small-sample outcomes do not establish a consistent balance improvement. Completed per-battle output is preserved in `logs/balance_before_*.log` and `logs/balance_final_*.log`. Earlier runs of an intermediate healer implementation are not presented as final; the shipped version preserves ally blessings already in progress.

## Renders

- [HUD](desktop_hud_full.png), [HUD close-up](desktop_hud_full_zoom.png), [low health](desktop_hud_low.png), [Ultimate ready](desktop_hud_ultimate_ready.png).
- [Keyboard battle](keyboard_battle.png), [keyboard cooldowns](keyboard_battle_slash.png).
- [Phone touch battle](phone_battle.png), [phone cooldowns](phone_battle_slash.png).
- [Settings Controls](settings_controls.png).
- [Figure icon sheet](figure_icons.png), [Skills upgrade tab](skills_upgrade_tab.png), [Bow/War Cry upgrade pictures](skills_upgrade_bow_war_cry.png), [samurai receiving +14](samurai_healing.png).

## Remaining issues and limits

- The original strict 8 ms average target remains unmet; all final probe runs truthfully return its failure status.
- Balance conclusions are limited to three stochastic battles per configuration.
- Physical iPhone and physical controller behavior/performance were not tested.

`tools/make_region_1.py` was never run.
