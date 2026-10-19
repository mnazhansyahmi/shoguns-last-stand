class_name TouchJoystick
extends Control
## Horizontal virtual joystick. Owns one touch index at a time, so other fingers stay free
## for the action buttons (multitouch). Drives move_left / move_right with analog strength.

@export var left_action: StringName = &"move_left"
@export var right_action: StringName = &"move_right"
## Fraction of the radius ignored around the center.
@export_range(0.0, 0.9) var dead_zone: float = 0.2

var _touch_index: int = -1
var _vector: Vector2 = Vector2.ZERO
var _sent_left: float = 0.0
var _sent_right: float = 0.0


func _ready() -> void:
	_update_opacity()


## Returns true if the event belongs to this joystick.
func handle_touch(event: InputEvent) -> bool:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _touch_index == -1 and _contains(touch.position):
			_touch_index = touch.index
			_update_opacity()
			_update_from(touch.position)
			return true
		if not touch.pressed and touch.index == _touch_index:
			release()
			return true
		return false
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null and drag.index == _touch_index:
		_update_from(drag.position)
		return true
	return false


func release() -> void:
	_touch_index = -1
	_vector = Vector2.ZERO
	_apply_actions()
	_update_opacity()
	queue_redraw()


func is_held() -> bool:
	return _touch_index != -1


## Semi-transparent at rest so the battle shows through; fully opaque while held.
func _update_opacity() -> void:
	modulate.a = 1.0 if is_held() else TouchLayout.IDLE_OPACITY


func get_vector() -> Vector2:
	return _vector


func _contains(point: Vector2) -> bool:
	return get_global_rect().has_point(point)


func _update_from(point: Vector2) -> void:
	var rect: Rect2 = get_global_rect()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.5
	_vector = ((point - rect.get_center()) / maxf(radius, 1.0)).limit_length(1.0)
	_apply_actions()
	queue_redraw()


func _apply_actions() -> void:
	var x: float = _vector.x
	if absf(x) < dead_zone:
		x = 0.0
	else:
		x = signf(x) * (absf(x) - dead_zone) / (1.0 - dead_zone)
	_send(left_action, maxf(-x, 0.0), true)
	_send(right_action, maxf(x, 0.0), false)


func _send(action: StringName, strength: float, is_left: bool) -> void:
	var previous: float = _sent_left if is_left else _sent_right
	if is_equal_approx(previous, strength):
		return
	if strength > 0.0:
		TouchInput.press(action, strength)
	else:
		TouchInput.release(action)
	if is_left:
		_sent_left = strength
	else:
		_sent_right = strength


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(center, radius, Color(0.08, 0.06, 0.12, 0.45))
	draw_arc(center, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.8), 4.0, true)
	draw_arc(center, radius * dead_zone, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.25), 2.0, true)
	# Direction arrows: the shape shows what the stick does, not just color.
	for side: float in [-1.0, 1.0]:
		var tip: Vector2 = center + Vector2(side * radius * 0.82, 0.0)
		var back: Vector2 = center + Vector2(side * radius * 0.62, 0.0)
		draw_colored_polygon(PackedVector2Array([tip, back + Vector2(0.0, -radius * 0.14),
				back + Vector2(0.0, radius * 0.14)]), Color(1.0, 1.0, 1.0, 0.55))
	var knob_radius: float = radius * 0.4
	var knob_center: Vector2 = center + _vector * (radius - knob_radius)
	draw_circle(knob_center, knob_radius, Color(0.85, 0.9, 1.0, 0.85 if is_held() else 0.6))
	draw_arc(knob_center, knob_radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.95), 3.0, true)
