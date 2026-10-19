class_name EdgeIndicator
extends Control
## Points at something off screen in the zoomed battle view: the gate (left edge, with its
## health) or incoming enemies (right edge). A charcoal tab with an arrow toward the screen edge;
## it pulses ember while `alert` is on. Visual only, ignores input.

const TAB_SIZE: Vector2 = Vector2(240.0, 100.0)
const ARROW_DEPTH: float = 34.0
const PULSE_PERIOD: float = 0.6

## Arrow on the left side (points at the left edge) or the right side.
@export var points_left: bool = true

var title: String = ""
var detail: String = ""
## Health bar fill 0..1; negative = no bar.
var ratio: float = -1.0
var alert: bool = false

var _clock: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = TAB_SIZE
	visible = false


func show_info(p_title: String, p_detail: String, p_ratio: float, p_alert: bool) -> void:
	var changed: bool = not visible or p_title != title or p_detail != detail or p_alert != alert \
			or not is_equal_approx(p_ratio, ratio)
	title = p_title
	detail = p_detail
	ratio = p_ratio
	alert = p_alert
	visible = true
	if changed:
		queue_redraw()


func hide_info() -> void:
	visible = false


func _process(delta: float) -> void:
	if visible and alert:
		_clock += delta
		queue_redraw()


func _draw() -> void:
	var lit: bool = alert and fmod(_clock, PULSE_PERIOD) < PULSE_PERIOD * 0.5
	var accent: Color = InkPalette.EMBER_TEXT if lit else InkPalette.GOLD
	var body: Rect2 = Rect2(Vector2(ARROW_DEPTH if points_left else 0.0, 0.0), Vector2(size.x - ARROW_DEPTH, size.y))
	draw_rect(body, Color(InkPalette.UI_CHARCOAL, 0.88))
	draw_rect(body, accent, false, 3.0)
	var mid: float = size.y * 0.5
	var tip_x: float = 0.0 if points_left else size.x
	var base_x: float = ARROW_DEPTH if points_left else size.x - ARROW_DEPTH
	draw_colored_polygon(PackedVector2Array([Vector2(tip_x, mid), Vector2(base_x, mid - 26.0), Vector2(base_x, mid + 26.0)]), accent)

	var font: Font = get_theme_default_font()
	var left: float = body.position.x + 16.0
	var width: float = body.size.x - 32.0
	_text(font, title, Vector2(left, 36.0), width, 28, InkPalette.PARCHMENT)
	if not detail.is_empty():
		_text(font, detail, Vector2(left, 64.0), width, 22, InkPalette.EMBER_TEXT if alert else InkPalette.PARCHMENT_DIM)
	if ratio >= 0.0:
		var bar: Rect2 = Rect2(left, size.y - 22.0, width, 10.0)
		draw_rect(bar, Color(InkPalette.INK, 0.85))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(ratio, 0.0, 1.0), bar.size.y)), InkPalette.JADE)


func _text(font: Font, text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 6, Color(InkPalette.INK, 0.9))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
