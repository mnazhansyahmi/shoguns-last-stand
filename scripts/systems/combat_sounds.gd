class_name CombatSounds
extends RefCounted
## Which sounds the big enemies make: the Oni and the boss die, roar and slam in a lower voice than a soldier.

## The pitch an enemy's death groan plays at: a soldier at its own pitch, an Oni lower, the boss lowest.
static func death_pitch(data: EnemyData) -> float:
	if data == null:
		return 1.0
	match data.figure:
		InkFigure.Kind.FALLEN_DAIMYO:
			return 0.6
		InkFigure.Kind.ONI_BRUTE:
			return 0.7
	return 1.0


## The big ones that roar when they arrive and slam the ground: the Oni and the boss.
static func is_big(data: EnemyData) -> bool:
	return data != null and (data.figure == InkFigure.Kind.ONI_BRUTE or data.figure == InkFigure.Kind.FALLEN_DAIMYO)


## The pitch of the roar when `data` arrives (the boss lower than an Oni).
static func roar_pitch(data: EnemyData) -> float:
	return 0.8 if data != null and data.figure == InkFigure.Kind.FALLEN_DAIMYO else 1.0
