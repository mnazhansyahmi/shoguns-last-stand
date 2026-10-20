class_name TouchActionButton
extends Control
## Round touch button that holds an Input Map action while touched. Owns one touch index, so
## several buttons and the joystick can be held at once. Shows cooldown as a shrinking pie with
## the seconds left, and "unavailable" as a crossed-out button with a reason, not only color.

@export var action: StringName = &"attack"
@export var caption: String = ""
@export var sub_caption: String = ""
@export var base_color: Color = InkPalette.SAMURAI_RED
@export var font_size: int = 30

## Remaining cooldown as a fraction (1 = just used, 0 = ready).
var cooldown_ratio: float = 0.0
var cooldown_seconds: float = 0.0
var available: bool = true
var unavailable_text: String = ""
## Charge meter around the rim (0..1; 0 = no meter), for the Ultimate.
var charge_ratio: float = 0.0
## Pulses with a golden glow (the Ultimate is ready).
var glowing: bool = false
## The keyboard key of the action ("J", "Q", "1"), read from the Input Map and shown on a badge ("" = none).
var key_hint: String = ""
## A locked skill shows a padlock and how to unlock it ("Clear stage 2") instead of its name; "" = unlocked.
var locked_text: String = ""

var _touch_index: int = -1
var _press_physics_frame: int = -1
var _release_pending: bool = false


func _ready() -> void:
	set_physics_process(false)
	set_process(false)
	key_hint = SkillHints.key_label(action)
	_update_opacity()


## Marks the skill locked ("Clear stage 2") or, with "", unlocked. A tap on a locked button still reaches the
## player, who says which stage unlocks it.
func set_locked(text: String) -> void:
	if text == locked_text:
		return
	locked_text = text
	queue_redraw()


func is_locked() -> bool:
	return not locked_text.is_empty()


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


## Semi-transparent at rest so the battle shows through; fully opaque while pressed or glowing.
func _update_opacity() -> void:
	modulate.a = 1.0 if is_held() or glowing else TouchLayout.IDLE_OPACITY


## The charge meter around the rim; `ready` makes the button glow and pulse.
func set_charge(ratio: float, is_ready: bool) -> void:
	var new_ratio: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(new_ratio, charge_ratio) and is_ready == glowing:
		return
	charge_ratio = new_ratio
	if is_ready != glowing:
		glowing = is_ready
		set_process(glowing)
		_update_opacity()
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


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
	# Charcoal disc, the action's colour as a ring and wash, gold rim (docs/ART_BIBLE.md, UI).
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.009) if glowing else 0.0
	if glowing:
		# A pulsing golden halo around a ready button.
		draw_circle(center, radius * (1.1 + pulse * 0.08), Color(InkPalette.GOLD_BRIGHT, 0.18 + pulse * 0.22))
		draw_arc(center, radius * (1.04 + pulse * 0.05), 0.0, TAU, 64, Color(InkPalette.GOLD_BRIGHT, 0.5 + pulse * 0.4), 5.0, true)
	draw_circle(center, radius, Color(InkPalette.UI_CHARCOAL, 0.72))
	var fill: Color = base_color.lightened(0.2) if held else base_color
	fill.a = 0.55 if held else (0.3 + pulse * 0.3)
	draw_circle(center, radius * (0.86 if held else 0.9), fill)
	draw_arc(center, radius * 0.86, 0.0, TAU, 64, Color(base_color, 0.95), 5.0, true)
	if cooldown_ratio > 0.0:
		_draw_sector(center, radius * 0.92, cooldown_ratio, Color(InkPalette.INK, 0.7))
	if not available:
		var reach: float = radius * 0.62
		draw_line(center + Vector2(-reach, reach), center + Vector2(reach, -reach), Color(InkPalette.PARCHMENT, 0.6), 6.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, InkPalette.GOLD_BRIGHT if held else Color(InkPalette.GOLD, 0.9), 4.0 if held else 3.0, true)
	if charge_ratio > 0.0:
		# The meter: a bright arc from 12 o'clock clockwise on the rim.
		draw_arc(center, radius - 9.0, -PI * 0.5, -PI * 0.5 + TAU * charge_ratio, maxi(8, ceili(64.0 * charge_ratio)),
				Color(InkPalette.GOLD_BRIGHT, 0.95), 8.0, true)

	var font: Font = get_theme_default_font()
	var width: float = size.x
	if is_locked():
		_draw_locked(font, center, radius)
		_draw_key_badge(font, center, radius)
		return
	var main_y: float = center.y + font_size * 0.35 - (font_size * 0.55 if not sub_caption.is_empty() else 0.0)
	_draw_text(font, caption, Vector2(0.0, main_y), width, font_size)
	var bottom_text: String = sub_caption
	if cooldown_ratio > 0.0:
		bottom_text = "%.1fs" % cooldown_seconds
	elif not available and not unavailable_text.is_empty():
		bottom_text = unavailable_text
	if not bottom_text.is_empty():
		_draw_text(font, bottom_text, Vector2(0.0, main_y + font_size * 1.1), width, int(font_size * 0.8))
	_draw_key_badge(font, center, radius)


## A locked skill: the disc greyed out, a padlock and "Clear stage N" on two lines ("Clear" / "stage N").
func _draw_locked(font: Font, center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.9, Color(InkPalette.UI_CHARCOAL, 0.6))
	LockIcon.draw(self, center + Vector2(0.0, -radius * 0.3), radius * 0.62, Color(InkPalette.PARCHMENT, 0.9))
	var small: int = maxi(int(font_size * 0.62), 14)
	var words: PackedStringArray = locked_text.split(" ", true, 1)
	var first: String = words[0] if words.size() > 0 else ""
	var second: String = words[1] if words.size() > 1 else ""
	_draw_text(font, first, Vector2(0.0, center.y + radius * 0.42), size.x, small)
	_draw_text(font, second, Vector2(0.0, center.y + radius * 0.42 + small * 1.1), size.x, small)


## The key on a small badge at the top right of the rim, so the keyboard player learns it from the touch layout too.
func _draw_key_badge(font: Font, center: Vector2, radius: float) -> void:
	if key_hint.is_empty():
		return
	var badge_radius: float = maxf(radius * 0.24, 17.0)
	var at: Vector2 = center + Vector2(0.7071, -0.7071) * radius * 0.9
	draw_circle(at, badge_radius, Color(InkPalette.INK, 0.92))
	draw_arc(at, badge_radius, 0.0, TAU, 24, Color(InkPalette.GOLD_BRIGHT, 0.95), 2.5, true)
	var text_size: int = roundi(badge_radius * 1.15)
	draw_string(font, at + Vector2(-badge_radius, text_size * 0.35), key_hint, HORIZONTAL_ALIGNMENT_CENTER, badge_radius * 2.0, text_size, InkPalette.PARCHMENT)


func _draw_text(font: Font, text: String, origin: Vector2, width: float, text_size: int) -> void:
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, text_size, 6, Color(InkPalette.INK, 0.9))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, text_size, InkPalette.PARCHMENT)


## Pie slice for the remaining cooldown, starting at 12 o'clock.
func _draw_sector(center: Vector2, radius: float, ratio: float, color: Color) -> void:
	var steps: int = maxi(3, ceili(48.0 * ratio))
	var points: PackedVector2Array = PackedVector2Array([center])
	for i: int in steps + 1:
		var angle: float = -PI * 0.5 + TAU * ratio * float(i) / float(steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
