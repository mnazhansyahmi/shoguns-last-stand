class_name HitData
extends RefCounted
## Result of one validated hit, passed from a hurtbox to its owner.

var damage: float
var knockback: Vector2
var source: Node


func _init(p_damage: float = 0.0, p_knockback: Vector2 = Vector2.ZERO, p_source: Node = null) -> void:
	damage = p_damage
	knockback = p_knockback
	source = p_source
