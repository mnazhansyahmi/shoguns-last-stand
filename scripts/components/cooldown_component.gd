class_name CooldownComponent
extends Node
## Reusable attack/ability cooldown timer. Pauses with the scene tree.

signal cooldown_finished

@export var duration: float = 1.0

var time_left: float = 0.0


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		cooldown_finished.emit()


## Starts the cooldown. A negative `custom_duration` uses `duration`.
func start(custom_duration: float = -1.0) -> void:
	time_left = duration if custom_duration < 0.0 else custom_duration


func reset() -> void:
	time_left = 0.0


func is_available() -> bool:
	return time_left <= 0.0
