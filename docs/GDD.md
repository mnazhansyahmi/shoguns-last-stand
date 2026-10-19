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

Moves: a 3-hit combo, a heavy attack, a dash, and the Spirit Slash special.

## Enemies

| Enemy | HP | Damage | Notes |
|---|---|---|---|
| Hollow Soldier | 75 | 12 | Basic melee |
| Oni Brute | 350 | 35 | Slow, area melee |

## Allies (Spirit Energy: max 150, regen 5/s)

| Ally | HP | Damage | Cost | Notes |
|---|---|---|---|---|
| Ashigaru | 120 | 14 | 30 | Melee |
| Yumi Archer | 70 | 12 | 45 | Projectile |

## Stage 1 waves

1. 4 × Hollow Soldier
2. 6 × Hollow Soldier
3. 6 × Hollow Soldier + 1 × Oni Brute

## Village gate

1000 HP and a visible health bar. The battle is lost when it reaches 0.

## Rewards

Hollow Soldier: 5 gold, 10 XP. Oni Brute: 30 gold, 50 XP. Clearing a stage adds 100 gold and 50 XP. A defeat keeps 50% of kill rewards. A full stage 1 clear pays 210 gold and 260 XP.

## Upgrades (5 levels each; cost grows ×1.5 per level)

| Upgrade | Per level | First level cost |
|---|---|---|
| Samurai max HP | +20 HP | 100 |
| Samurai attack damage | +3 | 120 |
| Ashigaru HP | +20 HP | 80 |
| Ashigaru damage | +3 | 80 |
| Archer damage | +3 | 100 |
| Spirit regeneration | +1 energy/s | 120 |
