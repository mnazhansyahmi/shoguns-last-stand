class_name HudGateBar
extends HudGauge
## The village gate's health: a small ink gate icon (roof beam, posts, doors, gold trim) and a short brush-edged bar,
## jade while it stands, with the number on it. A hit flashes the bar red for a moment.

const ICON_WIDTH: float = 32.0
const FONT_SIZE: int = 19
const FLASH_TIME: float = 0.45

var _flash: float = 0.0
## The parts that never change, built once per size: under the fill (plate, track) and over it (frame, gate icon).
var _back: InkBatch = InkBatch.new()
var _front: InkBatch = InkBatch.new()


func _ready() -> void:
	super()
	resized.connect(_build_shape)
	_build_shape()


func _is_animating() -> bool:
	return _flash > 0.0


func _on_ratio_changed(old: float, new: float) -> void:
	if new < old:
		_flash = 1.0


func _step(delta: float) -> void:
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	queue_redraw()


func get_bar_rect() -> Rect2:
	var x0: float = ICON_WIDTH + 8.0
	return Rect2(x0, size.y * 0.18, size.x - x0, size.y * 0.64)


func _build_shape() -> void:
	var bar: Rect2 = get_bar_rect()
	var plate: PackedVector2Array = HudGauge.ragged_plate(bar.grow(4.0), 4242, 2.2, 8)
	_back.clear()
	_back.fill(HudGauge.shifted(plate, Vector2(3.0, 4.0)), Color(InkPalette.INK, 0.4))
	_back.fill(plate, Color(InkPalette.INK, 0.92))
	_back.fill_convex(HudGauge.rect_points(bar), Color(InkPalette.JADE.darkened(0.8), 0.95))
	_front.clear()
	HudGauge.outline(_front, HudGauge.rect_points(bar), 1.5, Color(InkPalette.GOLD, 0.8))
	_batch_gate_icon(_front, Rect2(Vector2.ZERO, Vector2(ICON_WIDTH, size.y)))
	queue_redraw()


func _draw() -> void:
	var bar: Rect2 = get_bar_rect()
	_back.draw(self)
	_batch.clear()
	if ratio > 0.0:
		var fill: Rect2 = Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y))
		_batch.fill_convex(HudGauge.rect_points(fill), InkPalette.JADE.darkened(0.38).lerp(InkPalette.SAMURAI_RED, _flash * 0.7))
		_batch.fill_convex(HudGauge.rect_points(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.36))), Color(InkPalette.PAPER, 0.16))
	if _flash > 0.0:
		HudGauge.outline(_batch, HudGauge.rect_points(bar.grow(2.0)), 3.0, Color(InkPalette.SAMURAI_RED, _flash * 0.8))
	_batch.draw(self)
	_front.draw(self)
	var baseline: float = bar.get_center().y + get_theme_default_font().get_ascent(FONT_SIZE) * 0.36
	draw_outlined(Vector2(bar.end.x - 8.0, baseline), value_text, FONT_SIZE, InkPalette.PAPER, true)


## A small village gate in ink with gold trim: a curved roof beam over two posts, a tie beam, and two dark doors.
static func _batch_gate_icon(batch: InkBatch, area: Rect2) -> void:
	var w: float = area.size.x
	var h: float = area.size.y
	var ink: Color = Color(InkPalette.INK, 0.96)
	var trim: Color = InkPalette.GOLD
	var roof: PackedVector2Array = PackedVector2Array([Vector2(-2.0, h * 0.2), Vector2(w * 0.5, h * 0.08), Vector2(w + 2.0, h * 0.2),
			Vector2(w - 1.0, h * 0.32), Vector2(1.0, h * 0.32)])
	batch.fill(roof, ink)
	HudGauge.outline(batch, roof, 1.4, trim)
	for post: Rect2 in [Rect2(w * 0.12, h * 0.3, w * 0.16, h * 0.64), Rect2(w * 0.72, h * 0.3, w * 0.16, h * 0.64)]:
		batch.fill_convex(HudGauge.rect_points(post), ink)
		HudGauge.outline(batch, HudGauge.rect_points(post), 1.2, trim)
	batch.fill_convex(HudGauge.rect_points(Rect2(w * 0.12, h * 0.4, w * 0.76, h * 0.07)), trim)
	var doors: Rect2 = Rect2(w * 0.28, h * 0.46, w * 0.44, h * 0.48)
	batch.fill_convex(HudGauge.rect_points(doors), Color(InkPalette.INK_DETAIL, 0.95))
	batch.segment(Vector2(w * 0.5, doors.position.y), Vector2(w * 0.5, doors.end.y), 1.0, 1.0, trim)
