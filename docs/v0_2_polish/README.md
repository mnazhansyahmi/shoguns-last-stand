# v0.2 playtest fixes

Local work on `v0.2`. No publishing or uploads. The Region 1 generator is never run.

## 1. Oni arm and archer bow

Oni shoulder caps now sample solid torso paint. His two-handed poses stay within
arm reach, with a connected shoulder and the upper arm behind the face. The same
ordering and shoulder checks cover the Daimyo and Burning General. Their death
grip also remains reachable.

Both archers now grip equal-length bow limbs at their visual centre, and their
string fingers track the exact cached draw step. A separate fist layer keeps the
string hand visible. Bow clearance includes the full centred silhouette.

- Full suite: **490 passed, 0 failed**. [Tests](part_1/tests.log).
- [Oni, Daimyo, General and both archers: eight poses](part_1/motion_after.png).
- [Import log](part_1/import.log).

## 2. Oni super armor

Light hits still deal damage but no longer knock the Oni backwards or interrupt
his attack. Only the player's Heavy, Spirit Slash and Ultimate pierce this armor;
ally heavy/spirit attacks do not. Walk speed is 52 -> 65, recovery 0.90 -> 0.55 s,
and cooldown 1.00 -> 0.65 s. The readable 0.80 s wind-up is unchanged.
No wave counts or rewards were changed: the upgraded campaign remains viable.

Continuous pose checks also caught the club rotating backwards between run and
wind-up. The carry angle now transitions forwards, and both heavy hands remain
within arm reach during blends, including the Daimyo and Burning General.

Three bot runs per stage, no upgrades, progressive ally unlocks:

| Stage | Wins before -> after | Gate % before -> after | Seconds before -> after | Deaths before -> after |
| --- | --- | --- | --- | --- |
| 1 | 3/3 -> 3/3 | 100 -> 100 | 82 -> 82 | 1.0 -> 1.0 |
| 2 | 3/3 -> 3/3 | 100 -> 100 | 111 -> 112 | 1.0 -> 1.0 |
| 3 | 3/3 -> 3/3 | 100 -> 100 | 161 -> 171 | 3.0 -> 4.0 |
| 4 | 3/3 -> 3/3 | 100 -> 100 | 259 -> 261 | 5.7 -> 7.7 |
| 5 | 2/3 -> 3/3 | 51 -> 74 | 340 -> 397 | 11.3 -> 11.7 |
| 6 | 3/3 -> 3/3 | 100 -> 100 | 298 -> 293 | 7.3 -> 8.3 |
| 7 | 3/3 -> 3/3 | 100 -> 100 | 307 -> 295 | 11.0 -> 11.3 |
| 8 | 3/3 -> 3/3 | 100 -> 100 | 338 -> 350 | 9.7 -> 10.7 |
| 9 | 3/3 -> 3/3 | 100 -> 100 | 423 -> 410 | 13.0 -> 12.3 |
| 10 | 1/3 -> 0/3 | 23 -> 0 | 485 -> 461 | 19.7 -> 19.0 |

The final stage's zero-upgrade stress result worsened. The normal purchased
campaign in Part 3 won all 20 clear/replay battles, so the final stage still
expects progression; these three stress samples do not establish human balance.

- [Before](part_2/before_all.log), [after](part_2/after_all.log).
- Armor checkpoint: **494 passed**; final transition/integration check:
  **499 passed**, including the subsequently prepared settings and cap tests.
  [Armor tests](part_2/tests.log), [integration tests](part_2/tests_final.log).
- [Final heavy/archer motion sheet](part_2/motion_after.png).
