class_name AttackProfile
extends Resource
## Timing, reach and impact of a single melee attack. Damage = base damage × multiplier.

@export var damage_multiplier: float = 1.0
@export var windup: float = 0.1
@export var active_time: float = 0.1
@export var recovery: float = 0.2
## Extra wait after recovery before the same attack can start again.
@export var cooldown: float = 0.0
@export var knockback: float = 150.0
## Hitbox center relative to the attacker's feet, for an attacker facing right.
@export var hitbox_offset: Vector2 = Vector2(60.0, -60.0)
@export var hitbox_size: Vector2 = Vector2(90.0, 80.0)
## Forward speed applied when the hitbox becomes active.
@export var lunge_speed: float = 0.0
## Heavy hits get the heavy impact sound, a short hit-stop and a small screen shake.
@export var heavy: bool = false


func get_total_duration() -> float:
	return windup + active_time + recovery
