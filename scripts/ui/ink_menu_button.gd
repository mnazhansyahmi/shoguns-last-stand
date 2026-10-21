class_name InkMenuButton
extends Button
## A main-menu button: one simple shape for all six, a dark panel with a thin gold border (and a faint inner trim line)
## under gold serif text. Its theme variation (MenuButtonPanel / MenuButtonPanelSub) strips the normal button boxes and
## sets the font and margins; this class draws the panel and the label so that, when the button is hovered or focused,
## the border brightens and a soft gold glow fades in around it (with a soft katana slash sound). An optional small line
## (`sub_caption`) sits inside the panel under the label. Keyboard, gamepad and touch use the ordinary Button behaviour.

const GLOW_TIME: float = 0.18
const CORNER: int = 4
const BORDER: int = 2
## The faint inner trim line sits this far inside the border.
const TRIM_INSET: float = 6.0
const SUB_CAPTION_SIZE: int = 26
## The small line's baseline sits this far above the bottom edge.
const SUB_CAPTION_BOTTOM: float = 20.0

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
var _panel: StyleBoxFlat = StyleBoxFlat.new()
var _trim: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	set_process(false)
	_panel.set_corner_radius_all(CORNER)
	_panel.set_border_width_all(BORDER)
	_panel.corner_detail = 4
	_trim.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	_trim.set_corner_radius_all(maxi(CORNER - 2, 0))
	_trim.set_border_width_all(1)
	mouse_entered.connect(_refresh_active)
	mouse_exited.connect(_refresh_active)
	focus_entered.connect(_refresh_active)
	focus_exited.connect(_refresh_active)
	get_tree().create_timer(0.35).timeout.connect(_arm)


func _arm() -> void:
	_armed = true


## 0 = at rest, 1 = border fully bright and glowing.
func get_glow() -> float:
	return _glow


## True while the button is hovered or focused.
func is_active() -> bool:
	return _target > 0.5


func _refresh_active() -> void:
	var active: bool = is_hovered() or has_focus()
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
	# At rest the panel casts a soft ink shadow; lit, that shadow becomes the gold glow around it.
	_panel.bg_color = Color(InkPalette.INK, 0.9).lerp(Color(InkPalette.UI_CHARCOAL, 0.94), lit)
	if pressed:
		_panel.bg_color = Color(InkPalette.UI_BUTTON_PRESSED, 0.96)
	_panel.border_color = Color(InkPalette.GOLD, 0.62).lerp(InkPalette.GOLD_BRIGHT, lit)
	_panel.shadow_color = Color(InkPalette.INK, 0.5).lerp(Color(InkPalette.GOLD_BRIGHT, 0.45), lit)
	_panel.shadow_size = roundi(lerpf(8.0, 22.0, lit))
	_panel.shadow_offset = Vector2(0.0, 4.0).lerp(Vector2.ZERO, lit)
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	_trim.border_color = Color(InkPalette.GOLD, 0.14 + 0.16 * lit)
	draw_style_box(_trim, Rect2(Vector2.ONE * TRIM_INSET, size - Vector2.ONE * TRIM_INSET * 2.0))
	_draw_label(lit, pressed)
	if not sub_caption.is_empty():
		var font: Font = get_theme_default_font()
		var left: float = get_theme_stylebox(&"normal").content_margin_left
		draw_string(font, Vector2(left, size.y - SUB_CAPTION_BOTTOM), sub_caption, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - left - 24.0, SUB_CAPTION_SIZE, Color(InkPalette.PARCHMENT_DIM, 0.95))


## The gold serif label, on top of the panel (the theme makes the button's own text invisible). Gold at rest, brighter
## when hovered or focused, paper white while pressed. It is centred in the space the margins leave, so with a small
## line under it the label sits in the upper part of the panel and never touches that line.
func _draw_label(lit: float, pressed: bool) -> void:
	var font: Font = get_theme_font(&"font")
	var font_size: int = get_theme_font_size(&"font_size")
	var margins: StyleBox = get_theme_stylebox(&"normal")
	var left: float = margins.content_margin_left
	var area_height: float = size.y - margins.content_margin_top - margins.content_margin_bottom
	var baseline: float = margins.content_margin_top + (area_height - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	var color: Color = InkPalette.GOLD.lerp(InkPalette.GOLD_BRIGHT, lit)
	if pressed:
		color = InkPalette.PAPER
	var width: float = size.x - left - margins.content_margin_right
	draw_string_outline(font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 6, Color(InkPalette.INK, 0.9))
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


func get_sub_caption_rect() -> Rect2:
	if sub_caption.is_empty():
		return Rect2()
	var font: Font = get_theme_default_font()
	var baseline: float = size.y - SUB_CAPTION_BOTTOM
	var width: float = font.get_string_size(sub_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, SUB_CAPTION_SIZE).x
	return Rect2(get_theme_stylebox(&"normal").content_margin_left, baseline - font.get_ascent(SUB_CAPTION_SIZE), width,
			font.get_height(SUB_CAPTION_SIZE))
