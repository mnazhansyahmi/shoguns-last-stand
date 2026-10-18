class_name HealthComponent
extends Node
## Hit points for any damageable entity. Emits `died` exactly once until reset().

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal died

## Setting this before the component is used also refills current health.
@export var max_health: float = 100.0:
	set(value):
		max_health = maxf(value, 1.0)
		current_health = max_health if not _started else minf(current_health, max_health)

var current_health: float = 100.0

var _started: bool = false
var _is_dead: bool = false
var _invulnerable_time_left: float = 0.0


func _ready() -> void:
	_started = true


func _process(delta: float) -> void:
	tick_invulnerability(delta)


## Applies damage and returns the amount actually removed (0 if ignored).
func take_damage(amount: float, source: Node = null) -> float:
	_started = true
	if _is_dead or amount <= 0.0 or is_invulnerable():
		return 0.0
	var applied: float = minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, source)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		current_health = 0.0
		_is_dead = true
		died.emit()
	return applied


## Restores health and returns the amount actually restored. Dead entities cannot be healed.
func heal(amount: float) -> float:
	_started = true
	if _is_dead or amount <= 0.0:
		return 0.0
	var applied: float = minf(amount, max_health - current_health)
	if applied <= 0.0:
		return 0.0
	current_health += applied
	healed.emit(applied)
	health_changed.emit(current_health, max_health)
	return applied


## Revives at full health and clears invulnerability.
func reset() -> void:
	_started = true
	_is_dead = false
	_invulnerable_time_left = 0.0
	current_health = max_health
	health_changed.emit(current_health, max_health)


func set_invulnerable_for(seconds: float) -> void:
	_invulnerable_time_left = maxf(_invulnerable_time_left, seconds)


func clear_invulnerability() -> void:
	_invulnerable_time_left = 0.0


func tick_invulnerability(delta: float) -> void:
	if _invulnerable_time_left > 0.0:
		_invulnerable_time_left = maxf(_invulnerable_time_left - delta, 0.0)


func is_invulnerable() -> bool:
	return _invulnerable_time_left > 0.0


func is_dead() -> bool:
	return _is_dead


func get_ratio() -> float:
	return current_health / max_health
