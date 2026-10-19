class_name TouchActionButton
extends Control
## Round touch button that holds an Input Map action while touched. Owns one touch index, so
## several buttons and the joystick can be held at once. Shows cooldown as a shrinking pie with
## the seconds left, and "unavailable" as a crossed-out button with a reason, not only color.

@export var action: StringName = &"attack"
@export var caption: String = ""
@export var sub_caption: String = ""
@export var base_color: Color = Color(0.75, 0.2, 0.18)
@export var font_size: int = 30

## Remaining cooldown as a fraction (1 = just used, 0 = ready).
var cooldown_ratio: float = 0.0
var cooldown_seconds: float = 0.0
var available: bool = true
var unavailable_text: String = ""

var _touch_index: int = -1
var _press_physics_frame: int = -1
var _release_pending: bool = false


func _ready() -> void:
	set_physics_process(false)
	_update_opacity()


## Returns true if the event belongs to this button.
func handle_touch(event: InputEvent) -> bool:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch == null:
		# Drags are kept by the owning finger; nothing to do.
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		return drag != null and drag.index == _touch_index
	if touch.pressed and _touch_index == -1 and _contains(touch.position):
		_touch_index = touch.index
		_release_pending = false
		_press_physics_frame = Engine.get_physics_frames()
		TouchInput.press(action)
		_update_opacity()
		queue_redraw()
		return true
	if not touch.pressed and touch.index == _touch_index:
		_touch_index = -1
		# A tap shorter than one physics tick would never be seen by just_pressed checks.
		if Engine.get_physics_frames() == _press_physics_frame:
			_release_pending = true
			set_physics_process(true)
		else:
			TouchInput.release(action)
		_update_opacity()
		queue_redraw()
		return true
	return false


func release() -> void:
	_touch_index = -1
	_release_pending = false
	set_physics_process(false)
	TouchInput.release(action)
	_update_opacity()
	queue_redraw()


func is_held() -> bool:
	return _touch_index != -1


## Semi-transparent at rest so the battle shows through; fully opaque while pressed.
func _update_opacity() -> void:
	modulate.a = 1.0 if is_held() else TouchLayout.IDLE_OPACITY


func set_cooldown(ratio: float, seconds: float) -> void:
	var new_ratio: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(new_ratio, cooldown_ratio) and is_equal_approx(seconds, cooldown_seconds):
		return
	cooldown_ratio = new_ratio
	cooldown_seconds = maxf(seconds, 0.0)
	queue_redraw()


func set_available(is_available: bool, reason: String = "") -> void:
	if is_available == available and reason == unavailable_text:
		return
	available = is_available
	unavailable_text = reason
	queue_redraw()


func set_captions(main: String, sub: String) -> void:
	if main == caption and sub == sub_caption:
		return
	caption = main
	sub_caption = sub
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _release_pending and Engine.get_physics_frames() > _press_physics_frame:
		_release_pending = false
		set_physics_process(false)
		TouchInput.release(action)


func _contains(point: Vector2) -> bool:
	var rect: Rect2 = get_global_rect()
	var radius: float = minf(rect.size.x, rect.size.y) * 0.5
	# Slightly generous hit area around the circle.
	return point.distance_to(rect.get_center()) <= radius * 1.08


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 4.0
	var held: bool = is_held()
	draw_circle(center, radius, Color(0.08, 0.06, 0.12, 0.55))
	var fill: Color = base_color.lightened(0.35) if held else base_color
	fill.a = 0.8 if held else 0.55
	draw_circle(center, radius * (0.86 if held else 0.92), fill)
	if cooldown_ratio > 0.0:
		_draw_sector(center, radius * 0.92, cooldown_ratio, Color(0.0, 0.0, 0.0, 0.65))
	if not available:
		var reach: float = radius * 0.62
		draw_line(center + Vector2(-reach, reach), center + Vector2(reach, -reach), Color(1.0, 1.0, 1.0, 0.6), 6.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.9), 4.0 if held else 3.0, true)

	var font: Font = get_theme_default_font()
	var width: float = size.x
	var main_y: float = center.y + font_size * 0.35 - (font_size * 0.55 if not sub_caption.is_empty() else 0.0)
	_draw_text(font, caption, Vector2(0.0, main_y), width, font_size)
	var bottom_text: String = sub_caption
	if cooldown_ratio > 0.0:
		bottom_text = "%.1fs" % cooldown_seconds
	elif not available and not unavailable_text.is_empty():
		bottom_text = unavailable_text
	if not bottom_text.is_empty():
		_draw_text(font, bottom_text, Vector2(0.0, main_y + font_size * 1.1), width, int(font_size * 0.8))


func _draw_text(font: Font, text: String, origin: Vector2, width: float, text_size: int) -> void:
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, text_size, 6, Color(0.0, 0.0, 0.0, 0.9))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, text_size, Color.WHITE)


## Pie slice for the remaining cooldown, starting at 12 o'clock.
func _draw_sector(center: Vector2, radius: float, ratio: float, color: Color) -> void:
	var steps: int = maxi(3, ceili(48.0 * ratio))
	var points: PackedVector2Array = PackedVector2Array([center])
	for i: int in steps + 1:
		var angle: float = -PI * 0.5 + TAU * ratio * float(i) / float(steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
