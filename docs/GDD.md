# Game Design Document (short)

The full, authoritative spec is [MASTER_PROMPT.md](MASTER_PROMPT.md). This is a summary.

## Pitch

You are a lone samurai defending a village gate on the left side of the screen. Undead waves come from the right. Fight with the katana and summon allies with Spirit Energy. If the gate falls, you lose. Clear every wave to win.

## Core loop

Battle (3 waves) → rewards (gold, XP) → upgrades → next battle.

## Player (samurai)

| Stat | Value |
|---|---|
| Health | 200 |
| Basic damage | 20 |
| Move speed | 210 px/s |
| Dash distance | 135 px |
| Dash cooldown | 3 s |

Moves: a 3-hit combo, a heavy attack, a dash, the Spirit Slash special, and the Ultimate.

## Ultimate (key I, touch button beside the other skills)

An area attack charged through combat. The meter (`UltimateMeter`, 100 points, empty at the start of every battle) fills from damage: 0.1 per point the samurai deals, 0.03 per point his allies deal, 0.25 per point he takes. When full the HUD bar and the touch button glow and pulse. Using it: the samurai raises his blade (0.35 s, invulnerable for the whole move), then an ink-brush stroke sweeps across the screen, the game freezes for 0.4 s (a short dramatic pause) while every enemy in view takes 9x his attack damage as a heavy hit (180 at base: it kills a Hollow Soldier, and takes 20% off an Oni Brute). It can be used from any state except dead (a panic button) and empties the meter.

## Enemies

| Enemy | HP | Damage | Notes |
|---|---|---|---|
| Hollow Soldier | 160 | 24 | Basic melee, speed 90 |
| Oni Brute | 900 | 65 | Slow (52), area melee, heavy |

Enemies were buffed after playtesting showed summoned allies could win stage 1 without the player (spec values were 75/12 and 350/35). See `tools/balance_sim.gd` for how this is measured.

## Allies (Spirit Energy: max 150, regen 5/s)

| Ally | HP | Damage | Cost | Notes |
|---|---|---|---|---|
| Ashigaru | 120 | 14 | 30 | Melee |
| Yumi Archer | 70 | 12 | 45 | Projectile |

## Region 1: Bamboo Outskirts

Stages unlock in order (stage N needs stage N-1 cleared) and are picked on the stage select screen (Start). Only Hollow Soldiers and Oni Brutes appear. Oni Brutes head for the gate once it is in range (target priority gate → allies → player).

| # | Stage | Waves | Soldiers | Oni | Fastest spawn | First clear gold | Replay gold |
|---|---|---|---|---|---|---|---|
| 1 | The Village Gate | 3 | 25 | 1 | 0.6 s | 340 | 170 |
| 2 | Bamboo Path | 4 | 38 | 1 | 0.55 s | 468 | 234 |
| 3 | Misty Grove | 4 | 44 | 5 | 0.5 s | 724 | 362 |
| 4 | Broken Shrine | 5 | 72 | 10 | 0.4 s | 1162 | 581 |
| 5 | Oni's Hollow | 5 (last = boss: 6 Oni + 12 soldiers) | 76 | 16 | 0.35 s | 1546 | 773 |

Replays (stage already cleared) pay 50% gold; XP is unchanged. After a first clear the result screen offers **Next Stage**.

## Village gate

1000 HP and a visible health bar. The battle is lost when it reaches 0.

## Rewards

Hollow Soldier: 6 gold, 10 XP. Oni Brute: 40 gold, 50 XP. Each stage adds its own clear bonus (150 / 200 / 260 / 330 / 450 gold). A defeat keeps 50% of kill rewards; a replay pays 50% gold.

## Upgrades (5 levels each; cost grows ×1.2 per level, rounded to 5)

| Upgrade | Per level | Level costs |
|---|---|---|
| Samurai max HP | +20 HP | 140, 170, 200, 240, 290 |
| Samurai attack damage | +3 | 170, 205, 245, 295, 355 |
| Ashigaru HP | +20 HP | 110, 130, 160, 190, 230 |
| Ashigaru damage | +3 | 110, 130, 160, 190, 230 |
| Archer damage | +3 | 140, 170, 200, 240, 290 |
| Spirit regeneration | +1 energy/s | 170, 205, 245, 295, 355 |

**Economy curve** (clear each stage once, then replay it once, always buying the cheapest upgrade; checked by a test and by `tools/balance_sim.gd -- curve`):

| After | Upgrade levels owned (of 30) |
|---|---|
| Stage 1 ×2 | 4 |
| Stage 2 ×2 | 8 |
| Stage 3 ×2 | 14 |
| Stage 4 ×2 | 22 (≈ 73%, going into stage 5) |
| Stage 5 ×2 | 30 |

The first stage 1 clear buys 2 upgrades. Stage 1 is winnable with no upgrades.

## Game feel

- **Sounds:** sword swing, hit, heavy hit, dash, spirit slash, summon, enemy death, gate hit, victory, defeat and button click. They're synthetic placeholders (also ultimate, ultimate ready, heal and magic burst) made by `tools/generate_sfx.gd`.
- **Hit-stop:** heavy attacks (the samurai's heavy attack and the Oni Brute's slam) and kills freeze the game for about 50 ms.
- **Screen shake:** player hits, gate hits, heavy hits and kills, if Screen shake is on.
- **Damage numbers:** float up from every hit. Pale yellow means damage to enemies, orange "N!" a heavy hit, and red damage to the samurai, allies or gate.
- **Vibration:** 45 ms when the samurai is hit and 20 ms when the samurai lands a heavy hit, only on phones/tablets with Vibration on.
