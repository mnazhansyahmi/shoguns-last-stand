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
