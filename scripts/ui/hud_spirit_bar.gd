class_name HudSpiritBar
extends HudGauge
## Spirit Energy: a small glowing spirit orb at the left, then a brush-edged ink bar with a blue fill, tick marks at every
## SEGMENTS-th of the way and the number at the right end ("137 / 600"). The ink flows: pale streaks drift along the
## fill, its leading edge ripples and the orb's swirl turns. Only that small "Flow" layer is redrawn each frame; the bar
## itself redraws when the energy changes.

const SEGMENTS: int = 5
const ORB_RADIUS: float = 15.0
const FONT_SIZE: int = 21
const STREAKS: int = 4

var _flow: Layer
## The parts that never change, built once per size: under the fill (plate, track) and over it (ticks, frame, orb).
var _back: InkBatch = InkBatch.new()
var _front: InkBatch = InkBatch.new()


func _ready() -> void:
	_flow = add_layer("Flow", _paint_flow)
	super()
	resized.connect(_build_shape)
	_build_shape()


func _is_animating() -> bool:
	return ratio > 0.0 and is_visible_in_tree()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_refresh_processing()


func _step(_delta: float) -> void:
	_flow.queue_redraw()


## Where the bar itself starts (right of the orb) and its rect.
func get_bar_rect() -> Rect2:
	var x0: float = ORB_RADIUS * 2.0 + 8.0
	return Rect2(x0, size.y * 0.2, size.x - x0, size.y * 0.6)


func _build_shape() -> void:
	var bar: Rect2 = get_bar_rect()
	var plate: PackedVector2Array = HudGauge.ragged_plate(bar.grow(4.0), 7331, 2.5)
	_back.clear()
	_back.fill(HudGauge.shifted(plate, Vector2(3.0, 4.0)), Color(InkPalette.INK, 0.4))
	_back.fill(plate, Color(InkPalette.INK, 0.92))
	_back.fill_convex(HudGauge.rect_points(bar), Color(InkPalette.SPIRIT_DEEP.darkened(0.7), 0.95))
	_front.clear()
	for i: int in range(1, SEGMENTS):
		var x: float = bar.position.x + bar.size.x * float(i) / float(SEGMENTS)
		_front.segment(Vector2(x, bar.position.y + 2.0), Vector2(x, bar.end.y - 2.0), 2.0, 2.0, Color(InkPalette.INK, 0.55))
	HudGauge.outline(_front, HudGauge.rect_points(bar), 1.5, Color(InkPalette.GOLD, 0.8))
	var orb: Vector2 = _orb_center()
	_front.disc(orb + Vector2(2.0, 3.0), ORB_RADIUS + 2.0, Color(InkPalette.INK, 0.4), 20)
	_front.disc(orb, ORB_RADIUS + 6.0, Color(InkPalette.SPIRIT, 0.16), 24)
	_front.disc(orb, ORB_RADIUS, InkPalette.SPIRIT_DEEP, 24)
	_front.disc(orb + Vector2(-3.0, -3.0), ORB_RADIUS * 0.55, Color(InkPalette.SPIRIT, 0.75), 16)
	queue_redraw()


func _orb_center() -> Vector2:
	return Vector2(ORB_RADIUS + 1.0, size.y * 0.5)


func _fill_end() -> float:
	var bar: Rect2 = get_bar_rect()
	return bar.position.x + bar.size.x * ratio


func _draw() -> void:
	var bar: Rect2 = get_bar_rect()
	_back.draw(self)
	if ratio > 0.0:
		var width: float = _fill_end() - bar.position.x
		_batch.clear()
		_batch.fill_convex(HudGauge.rect_points(Rect2(bar.position, Vector2(width, bar.size.y))), InkPalette.SPIRIT_DEEP)
		# A lighter band along the top: the fill reads as a rounded, lit tube.
		_batch.fill_convex(HudGauge.rect_points(Rect2(bar.position, Vector2(width, bar.size.y * 0.38))), Color(InkPalette.SPIRIT, 0.38))
		_batch.draw(self)
	_front.draw(self)
	draw_arc(_orb_center(), ORB_RADIUS, 0.0, TAU, 24, InkPalette.GOLD, 1.6, true)
	var baseline: float = bar.get_center().y + get_theme_default_font().get_ascent(FONT_SIZE) * 0.36
	draw_outlined(Vector2(bar.end.x - 10.0, baseline), value_text, FONT_SIZE, InkPalette.PAPER, true)


## The moving ink: streaks drifting along the fill, a ripple on its leading edge, the orb's turning swirl.
func _paint_flow(layer: CanvasItem) -> void:
	if ratio <= 0.0:
		return
	var bar: Rect2 = get_bar_rect()
	var fill_end: float = _fill_end()
	var span: float = fill_end - bar.position.x
	var flow: InkBatch = InkBatch.new()
	for i: int in STREAKS:
		var x: float = bar.position.x + fposmod(_clock * 70.0 + float(i) * span / float(STREAKS), maxf(span, 1.0))
		var y: float = bar.position.y + bar.size.y * (0.3 + 0.13 * float(i % 3))
		var length: float = minf(46.0, fill_end - x)
		if length > 4.0:
			flow.segment(Vector2(x, y), Vector2(x + length, y), 1.0, 2.6, Color(InkPalette.PAPER, 0.3))
	if ratio < 1.0:
		var ripple: PackedVector2Array = PackedVector2Array([Vector2(fill_end, bar.position.y)])
		for i: int in range(1, 6):
			var t: float = float(i) / 6.0
			ripple.append(Vector2(fill_end + absf(sin(_clock * 5.0 + t * 5.0)) * 3.5 * minf(ratio * 10.0, 1.0), bar.position.y + bar.size.y * t))
		ripple.append(Vector2(fill_end, bar.end.y))
		flow.fill(ripple, InkPalette.SPIRIT_DEEP)
	var orb: Vector2 = _orb_center()
	flow.stroke(HudGauge.arc_points(orb, ORB_RADIUS * 0.62, _clock * 2.0, _clock * 2.0 + PI * 1.1, 10), 2.0, 2.0, Color(InkPalette.PAPER, 0.7))
	flow.draw(layer)
