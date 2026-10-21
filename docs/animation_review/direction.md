# Character motion refinement — 2026-10-21

The user rejected the still menu portrait, imperceptible gameplay hair/cloth and
long neck. They authorized this phase: menu breathing and wind with feet anchored;
shorter natural samurai neck and visible motion follow-through; differentiated
motion for all six allies; recorded clips, transitions, ground and performance checks.

Retain the approved painted swordsman, original sunset/menu composition and
procedural allies. This is motion and proportion refinement, with no combat-stat,
control, skill-timing or campaign changes. The original character concept is in
`../slim_samurai/approved_concept.png`; the user's later screenshots and request
supersede the previous static-portrait choice. No new visual-world selection.

The focal moment is the living swordsman standing in the menu: chest breathing,
independently weighted hair and free robe edges, feet pinned to rock. Native
vertex deformation reuses the original alpha texture. Gameplay uses world-space
hair/cloth chains so turns, attacks and stopping retain momentum. The archer's
light ribbons, healer's soft sleeves/hair, guardian's restrained cords and
Hatamoto's weighted banner retain distinct responses. A reduced-motion setting
softens decoration while preserving combat animation.

The 30-enemy benchmark retains the existing strict 8 ms target; measure and report
the result, including failures. Review actual captured sequences at 15 fps and
selected rendered frames. Mechanical checks cover anchors, chain lengths,
teleports, feet and existing pose transitions; sampled clips are not device QA.
