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

Hollow Soldier: 8 gold, 10 XP. Oni Brute: 40 gold, 50 XP. Clearing a stage adds 150 gold and 50 XP. A defeat keeps 50% of kill rewards. A full stage 1 clear pays **318 gold** and 260 XP.

## Upgrades (5 levels each; cost grows ×1.2 per level, rounded to 5)

| Upgrade | Per level | Level costs |
|---|---|---|
| Samurai max HP | +20 HP | 100, 120, 145, 175, 205 |
| Samurai attack damage | +3 | 120, 145, 175, 205, 250 |
| Ashigaru HP | +20 HP | 80, 95, 115, 140, 165 |
| Ashigaru damage | +3 | 80, 95, 115, 140, 165 |
| Archer damage | +3 | 100, 120, 145, 175, 205 |
| Spirit regeneration | +1 energy/s | 120, 145, 175, 205, 250 |

**Pacing target:** about 2 upgrades per stage clear. If you always buy the cheapest upgrade, early clears buy about 3, later ones 1–2, and everything is maxed after about 15 clears (it was 38 before Phase 7). A test checks this.

## Game feel

- **Sounds:** sword swing, hit, heavy hit, dash, spirit slash, summon, enemy death, gate hit, victory, defeat and button click. They're synthetic placeholders made by `tools/generate_sfx.gd`.
- **Hit-stop:** heavy attacks (the samurai's heavy attack and the Oni Brute's slam) and kills freeze the game for about 50 ms.
- **Screen shake:** player hits, gate hits, heavy hits and kills, if Screen shake is on.
- **Damage numbers:** float up from every hit. Pale yellow means damage to enemies, orange "N!" a heavy hit, and red damage to the samurai, allies or gate.
- **Vibration:** 45 ms when the samurai is hit and 20 ms when the samurai lands a heavy hit, only on phones/tablets with Vibration on.
