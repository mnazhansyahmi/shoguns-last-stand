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

## Upgrades

Samurai max HP, samurai damage, Ashigaru HP, Ashigaru damage, Archer damage, and spirit regeneration.
