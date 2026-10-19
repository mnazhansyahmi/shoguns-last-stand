class_name BattleFeedback
extends Node
## Screen shake and phone vibration, both switchable in settings. Pauses with the tree.

@export var camera: Camera2D

var screen_shake_enabled: bool = true
var vibration_enabled: bool = true

var _strength: float = 0.0
var _duration: float = 0.0
var _time_left: float = 0.0


func configure(settings: GameSettings) -> void:
	screen_shake_enabled = settings.screen_shake
	vibration_enabled = settings.vibration
	if not screen_shake_enabled:
		_stop_shake()


func on_player_hit() -> void:
	shake(10.0, 0.22)
	vibrate(45)


func on_gate_hit() -> void:
	shake(5.0, 0.15)


func shake(strength: float, duration: float) -> void:
	if not screen_shake_enabled or duration <= 0.0:
		return
	_strength = maxf(_strength * (_time_left / maxf(_duration, 0.001)), strength)
	_duration = duration
	_time_left = duration


func vibrate(duration_ms: int) -> void:
	if vibration_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)


func is_shaking() -> bool:
	return _time_left > 0.0


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_stop_shake()
		return
	if is_instance_valid(camera):
		var falloff: float = _time_left / _duration
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * falloff


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_stop_shake()


func _stop_shake() -> void:
	_time_left = 0.0
	_strength = 0.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
