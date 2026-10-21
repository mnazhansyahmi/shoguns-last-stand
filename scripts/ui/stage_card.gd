class_name StageCard
extends Control
## One stage on the stage select: a picture of the stage's own atmosphere (StagePreview), its number and name and a one-line
## description. A cleared stage wears a gold check mark in the corner; a locked one has a dark picture with a padlock and
## "Clear <previous stage>"; the boss stage has a small boss crest. The selected card has a bright gold frame; the full
## details (waves, enemies, gold) are shown in the screen's side panel, not here.
## Input: focusing it (keyboard, gamepad) or clicking / tapping it selects it; Enter / the confirm button or a double click
## "activates" it (starts the stage). Selecting and activating are separate so a tap can read the details before playing.

signal selected(card: StageCard)
signal activated(card: StageCard)

const CARD_SIZE: Vector2 = Vector2(380.0, 312.0)
const PICTURE_HEIGHT: float = 214.0
const BADGE_RADIUS: float = 22.0
const NAME_SIZE: int = 30
const LINE_SIZE: int = 22

var stage: StageData
## 0-based position in the region.
var index: int = 0
## The stage's number in the campaign (stage 6 is the Burning Village's first); 0 = index + 1.
var number: int = 0
var unlocked: bool = true
var cleared: bool = false
## "Clear The Village Gate" on a locked card.
var locked_text: String = ""
var is_selected: bool = false:
	set(value):
		is_selected = value
		if _face != null:
			_face.queue_redraw()

var _preview: StagePreview
var _face: Control
var _hovered: bool = false


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(p_stage: StageData, p_index: int, p_unlocked: bool, p_cleared: bool, p_locked_text: String, p_number: int = 0) -> void:
	stage = p_stage
	index = p_index
	unlocked = p_unlocked
	cleared = p_cleared
	locked_text = p_locked_text
	number = p_number
	name = "Card%d" % (p_index + 1)
	if _preview != null:
		_preview.setup(stage.atmosphere)
	if _face != null:
		_face.queue_redraw()


func _ready() -> void:
	_preview = StagePreview.new()
	_preview.name = "Picture"
	_preview.position = Vector2.ZERO
	_preview.size = Vector2(CARD_SIZE.x, PICTURE_HEIGHT)
	add_child(_preview)
	_face = Control.new()
	_face.name = "Face"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face.draw.connect(_draw_face)
	add_child(_face)
	if stage != null:
		_preview.setup(stage.atmosphere)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_face.queue_redraw)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	resized.connect(_on_resized)


func _on_resized() -> void:
	if _preview != null:
		_preview.size = Vector2(size.x, minf(PICTURE_HEIGHT, size.y))
	if _face != null:
		_face.queue_redraw()


func _on_focus_entered() -> void:
	selected.emit(self)
	_face.queue_redraw()


func _on_hover(hovered: bool) -> void:
	_hovered = hovered
	_face.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		accept_event()
		if unlocked:
			activated.emit(self)
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		grab_focus()
		selected.emit(self)
		if click.double_click and unlocked:
			activated.emit(self)


## The number on the badge: the campaign number, or the position in the region.
func get_number() -> int:
	return number if number > 0 else index + 1


## The text on the locked picture and in the details panel's lock line.
func get_locked_text() -> String:
	return locked_text if not unlocked else ""


func _draw_face() -> void:
	var serif: Font = get_theme_font(&"font", &"HeaderLabel")
	var plain: Font = get_theme_default_font()
	var width: float = size.x
	var picture: Rect2 = Rect2(0.0, 0.0, width, minf(PICTURE_HEIGHT, size.y))
	# The text band under the picture.
	_face.draw_rect(Rect2(0.0, picture.end.y, width, size.y - picture.end.y), Color(InkPalette.UI_CHARCOAL, 0.97))
	# A darker foot on the picture so the number badge and the stage name sit well.
	_face.draw_rect(Rect2(0.0, picture.end.y - 46.0, width, 46.0), Color(InkPalette.INK, 0.28))
	if not unlocked:
		_face.draw_rect(picture, Color(InkPalette.INK, 0.66))
		LockIcon.draw(_face, picture.get_center() + Vector2(0.0, -20.0), 84.0, Color(InkPalette.PARCHMENT, 0.9))
		_draw_centered(plain, locked_text, picture.get_center().y + 58.0, 24, InkPalette.PARCHMENT, width - 24.0)
	# Number badge on the edge between picture and text.
	var badge_center: Vector2 = Vector2(36.0, picture.end.y)
	_face.draw_circle(badge_center, BADGE_RADIUS + 3.0, Color(InkPalette.INK, 0.95))
	_face.draw_circle(badge_center, BADGE_RADIUS, InkPalette.GOLD if unlocked else InkPalette.UI_DISABLED)
	_draw_centered_at(serif, str(get_number()), badge_center + Vector2(0.0, 11.0), 30, InkPalette.INK)
	# Name and the one line.
	var name_color: Color = InkPalette.GOLD_BRIGHT if unlocked else InkPalette.UI_DISABLED
	var title: String = stage.display_name if stage != null else ""
	_face.draw_string_outline(serif, Vector2(72.0, picture.end.y + 38.0), title, HORIZONTAL_ALIGNMENT_LEFT, width - 84.0, NAME_SIZE, 6, Color(InkPalette.INK, 0.9))
	_face.draw_string(serif, Vector2(72.0, picture.end.y + 38.0), title, HORIZONTAL_ALIGNMENT_LEFT, width - 84.0, NAME_SIZE, name_color)
	var line: TextLine = TextLine.new()
	line.add_string(stage.short_description() if stage != null else "", plain, LINE_SIZE)
	line.width = width - 32.0
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.draw(_face.get_canvas_item(), Vector2(18.0, picture.end.y + 52.0), InkPalette.PARCHMENT_DIM if unlocked else Color(InkPalette.UI_DISABLED, 0.9))
	# Corner badges: the gold check mark of a cleared stage, the crest of a boss stage.
	if cleared:
		_draw_check(Vector2(width - 34.0, 34.0))
	if stage != null and stage.has_boss():
		draw_boss_crest(_face, Vector2(34.0, 34.0), BADGE_RADIUS)
	# The frame: bright gold when selected (or focused), thin gold otherwise.
	var frame: Color = Color(InkPalette.GOLD, 0.55)
	var frame_width: float = 2.0
	if is_selected or has_focus():
		frame = InkPalette.GOLD_BRIGHT
		frame_width = 5.0
	elif _hovered:
		frame = Color(InkPalette.GOLD_BRIGHT, 0.85)
		frame_width = 3.0
	_face.draw_rect(Rect2(Vector2.ZERO, size), frame, false, frame_width)


func _draw_centered(font: Font, text: String, baseline: float, font_size: int, color: Color, max_width: float) -> void:
	_face.draw_string_outline(font, Vector2((size.x - max_width) * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, max_width, font_size, 6, Color(InkPalette.INK, 0.95))
	_face.draw_string(font, Vector2((size.x - max_width) * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, max_width, font_size, color)


func _draw_centered_at(font: Font, text: String, baseline_center: Vector2, font_size: int, color: Color) -> void:
	_face.draw_string(font, Vector2(baseline_center.x - 30.0, baseline_center.y), text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, font_size, color)


## A gold disc with a dark check mark.
func _draw_check(center: Vector2) -> void:
	_face.draw_circle(center, BADGE_RADIUS + 3.0, Color(InkPalette.INK, 0.95))
	_face.draw_circle(center, BADGE_RADIUS, InkPalette.GOLD_BRIGHT)
	_face.draw_polyline(PackedVector2Array([center + Vector2(-10.0, 0.0), center + Vector2(-3.0, 8.0), center + Vector2(11.0, -8.0)]), InkPalette.INK, 5.0, true)


## A small boss crest: a dark disc with a gold ring and the horned crest of a kabuto (two upswept horns and a centre blade).
static func draw_boss_crest(ci: CanvasItem, center: Vector2, radius: float) -> void:
	ci.draw_circle(center, radius + 3.0, Color(InkPalette.INK, 0.95))
	ci.draw_circle(center, radius, Color(InkPalette.INK.lightened(0.08), 1.0))
	ci.draw_arc(center, radius - 1.5, 0.0, TAU, 28, InkPalette.GOLD_BRIGHT, 2.5, true)
	var s: float = radius / 22.0
	for side: float in [-1.0, 1.0]:
		ci.draw_polyline(PackedVector2Array([center + Vector2(side * 3.0 * s, 8.0 * s), center + Vector2(side * 9.0 * s, 4.0 * s),
				center + Vector2(side * 13.0 * s, -4.0 * s), center + Vector2(side * 12.0 * s, -12.0 * s)]), InkPalette.GOLD_BRIGHT, 3.2 * s, true)
	ci.draw_colored_polygon(PackedVector2Array([center + Vector2(-2.5 * s, 8.0 * s), center + Vector2(0.0, -12.0 * s), center + Vector2(2.5 * s, 8.0 * s)]), InkPalette.SAMURAI_RED)
