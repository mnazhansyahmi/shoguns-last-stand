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
