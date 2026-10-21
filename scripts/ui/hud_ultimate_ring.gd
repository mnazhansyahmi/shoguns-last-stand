class_name HudUltimateRing
extends HudGauge
## The samurai's round portrait medallion with the Ultimate meter as a ring around it. The portrait is the real in-game
## figure (an InkFigure rendered once into a SubViewport, head and shoulders against the moon on a crimson dusk) cut to a
## circle. The ring fills gold clockwise from the top as the meter charges; when it is READY the ring turns bright gold,
## a gold halo glows and pulses round the medallion and a READY plate sits on its foot (otherwise the plate shows the
## charge, "42%"). The key badge ("I") sits on the ring. `danger` (low health) makes the inner rim pulse red with the
## health blade. The halo and the red rim are layers faded with modulate, so pulsing never redraws the medallion.

const PORTRAIT_PX: int = 192
## Radii as fractions of half the control's width: the portrait, the ring's centre line, the outer trim.
const PORTRAIT_R: float = 0.78
const RING_R: float = 0.885
const RING_WIDTH: float = 0.11
const OUTER_R: float = 0.96
const PLATE_FONT_SIZE: int = 20
const CIRCLE_POINTS: int = 48

## Low health: the inner rim pulses red.
var danger: bool = false:
	set(value):
		if value == danger:
			return
		danger = value
		if _danger_layer != null:
			_danger_layer.visible = value
		_refresh_processing()

var _viewport: SubViewport
var _figure: InkFigure
var _glow_layer: Layer
var _danger_layer: Layer
## Built once per size: the medallion under the portrait (shadow, ink disc, the dusk and moon), the portrait circle,
## and the ring's dark track.
var _back: InkBatch = InkBatch.new()
var _track: InkBatch = InkBatch.new()
var _portrait_points: PackedVector2Array = PackedVector2Array()
var _portrait_uvs: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	_build_portrait()
	_glow_layer = add_layer("Glow", _paint_glow)
	_glow_layer.visible = false
	_danger_layer = add_layer("Danger", _paint_danger)
	_danger_layer.visible = danger
	super()
	resized.connect(_build_shape)
	_build_shape()


## The SubViewport the portrait is rendered into (its figure is the samurai's own InkFigure).
func get_portrait_viewport() -> SubViewport:
	return _viewport


func get_portrait_figure() -> InkFigure:
	return _figure


func _is_animating() -> bool:
	return pulsing or danger


func _on_pulsing_changed() -> void:
	if _glow_layer != null:
		_glow_layer.visible = pulsing


func _step(_delta: float) -> void:
	if pulsing:
		_glow_layer.modulate.a = 0.35 + 0.65 * _pulse(1.1)
	if danger:
		_danger_layer.modulate.a = 0.3 + 0.7 * _pulse(1.6)


## The samurai in his idle pose, large enough that his head and shoulders fill the circle, facing right toward the blade.
func _build_portrait() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Portrait"
	_viewport.size = Vector2i(PORTRAIT_PX, PORTRAIT_PX)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_figure = InkFigure.new()
	_figure.kind = InkFigure.Kind.SAMURAI
	_figure.height = float(PORTRAIT_PX) * 1.45
	_figure.position = Vector2(float(PORTRAIT_PX) * 0.44, float(PORTRAIT_PX) * 1.66)
	_viewport.add_child(_figure)
	add_child(_viewport)
	_figure.refresh()


func _center() -> Vector2:
	return size * 0.5


func _build_shape() -> void:
	var half: float = size.x * 0.5
	var center: Vector2 = _center()
	var radius: float = half * PORTRAIT_R
	_back.clear()
	_back.disc(center + Vector2(3.0, 5.0), half * OUTER_R + 2.0, Color(InkPalette.INK, 0.45), CIRCLE_POINTS)
	_back.disc(center, half * OUTER_R, InkPalette.INK, CIRCLE_POINTS)
	# The portrait's dusk: crimson, a warm glow low down, the moon behind his head.
	_back.disc(center, radius, InkPalette.SAMURAI_RED.darkened(0.62), CIRCLE_POINTS)
	_back.disc(center + Vector2(0.0, radius * 0.35), radius * 0.8, Color(InkPalette.HATAMOTO_ORANGE.darkened(0.45), 0.55), 32)
	_back.disc(center + Vector2(radius * 0.08, -radius * 0.3), radius * 0.48, Color(InkPalette.MOON, 0.85), 32)
	_portrait_points.clear()
	_portrait_uvs.clear()
	for i: int in CIRCLE_POINTS:
		var direction: Vector2 = Vector2.from_angle(TAU * float(i) / float(CIRCLE_POINTS))
		_portrait_points.append(center + direction * radius)
		_portrait_uvs.append(Vector2(0.5, 0.5) + direction * 0.5)
	_track.clear()
	var ring_width: float = half * RING_WIDTH
	_track.stroke(HudGauge.arc_points(center, half * RING_R, 0.0, TAU, CIRCLE_POINTS), ring_width, ring_width, InkPalette.INK_BACK)
	queue_redraw()
	if _glow_layer != null:
		_glow_layer.queue_redraw()
		_danger_layer.queue_redraw()


func _draw() -> void:
	var half: float = size.x * 0.5
	var center: Vector2 = _center()
	_back.draw(self)
	if _viewport != null:
		draw_colored_polygon(_portrait_points, Color.WHITE, _portrait_uvs, _viewport.get_texture())
	_track.draw(self)
	# The charge: gold clockwise from the top.
	if ratio > 0.0:
		var ring_width: float = half * RING_WIDTH
		var steps: int = maxi(4, roundi(CIRCLE_POINTS * ratio))
		var charge: Color = InkPalette.GOLD_BRIGHT if pulsing else InkPalette.GOLD
		_batch.clear()
		_batch.stroke(HudGauge.arc_points(center, half * RING_R, -PI * 0.5, -PI * 0.5 + TAU * ratio, steps), ring_width, ring_width, charge)
		_batch.draw(self)
	# The two thin gold trims are drawn antialiased (round edges show stair steps otherwise), under the badge and plate.
	draw_arc(center, half * OUTER_R - 1.0, 0.0, TAU, CIRCLE_POINTS, InkPalette.GOLD, 2.0, true)
	draw_arc(center, half * (RING_R - RING_WIDTH * 0.5) - 1.0, 0.0, TAU, CIRCLE_POINTS, Color(InkPalette.GOLD, 0.85), 2.0, true)
	_batch.clear()
	var badge: Vector2 = center + Vector2(half * 0.66, half * 0.66)
	batch_key_badge(badge, 28.0)
	var foot: Vector2 = center + Vector2(0.0, half * RING_R)
	var plate: Rect2 = _plate_rect(foot)
	if not value_text.is_empty():
		_batch.fill_convex(HudGauge.rect_points(plate), Color(InkPalette.INK, 0.95))
		HudGauge.outline(_batch, HudGauge.rect_points(plate), 1.6, InkPalette.GOLD_BRIGHT if pulsing else InkPalette.GOLD)
	_batch.draw(self)
	draw_key_letter(badge, 28.0)
	if not value_text.is_empty():
		var color: Color = InkPalette.GOLD_BRIGHT if pulsing else InkPalette.PARCHMENT
		draw_outlined(Vector2(plate.position.x + 9.0, foot.y + get_theme_default_font().get_ascent(PLATE_FONT_SIZE) * 0.36),
				value_text, PLATE_FONT_SIZE, color)


## READY: a gold halo round the medallion and a pale shine along the ring (faded in and out by the layer).
func _paint_glow(layer: CanvasItem) -> void:
	var half: float = size.x * 0.5
	var center: Vector2 = _center()
	var glow: InkBatch = InkBatch.new()
	# The halo leaves a gap from the key badge (lower right) to the plate (at the foot), which reach out over it.
	var from: float = PI * 0.5 + 0.42
	var to: float = PI * 0.25 + TAU - 0.25
	glow.stroke(HudGauge.arc_points(center, half * OUTER_R + 7.0, from, to, CIRCLE_POINTS), 14.0, 14.0, Color(InkPalette.GOLD_BRIGHT, 0.22))
	glow.stroke(HudGauge.arc_points(center, half * OUTER_R + 3.0, from, to, CIRCLE_POINTS), 5.0, 5.0, Color(InkPalette.GOLD_BRIGHT, 0.7))
	_arc_around_badge_and_plate(glow, half * RING_R, half * RING_WIDTH * 0.35, Color(InkPalette.PAPER, 0.42))
	glow.draw(layer)


## Low health: the inner rim in red (faded in and out by the layer).
func _paint_danger(layer: CanvasItem) -> void:
	var half: float = size.x * 0.5
	var warn: InkBatch = InkBatch.new()
	_arc_around_badge_and_plate(warn, half * (RING_R - RING_WIDTH * 0.5) - 1.0, 5.0, InkPalette.SAMURAI_RED)
	warn.draw(layer)


## A full circle except where the key badge (lower right) and the plate (bottom) sit, which the layers would cover.
func _arc_around_badge_and_plate(batch: InkBatch, radius: float, width: float, color: Color) -> void:
	var badge: float = PI * 0.25
	var plate: float = PI * 0.5
	# The two gaps overlap: one arc from past the plate, round the top, to just before the badge.
	batch.stroke(HudGauge.arc_points(_center(), radius, plate + 0.62, badge + TAU - 0.3, CIRCLE_POINTS), width, width, color)


## The small plate on the ring's foot that holds the charge ("42%") or READY.
func _plate_rect(foot: Vector2) -> Rect2:
	var width: float = text_width(value_text, PLATE_FONT_SIZE) + 18.0
	return Rect2(foot - Vector2(width * 0.5, 13.0), Vector2(width, 26.0))
