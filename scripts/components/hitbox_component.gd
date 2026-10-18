class_name HitboxComponent
extends Area2D
## Deals damage to hostile HurtboxComponents while active.
## Each activation (one attack instance) hits a given target at most once.

signal hit_landed(hurtbox: HurtboxComponent)

@export var faction: Faction.Type = Faction.Type.DEFENDERS
## Node credited as the damage source. Defaults to the parent.
@export var source: Node

var damage: float = 0.0
var knockback: float = 0.0
## Fixed knockback direction (-1 or 1). 0 pushes targets away from the source.
var knockback_direction_x: float = 0.0

var _active: bool = false
var _time_left: float = -1.0
var _hit_targets: Dictionary = {}


func _ready() -> void:
	if source == null:
		source = get_parent()
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = Faction.hostile_hurtbox_mask(faction)


## Starts a new attack instance. A negative duration stays active until deactivate().
func activate(p_damage: float, p_knockback: float, duration: float = -1.0) -> void:
	damage = p_damage
	knockback = p_knockback
	_time_left = duration
	_hit_targets.clear()
	_active = true


func deactivate() -> void:
	_active = false


func is_active() -> bool:
	return _active


func _physics_process(delta: float) -> void:
	if not _active:
		return
	# Polling (rather than area_entered) also catches targets that were already
	# overlapping when the attack started or when the shape moved.
	for area: Area2D in get_overlapping_areas():
		var hurtbox: HurtboxComponent = area as HurtboxComponent
		if hurtbox != null:
			try_hit(hurtbox)
		if not _active:
			return
	if _time_left >= 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			_active = false


## Authoritative hit attempt. Returns true if damage was applied.
func try_hit(hurtbox: HurtboxComponent) -> bool:
	if not _active or hurtbox == null:
		return false
	var key: int = hurtbox.get_target_id()
	if _hit_targets.has(key):
		return false
	if not hurtbox.receive_hit(self):
		return false
	_hit_targets[key] = true
	hit_landed.emit(hurtbox)
	return true


func get_knockback_direction_x(target_x: float) -> float:
	if knockback_direction_x != 0.0:
		return signf(knockback_direction_x)
	var origin_x: float = global_position.x
	var source_2d: Node2D = source as Node2D
	if source_2d != null and is_instance_valid(source_2d):
		origin_x = source_2d.global_position.x
	return 1.0 if target_x >= origin_x else -1.0
