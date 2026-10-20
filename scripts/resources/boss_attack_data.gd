class_name BossAttackData
extends Resource
## One attack of a boss. Every attack has a wind-up (the telegraph) that the player can read, then an
## active part, then recovery. Boss.gd runs it by `kind`; this resource holds the numbers.

enum Kind {
	## A wide cut in front of him.
	SWEEP,
	## Overhead strike: a shockwave on both sides of him.
	SLAM,
	## Jumps to where the target stands and lands with a blast.
	LEAP,
	## Sends a cursed wave along the ground.
	WAVE,
	## Calls Hollow Soldiers out of the ground around him.
	SUMMON,
}

@export var id: StringName = &"sweep"
@export var kind: Kind = Kind.SWEEP
@export var display_name: String = "Sweeping Cut"
## The first phase (1..3) this attack is used in.
@export_range(1, 3) var min_phase: int = 1
## Chance weight when several attacks fit.
@export var weight: float = 1.0
## Horizontal distance to the target at which this attack is chosen.
@export var min_range: float = 0.0
@export var max_range: float = 200.0

@export_group("Timing (seconds, at phase speed 1.0)")
@export var windup: float = 0.9
@export var active_time: float = 0.2
@export var recovery: float = 0.7
## This attack cannot be chosen again for this long after it starts.
@export var cooldown: float = 3.0
## How many times it repeats in a row (a combo), per phase 1, 2 and 3.
@export var repeats: Vector3i = Vector3i(1, 1, 1)

@export_group("Impact")
@export var damage_multiplier: float = 1.0
@export var knockback: float = 380.0
## Hitbox centre relative to his feet, facing right, and its size.
@export var hitbox_offset: Vector2 = Vector2(150.0, -90.0)
@export var hitbox_size: Vector2 = Vector2(340.0, 170.0)

@export_group("Projectile (WAVE)")
@export var projectile_speed: float = 460.0
@export var projectile_range: float = 1100.0

@export_group("Summon (SUMMON)")
@export var summon_enemy: EnemyData
@export var summon_count: int = 3
## He will not summon while this many of his minions are alive.
@export var minion_cap: int = 5
