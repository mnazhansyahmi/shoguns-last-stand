class_name PlaceholderVisual
extends Node2D
## Placeholder animation interface built from Polygon2D shapes.
## Gameplay code only calls set_facing / play_state / flash_hit / set_blinking / set_tint,
## so real sprites or an AnimationPlayer can replace this script without touching combat logic.
## Expects an optional child "Rig" (flashed and posed) and "Rig/Weapon" (rotated).

const FLASH_COLOR: Color = Color(4.0, 4.0, 4.0, 1.0)
const FLASH_TIME: float = 0.15
const POSE_TIME: float = 0.06

@export var weapon_rest_angle: float = -0.9
@export var weapon_windup_angle: float = -2.3
@export var weapon_strike_angle: float = 0.5

var _rig: Node2D
var _weapon: Node2D
var _state: StringName = &""
var _base_tint: Color = Color.WHITE
var _blinking: bool = false
var _blink_clock: float = 0.0
var _bob_clock: float = 0.0
var _flash_tween: Tween
var _pose_tween: Tween
var _fx_tween: Tween


func _ready() -> void:
	_rig = get_node_or_null("Rig") as Node2D
	if _rig == null:
		_rig = self
	_weapon = get_node_or_null("Rig/Weapon") as Node2D
	if _weapon != null:
		_weapon.rotation = weapon_rest_angle


func _process(delta: float) -> void:
	if _state == &"run":
		_bob_clock += delta * 12.0
		_rig.position.y = -absf(sin(_bob_clock)) * 4.0
	elif _rig.position.y != 0.0:
		_rig.position.y = 0.0
	if _blinking:
		_blink_clock += delta
		modulate.a = 0.35 if fmod(_blink_clock, 0.12) < 0.06 else 1.0


func set_facing(direction: int) -> void:
	if direction != 0:
		scale.x = signf(direction)


func play_state(state: StringName) -> void:
	if state == _state:
		return
	_state = state
	match state:
		&"idle", &"run":
			_reset_rig()
			_pose_weapon(weapon_rest_angle)
		&"windup":
			_rig.scale = Vector2.ONE
			_pose_weapon(weapon_windup_angle)
		&"heavy_windup":
			_rig.scale = Vector2(1.08, 0.94)
			_pose_weapon(weapon_windup_angle - 0.5, 0.2)
		&"strike":
			_rig.scale = Vector2.ONE
			_pose_weapon(weapon_strike_angle, 0.04)
		&"cast":
			_pose_weapon(-1.6, 0.1)
		&"dash":
			_kill_tween(_fx_tween)
			modulate.a = 0.55
			_rig.scale = Vector2(1.25, 0.9)
		&"hurt":
			_rig.scale = Vector2.ONE
			_pose_weapon(weapon_rest_angle + 0.5)
		&"spawn":
			_kill_tween(_fx_tween)
			modulate.a = 0.0
			_fx_tween = create_tween()
			_fx_tween.tween_property(self, "modulate:a", 1.0, 0.4)
		&"dead":
			_blinking = false
			_kill_tween(_fx_tween)
			_fx_tween = create_tween().set_parallel(true)
			_fx_tween.tween_property(_rig, "rotation", -PI * 0.5, 0.3)
			_fx_tween.tween_property(self, "modulate:a", 0.5, 0.3)
		_:
			push_warning("PlaceholderVisual: unknown state '%s'." % state)


## Brief white flash so damage is visible.
func flash_hit() -> void:
	_kill_tween(_flash_tween)
	_rig.modulate = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_rig, "modulate", _base_tint, FLASH_TIME)


func set_blinking(enabled: bool) -> void:
	if enabled == _blinking:
		return
	_blinking = enabled
	if not enabled and _state != &"dead" and _state != &"dash":
		modulate.a = 1.0


func set_tint(color: Color) -> void:
	_base_tint = color
	_kill_tween(_flash_tween)
	_rig.modulate = color


func _reset_rig() -> void:
	_kill_tween(_fx_tween)
	_rig.rotation = 0.0
	_rig.scale = Vector2.ONE
	modulate = Color.WHITE


func _pose_weapon(angle: float, time: float = POSE_TIME) -> void:
	if _weapon == null:
		return
	_kill_tween(_pose_tween)
	_pose_tween = create_tween()
	_pose_tween.tween_property(_weapon, "rotation", angle, time)


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
