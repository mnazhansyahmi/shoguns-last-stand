# Boss header and sword review — v0.2 — 2026-10-23

Local changes only. No publishing or region generator execution. The pre-existing
project.godot ordering change is preserved and excluded from these commits.

## Part 1 — Boss bar at top

The painted bar is now a 560×90 logical-pixel maximum panel directly under the
wave counter. A reserved central column prevents the left vitals from pushing it
down or overlapping it at large UI scales. The boss view reserves body/leap
headroom while retaining touch ground lift, and restores ordinary framing when
the boss dies. The existing opaque ground texture continues below its original
band so the wider phone view does not reveal an empty strip. No new art generated.

**523/523 tests passed**. Import and boot passed. Tests cover header centering,
safe insets, UI scales 0.9–1.4, body/leap clearance and restored normal zoom.

| Physical render | HUD | Leap-height check |
| --- | --- | --- |
| 1280×720 | [HUD](header/1280_hud.png) | [Leap](header/1280_leap.png) |
| 1920×1080 | [HUD](header/1920_hud.png) | [Leap](header/1920_leap.png) |
| 2400×1080 phone, touch controls | [HUD](header/phone_hud.png) | [Leap](header/phone_leap.png) |

Desktop renders retain the project's 1920×1080 logical canvas; the phone expands
to 2400×1080. Raw render logs record the bar rectangles and camera zoom.

## Part 2 — Boss sword swings

Boss attacks now use a coupled hilt path instead of independently springing
the blade angle and wrist position. Two fixed grip points drive both arm IK
chains. The hilt stays in front of the torso, with fixed elbow poles and
reachable targets. Preparation raises the blade behind the head, the final
warning beat leads into the fast cut, followed by a short follow-through and
guard recovery. Leap descent uses the same continuous path. Short recoveries
queue behind an unfinished cut instead of replacing it with a new angle.
Facing is held through a complete combo. Idle weapon sway is suppressed while
the attack driver owns the pose. Local part order places the prepared sword
behind the torso without hiding it behind scene art. Slash trails sample the
actual solved blade each frame instead of drawing a separate idealized swing.
Damage values, hitbox sizes, cooldowns and phase timings are retained.

**525/525 tests passed**. Import, boot and all renders passed. The new regression
runs both bosses' eleven attack definitions in every phase and both facings:
**66 complete attacks/combos**. It checks both wrist attachments, arm reach,
elbow poles, raised-blade order, ground-clearance corrections and consecutive
blade angles. Maximum observed jump: **17.963° per 60-Hz frame**, below the
**24° limit**. Separate 30/120-fps checks verify the same angular-rate bound.
Test fixtures own and clean up their waves, fire pillars and transient effects.

### Attack frame strips

These snapshots come from the actual Boss step driver and UnitVisual at phase
3, showing every repeat. Each row is one cut/repeat. Horizontal translation is
normalized for comparison; the leap uses its ballistic vertical offset. Aura,
projectiles and trails are omitted from these pose-only strips so the grips
remain visible. The final sample shows the settled guard. No new art generated.

| Attack | Fallen Daimyo | Burning General |
| --- | --- | --- |
| Sweeping cut / three-hit combo | [Strip](attacks/fallen_daimyo_sweep.png) | [Strip](attacks/burning_general_sweep.png) |
| Slam | [Strip](attacks/fallen_daimyo_slam.png) | [Strip](attacks/burning_general_slam.png) |
| Leaping strike | [Strip](attacks/fallen_daimyo_leap.png) | [Strip](attacks/burning_general_leap.png) |
| Cursed / fire wave | [Strip](attacks/fallen_daimyo_wave.png) | [Strip](attacks/burning_general_wave.png) |
| Summon | [Strip](attacks/fallen_daimyo_summon.png) | [Strip](attacks/burning_general_summon.png) |
| Fire eruption | — | [Strip](attacks/burning_general_eruption.png) |

The three header-size captures above were refreshed with the finished motion.
One final 30-enemy Region 2 performance sanity run measured **9.16 ms average,
11.78 ms p95** (900 measured frames after 120 warm-up), passing the existing
9.5 ms average budget. This is one run, not a new three-run benchmark.
