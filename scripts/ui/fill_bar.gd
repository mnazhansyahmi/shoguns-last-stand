class_name FillBar
extends Control
## Horizontal bar: fill length plus "caption  value" text, so the value is readable without
## relying on color. Optional tick marks split the bar into segments.

@export var caption: String = ""
@export var fill_color: Color = Color(0.85, 0.25, 0.22)
@export var back_color: Color = Color(InkPalette.UI_CHARCOAL, 0.8)
@export var border_color: Color = Color(InkPalette.GOLD, 0.85)
@export var font_size: int = 26
## Number of segments marked with ticks (0 = none).
@export var segments: int = 0

var ratio: float = 1.0
var value_text: String = ""
## Pulses its fill and border (something the bar stands for is ready).
var pulsing: bool = false


func _ready() -> void:
	set_process(false)


func set_pulsing(enabled: bool) -> void:
	if enabled == pulsing:
		return
	pulsing = enabled
	set_process(enabled)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func set_value(current: float, maximum: float) -> void:
	set_ratio_text(current / maxf(maximum, 0.001), "%d / %d" % [ceili(current), roundi(maximum)])


func set_ratio_text(new_ratio: float, text: String) -> void:
	var clamped: float = clampf(new_ratio, 0.0, 1.0)
	if is_equal_approx(clamped, ratio) and text == value_text:
		return
	ratio = clamped
	value_text = text
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var glow: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.009) if pulsing else 0.0
	draw_rect(rect, back_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), fill_color.lerp(InkPalette.PAPER, glow * 0.4))
	if pulsing:
		draw_rect(rect.grow(3.0 + glow * 4.0), Color(InkPalette.GOLD_BRIGHT, 0.35 + glow * 0.5), false, 4.0)
	if segments > 1:
		for i: int in range(1, segments):
			var x: float = size.x * float(i) / float(segments)
			draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(InkPalette.INK, 0.5), 2.0)
	draw_rect(rect, border_color, false, 3.0)

	var font: Font = get_theme_default_font()
	var baseline: float = size.y * 0.5 + font_size * 0.35
	var padding: float = 12.0
	_draw_text(font, caption, Vector2(padding, baseline), size.x - padding * 2.0, HORIZONTAL_ALIGNMENT_LEFT)
	_draw_text(font, value_text, Vector2(padding, baseline), size.x - padding * 2.0, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_text(font: Font, text: String, origin: Vector2, width: float, alignment: HorizontalAlignment) -> void:
	if text.is_empty():
		return
	draw_string_outline(font, origin, text, alignment, width, font_size, 6, Color(InkPalette.INK, 0.9))
	draw_string(font, origin, text, alignment, width, font_size, InkPalette.PARCHMENT)
