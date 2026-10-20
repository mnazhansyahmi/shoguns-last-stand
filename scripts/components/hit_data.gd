class_name HitData
extends RefCounted
## Result of one validated hit, passed from a hurtbox to its owner.

var damage: float
var knockback: Vector2
var source: Node
## From a heavy attack (AttackProfile.heavy).
var heavy: bool = false
## This hit brought the target to 0 health.
var killed: bool = false
## From the Spirit Slash (the spirit blade bleeds more).
var spirit: bool = false


func _init(p_damage: float = 0.0, p_knockback: Vector2 = Vector2.ZERO, p_source: Node = null) -> void:
	damage = p_damage
	knockback = p_knockback
	source = p_source
