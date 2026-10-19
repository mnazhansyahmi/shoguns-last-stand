class_name VillageGate
extends Node2D
## The village gate enemies try to destroy. Reaching 0 HP emits `destroyed` (defeat).

signal destroyed
signal health_changed(current: float, maximum: float)

@export var max_health: float = 1000.0
## Distance from the gate's origin to its right-hand face, where enemies stop to attack.
@export var front_offset: float = 90.0

@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _visual: GateVisual = $Visual
@onready var _health_bar: WorldHealthBar = $HealthBar

var _destroyed: bool = false
var _shake_tween: Tween


func _ready() -> void:
	add_to_group("gate")
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_health.max_health = max_health
	_health.reset()


func get_front_x() -> float:
	return global_position.x + front_offset


func is_targetable() -> bool:
	return not _destroyed


func is_destroyed() -> bool:
	return _destroyed


func get_health() -> HealthComponent:
	return _health


func _on_hit_received(_hit: HitData) -> void:
	_visual.flash_hit()
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_visual.position = Vector2.ZERO
	_shake_tween = create_tween()
	_shake_tween.tween_property(_visual, "position:x", -6.0, 0.04)
	_shake_tween.tween_property(_visual, "position:x", 4.0, 0.04)
	_shake_tween.tween_property(_visual, "position:x", 0.0, 0.04)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.set_values(current, maximum)
	_visual.set_damage(1.0 - current / maxf(maximum, 0.001))
	health_changed.emit(current, maximum)


func _on_died() -> void:
	_destroyed = true
	_hurtbox.set_enabled(false)
	_visual.set_destroyed()
	destroyed.emit()
