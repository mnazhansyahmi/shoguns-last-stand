class_name InkMenuButton
extends Button
## Title navigation: one crimson brush for the primary action, quieter parchment rows
## for the rest. Full-size native Button hit areas and focus behaviour are retained.

const GLOW_TIME: float = 0.18
const BORDER: int = 2
const SUB_CAPTION_SIZE: int = 26
## The small line's baseline sits this far above the bottom edge.
const SUB_CAPTION_BOTTOM: float = 20.0
## The focus chevron occupies the right-hand 39 pixels; text must stop before it.
const TRAILING_SPACE: float = 56.0

@export var primary: bool = false

## The small line under the label ("Stage 3 - Misty Grove"); "" for none. Use the MenuButtonPanelSub variation for a
## button that has one, so the label leaves room for it.
var sub_caption: String = "":
	set(value):
		sub_caption = value
		queue_redraw()

var _glow: float = 0.0
var _target: float = 0.0
## The slash sound is only played once the menu has been up a moment (the first focus when it opens is silent).
var _armed: bool = false


func _ready() -> void:
	set_process(false)
	mouse_entered.connect(_refresh_active)
	mouse_exited.connect(_refresh_active)
	focus_entered.connect(_refresh_active)
	focus_exited.connect(_refresh_active)
	get_tree().create_timer(0.35).timeout.connect(_arm)


func _arm() -> void:
	_armed = true


## 0 = at rest, 1 = focused/hovered highlight fully visible.
func get_glow() -> float:
	return _glow


## True while the button is hovered or focused.
func is_active() -> bool:
	return _target > 0.5


func _refresh_active() -> void:
	var active: bool = not disabled and (is_hovered() or has_focus())
	var was_active: bool = _target > 0.5
	_target = 1.0 if active else 0.0
	if active and not was_active and _armed:
		AudioManager.play(&"menu_hover", 1.3)
	set_process(true)


func _process(delta: float) -> void:
	_glow = move_toward(_glow, _target, delta / GLOW_TIME)
	queue_redraw()
	if is_equal_approx(_glow, _target):
		set_process(false)


func _draw() -> void:
	var lit: float = ease(_glow, -2.0)
	var pressed: bool = is_pressed()
	if primary:
		var ink: Color = InkPalette.CRIMSON.darkened(0.25).lerp(InkPalette.CRIMSON, lit)
		if pressed:
			ink = InkPalette.CRIMSON.darkened(0.45)
		if disabled:
			ink = InkPalette.UI_BUTTON
		draw_colored_polygon(PackedVector2Array([Vector2(8.0, 14.0), Vector2(size.x - 12.0, 10.0),
				Vector2(size.x - 3.0, 26.0), Vector2(size.x - 11.0, size.y - 14.0),
				Vector2(5.0, size.y - 10.0), Vector2(0.0, size.y - 28.0)]), Color(ink, 0.96))
		draw_line(Vector2(22.0, size.y - 11.0), Vector2(size.x - 25.0, size.y - 14.0),
				Color(InkPalette.GOLD, 0.45 + lit * 0.35), 1.0, true)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(8.0, 18.0), Vector2(size.x - 8.0, 18.0),
				Vector2(size.x - 8.0, size.y - 18.0), Vector2(8.0, size.y - 18.0)]), Color(InkPalette.GOLD, 0.055 * lit))
		draw_line(Vector2(40.0, size.y - 12.0), Vector2(size.x - 30.0, size.y - 12.0),
				Color(InkPalette.GOLD, 0.12 + lit * 0.18), 1.0, true)
	if lit > 0.0:
		var middle: float = size.y * 0.5
		var color: Color = Color(InkPalette.GOLD_BRIGHT, lit)
		draw_colored_polygon(PackedVector2Array([Vector2(13.0, middle - 5.0), Vector2(18.0, middle),
				Vector2(13.0, middle + 5.0), Vector2(8.0, middle)]), color)
		draw_polyline(PackedVector2Array([Vector2(size.x - 39.0, middle - 7.0),
				Vector2(size.x - 30.0, middle), Vector2(size.x - 39.0, middle + 7.0)]), color, 2.0, true)
	_draw_label(lit, pressed)
	if not sub_caption.is_empty():
		var font: Font = get_theme_default_font()
		var left: float = get_theme_stylebox(&"normal").content_margin_left
		draw_string(font, Vector2(left, size.y - SUB_CAPTION_BOTTOM), sub_caption, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - left - 24.0, SUB_CAPTION_SIZE, Color(InkPalette.PARCHMENT_DIM, 0.95))


## The theme hides native text; draw parchment type here, warming to gold on focus.
## Continue's bottom margin reserves its separate saved-stage caption.
func _draw_label(lit: float, pressed: bool) -> void:
	var font: Font = get_theme_font(&"font")
	var font_size: int = get_theme_font_size(&"font_size")
	var margins: StyleBox = get_theme_stylebox(&"normal")
	var left: float = margins.content_margin_left
	var area_height: float = size.y - margins.content_margin_top - margins.content_margin_bottom
	var baseline: float = margins.content_margin_top + (area_height - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	var color: Color = InkPalette.PARCHMENT.lerp(InkPalette.GOLD_BRIGHT, lit)
	if primary:
		color = InkPalette.PAPER
	if pressed:
		color = InkPalette.PAPER
	if disabled:
		color = InkPalette.UI_DISABLED
	var width: float = size.x - left - maxf(margins.content_margin_right, TRAILING_SPACE)
	draw_string_outline(font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 2, Color(InkPalette.INK, 0.7))
	draw_string(font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)


## The label's box (where `_draw_label` puts the text) and the small line's, in the button's own space: tests check they
## stay apart and inside the panel.
func get_label_rect() -> Rect2:
	var font: Font = get_theme_font(&"font")
	var font_size: int = get_theme_font_size(&"font_size")
	var margins: StyleBox = get_theme_stylebox(&"normal")
	var area_height: float = size.y - margins.content_margin_top - margins.content_margin_bottom
	var top: float = margins.content_margin_top + (area_height - font.get_height(font_size)) * 0.5
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return Rect2(margins.content_margin_left, top, width, font.get_height(font_size))


func minimum_label_width() -> float:
	var label: Rect2 = get_label_rect()
	return label.end.x + TRAILING_SPACE


func get_sub_caption_rect() -> Rect2:
	if sub_caption.is_empty():
		return Rect2()
	var font: Font = get_theme_default_font()
	var baseline: float = size.y - SUB_CAPTION_BOTTOM
	var width: float = font.get_string_size(sub_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, SUB_CAPTION_SIZE).x
	return Rect2(get_theme_stylebox(&"normal").content_margin_left, baseline - font.get_ascent(SUB_CAPTION_SIZE), width,
			font.get_height(SUB_CAPTION_SIZE))
