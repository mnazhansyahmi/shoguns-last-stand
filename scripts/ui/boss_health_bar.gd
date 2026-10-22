class_name BossHealthBar
extends FillBar
## Painted frame with live health, delayed drain and readable phase feedback.
const FRAME: Texture2D = preload("res://assets/art/boss_bar_frame.png")
const SOURCE: Rect2 = Rect2(0, 165, 2172, 390)
var title: String = "LORD OF THE BROKEN OATH"
var ghost_ratio: float = 1.0
var phase: int = 1
var _drain_delay: float = 0.0
var _phase_flash: float = 0.0
var _clock: float = 0.0
var shake_enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func reset_health() -> void:
	ratio = 1.0
	ghost_ratio = 1.0
	phase = 1
	_phase_flash = 0.0
	_drain_delay = 0.0


func set_ratio_text(new_ratio: float, text: String) -> void:
	if new_ratio < ratio: _drain_delay = 0.22
	if new_ratio > ratio: ghost_ratio = clampf(new_ratio, 0.0, 1.0)
	super(new_ratio, text)


func set_phase(value: int) -> void:
	if value == phase: return
	phase = value
	_phase_flash = 0.8
	queue_redraw()


func _process(delta: float) -> void:
	if not visible: return
	_clock += delta
	_drain_delay = maxf(0.0, _drain_delay - delta)
	if _drain_delay <= 0.0: ghost_ratio = move_toward(ghost_ratio, ratio, delta * 0.8)
	_phase_flash = maxf(0.0, _phase_flash - delta)
	queue_redraw()


func _draw() -> void:
	var pulse: float = _phase_flash / 0.8
	var offset: Vector2 = Vector2(sin(_clock * 75.0) * 4.0 * pulse, 0.0) if shake_enabled and not GameSettings.reduced_decorative_motion else Vector2.ZERO
	draw_set_transform(offset)
	var trough: Rect2 = Rect2(Vector2(size.x * 0.13, size.y * 0.54), Vector2(size.x * 0.74, size.y * 0.15))
	draw_rect(trough, Color(0.055, 0.009, 0.012, 0.98))
	draw_rect(Rect2(trough.position, Vector2(trough.size.x * ghost_ratio, trough.size.y)), Color(0.9, 0.48, 0.18, 0.8))
	var fill: Rect2 = Rect2(trough.position, Vector2(trough.size.x * ratio, trough.size.y))
	draw_rect(fill, Color(0.48, 0.035, 0.025))
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.28)), Color(0.91, 0.24, 0.065, 0.85))
	for tick: int in [1, 2]:
		var x: float = trough.position.x + trough.size.x * tick / 3.0
		draw_line(Vector2(x, trough.position.y), Vector2(x, trough.end.y), Color(0.06, 0.01, 0.01), 3.0)
		if pulse > 0.0: draw_circle(Vector2(x, trough.position.y + 8), 7 + pulse * 6, Color(1, 0.45, 0.1, pulse * 0.45))
	draw_texture_rect_region(FRAME, Rect2(Vector2.ZERO, size), SOURCE)
	if pulse > 0.0:
		draw_rect(trough.grow(3), Color(1.0, 0.4, 0.1, pulse * 0.6), false, 3.0)
	if ratio < 0.25:
		for side: float in [-1.0, 1.0]:
			var root: Vector2 = Vector2(size.x * (0.5 + side * 0.32), size.y * 0.64)
			draw_polyline(PackedVector2Array([root + Vector2(-7, -10), root, root + Vector2(-5, 10), root + Vector2(4, 19)]), Color(0.02, 0.01, 0.01, 0.95), 3.0, true)
	var font: Font = get_theme_default_font()
	var plate_left: float = size.x * 0.24
	var plate_width: float = size.x * 0.52
	draw_string(font, Vector2(plate_left, size.y * 0.27), title, HORIZONTAL_ALIGNMENT_CENTER, plate_width, 13, InkPalette.GOLD)
	draw_string_outline(font, Vector2(plate_left, size.y * 0.44), caption, HORIZONTAL_ALIGNMENT_CENTER, plate_width, 24, 4, InkPalette.INK)
	draw_string(font, Vector2(plate_left, size.y * 0.44), caption, HORIZONTAL_ALIGNMENT_CENTER, plate_width, 24, InkPalette.PARCHMENT)
	draw_string(font, Vector2(trough.position.x, size.y * 0.68), value_text, HORIZONTAL_ALIGNMENT_CENTER, trough.size.x, 17, InkPalette.PARCHMENT)
	draw_set_transform(Vector2.ZERO)
