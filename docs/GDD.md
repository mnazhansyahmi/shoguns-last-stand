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

An area attack charged through combat. The meter (`UltimateMeter`, 100 points, empty at the start of every battle) fills from damage: 0.1 per point the samurai deals, 0.03 per point his allies deal, 0.25 per point he takes. When full the HUD bar and the touch button glow and pulse. Using it: the samurai raises his blade (0.35 s, invulnerable for the whole move), then an ink-brush stroke sweeps across the screen, the game freezes for 0.15 s (a short dramatic pause) while every enemy in view takes 9x his attack damage as a heavy hit (180 at base: it kills a Hollow Soldier, and takes 20% off an Oni Brute). It can be used from any state except dead (a panic button) and empties the meter.

## Enemies

| Enemy | HP | Damage | Notes |
|---|---|---|---|
| Hollow Soldier | 160 | 24 | Basic melee, speed 90 |
| Oni Brute | 900 | 65 | Slow (52), area melee, heavy |

Enemies were buffed after playtesting showed summoned allies could win stage 1 without the player (spec values were 75/12 and 350/35). See `tools/balance_sim.gd` for how this is measured.

## Allies (Spirit Energy: max 150, regen 5/s)

Summon keys 1-6 (or the summon buttons) are given to the unlocked allies in this order. Only unlocked allies are shown.

| Ally | HP | Damage | Cost | Unlock | Notes |
|---|---|---|---|---|---|
| Ashigaru | 120 | 14 | 30 | start | Melee |
| Yumi Archer | 70 | 12 | 45 | start | Projectile |
| Shrine Healer | 80 | heals 28 | 65 | clear Stage 1 | Walks to the most injured ally in range and heals it every ~2.8 s; does not attack. Fragile |
| Spear Guardian | 340 | 11 | 80 | clear Stage 2 | Tank: 70% knockback resistance, cannot be staggered, and enemies within 380 px of her pick her before other allies |
| Onmyoji | 75 | 38 burst | 110 | clear Stage 3 | Throws a talisman that bursts on every enemy within 130 px of its target; range 430 |
| Hatamoto | 260 | 30 | 150 | clear Stage 4 | Elite melee: a naginata sweep hits several enemies; 30% knockback resistance |

**Balance of the later allies** (`tools/balance_sim.gd`, 3 battles per stage, no upgrades, progressive unlocks; `roster=ashigaru,yumi_archer` is the old two-ally baseline). The scripted summoner buys Guardian, Hatamoto, Onmyoji and a Healer (once there are 3 allies) before cheap fighters.

| Stage | Bot: allies lost, player deaths (2 allies -> 6) | Allies only, no player: wins (2 allies -> 6) |
|---|---|---|
| 1 | 0, 1.0 -> 0, 1.0 | 2/3 -> 3/3 (same allies: variance) |
| 2 | 0, 1.0 -> 0, 1.0 | 2/3, gate 65% -> 3/3, gate 100% (the Healer) |
| 3 | 2.7, 4.7 -> 0, 4.0 | 0/3 -> 1/3 |
| 4 | 10, 8.3 -> 4, 7.3 | 0/3 -> 0/3 |
| 5 | 18.7, 10.7 -> 18, 10.3 | 0/3 -> 0/3 |

The new allies make the mid stages kinder (fewer allies die, the samurai dies a little less) and let allies alone hold stages 1-2, but stages 4-5 still need the samurai and the late battles still cost him about 10 deaths without upgrades, so nothing is trivialised. The Hatamoto costs 150 (a full Spirit bar), the Onmyoji 110 and the Guardian 80, which keeps them a real spending decision.

An ally's upgrades show in the upgrade menu from the start but can only be bought once it is unlocked. The result screen announces newly unlocked allies.

## Region 1: Bamboo Outskirts

Every stage is a different sunset (indigo to crimson to gold): Golden Sunset, Rose Dusk, Misty Grove, Broken Shrine (blood red) and Oni's Hollow (an eclipse). Pampas grass and reeds sway in wind that gusts and changes, red maple leaves and petals drift on it, light rays cut through the fog, and a thin rim of the sun's light outlines every fighter. See docs/ART_BIBLE.md.

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
| Healer blessing | +5 healing (4 levels) | 130, 155, 185, 225 |
| Guardian HP | +40 HP (4 levels) | 150, 180, 215, 260 |
| Onmyoji damage | +5 damage (4 levels) | 170, 205, 245, 295 |
| Hatamoto damage | +4 damage (4 levels) | 190, 230, 275, 330 |

**Economy curve** (clear each stage once, then replay it once, always buying the cheapest upgrade; checked by a test and by `tools/balance_sim.gd -- curve`):

| After | Upgrade levels owned (of 46) |
|---|---|
| Stage 1 ×2 | 4 |
| Stage 2 ×2 | 9 |
| Stage 3 ×2 | 15 |
| Stage 4 ×2 | 24 (≈ 52%, going into stage 5) |
| Stage 5 ×2 | 34 (≈ 74%; the rest is for the next region) |

The first stage 1 clear buys 2 upgrades. Stage 1 is winnable with no upgrades.

## Game feel

- **Sounds:** sword swing, hit, heavy hit, dash, spirit slash, summon, enemy death, gate hit, victory, defeat and button click. They're synthetic placeholders (also ultimate, ultimate ready, heal and magic burst) made by `tools/generate_sfx.gd`.
- **Hit-stop:** heavy attacks (the samurai's heavy attack and the Oni Brute's slam) and kills freeze the game for about 50 ms.
- **Screen shake:** player hits, gate hits, heavy hits and kills, if Screen shake is on.
- **Damage numbers:** float up from every hit. Pale yellow means damage to enemies, orange "N!" a heavy hit, and red damage to the samurai, allies or gate. Quick hits on the same target merge into one growing number, numbers that would overlap stack upward with a gap, and at most 6 are on screen (a new one pushes out the oldest).
- **Vibration:** 45 ms when the samurai is hit and 20 ms when the samurai lands a heavy hit, only on phones/tablets with Vibration on.
