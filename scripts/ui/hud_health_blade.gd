class_name HudHealthBlade
extends HudGauge
## The samurai's health as a katana: a guard (tsuba) and collar at the left, where it comes out of the portrait
## medallion, then the blade itself, filled crimson from the hilt toward the point as far as his health goes, with a pale
## edge line (the hamon) along the cutting edge. A hit leaves a pale "ghost" of the lost health that holds a moment and
## then drains away, with a quick white flash; at LOW_HEALTH or less the fill turns blood red and a red glow round the
## blade pulses (a layer behind it, faded with modulate, so the blade itself is not redrawn). The number sits on the blade in parchment with an
## ink outline.

const LOW_HEALTH: float = 0.3
## How long the ghost of lost health holds before it drains, and how fast it drains (ratio per second).
const GHOST_HOLD: float = 0.35
const GHOST_DRAIN: float = 0.9
const FLASH_TIME: float = 0.22
const GUARD_WIDTH: float = 18.0
const COLLAR_WIDTH: float = 12.0
const FONT_SIZE: int = 26
## The blade's spine and cutting edge, as fractions of the control's height.
const TOP: float = 0.26
const BOTTOM: float = 0.8

## Where the lost-health ghost reaches (>= ratio while it drains).
var ghost: float = 1.0

var _hold: float = 0.0
var _flash: float = 0.0
var _blade: PackedVector2Array = PackedVector2Array()
var _danger: Layer
## The parts that never change, built once per size: under the fill (shadow, steel) and over it (outline, guard).
var _back: InkBatch = InkBatch.new()
var _front: InkBatch = InkBatch.new()


func _ready() -> void:
	_danger = add_layer("Danger", _paint_danger, true)
	_danger.visible = false
	super()
	resized.connect(_build_shape)
	_build_shape()


## True while health is at LOW_HEALTH or less (the blade pulses red).
func is_low() -> bool:
	return ratio <= LOW_HEALTH and ratio > 0.0


func get_blade_polygon() -> PackedVector2Array:
	return _blade


func _is_animating() -> bool:
	return ghost > ratio + 0.001 or _flash > 0.0 or is_low()


func _on_ratio_changed(old: float, new: float) -> void:
	if new < old:
		ghost = maxf(ghost, old)
		_hold = GHOST_HOLD
		_flash = 1.0
	else:
		ghost = new
	if _danger != null:
		_danger.visible = is_low()
		_danger.queue_redraw()


func _step(delta: float) -> void:
	var moving: bool = _flash > 0.0 or ghost > ratio + 0.001
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	if _hold > 0.0:
		_hold -= delta
	else:
		ghost = move_toward(ghost, ratio, GHOST_DRAIN * delta)
	if moving:
		queue_redraw()
	if is_low():
		_danger.modulate.a = 0.25 + 0.75 * _pulse(1.6)


## The blade outline: a straight spine on top, the cutting edge below curving up into the point at the right end.
func _build_shape() -> void:
	var x0: float = GUARD_WIDTH + COLLAR_WIDTH
	var top: float = size.y * TOP
	var bottom: float = size.y * BOTTOM
	var tip_x: float = size.x - 2.0
	var shoulder: float = size.x - (bottom - top) * 1.6
	_blade = PackedVector2Array([
		Vector2(x0, top), Vector2(shoulder, top + 1.0), Vector2(tip_x, top + (bottom - top) * 0.28),
		Vector2(tip_x - 10.0, top + (bottom - top) * 0.62), Vector2(shoulder - 6.0, bottom), Vector2(x0, bottom)])
	_back.clear()
	_back.fill(HudGauge.shifted(_blade, Vector2(3.0, 4.0)), Color(InkPalette.INK, 0.45))
	_back.fill(_blade, Color(InkPalette.INK_BACK, 0.94))
	_front.clear()
	HudGauge.outline(_front, _blade, 5.0, Color(InkPalette.INK, 0.95))
	var mid: float = (top + bottom) * 0.5
	var guard: PackedVector2Array = InkBrush.ellipse_points(Vector2(GUARD_WIDTH * 0.5, mid), Vector2(GUARD_WIDTH * 0.5, size.y * 0.47), 20)
	_front.fill_convex(guard, InkPalette.INK_DETAIL)
	HudGauge.outline(_front, guard, 4.0, Color(InkPalette.INK, 0.95))
	HudGauge.outline(_front, guard, 1.6, InkPalette.GOLD)
	var collar: PackedVector2Array = HudGauge.rect_points(Rect2(Vector2(GUARD_WIDTH, top - 2.0), Vector2(COLLAR_WIDTH, bottom - top + 4.0)))
	_front.fill_convex(collar, InkPalette.GOLD.darkened(0.15))
	HudGauge.outline(_front, collar, 1.2, InkPalette.GOLD_BRIGHT)
	queue_redraw()
	_danger.queue_redraw()


## The part of the blade between x = `from_ratio` and `to_ratio` of its length (one polygon, or none).
func _blade_slice(from_ratio: float, to_ratio: float) -> PackedVector2Array:
	if to_ratio <= from_ratio or _blade.is_empty():
		return PackedVector2Array()
	var x0: float = GUARD_WIDTH + COLLAR_WIDTH
	var length: float = size.x - x0
	var a: float = x0 + length * from_ratio
	var b: float = x0 + length * to_ratio
	var box: PackedVector2Array = PackedVector2Array([Vector2(a, -10.0), Vector2(b, -10.0), Vector2(b, size.y + 10.0), Vector2(a, size.y + 10.0)])
	var parts: Array[PackedVector2Array] = Geometry2D.intersect_polygons(_blade, box)
	return parts[0] if not parts.is_empty() else PackedVector2Array()


func _draw() -> void:
	if _blade.is_empty():
		return
	_back.draw(self)
	# The crimson health, then the pale ghost of what the last hit took, and the edge lines on the filled part.
	_batch.clear()
	var filled: PackedVector2Array = _blade_slice(0.0, ratio)
	if not filled.is_empty():
		var health: Color = InkPalette.BLOOD.lightened(0.12) if is_low() else InkPalette.SAMURAI_RED.darkened(0.12)
		_batch.fill_convex(filled, health.lerp(InkPalette.PAPER, _flash * 0.55))
	var lost: PackedVector2Array = _blade_slice(ratio, ghost)
	if not lost.is_empty():
		_batch.fill_convex(lost, Color(InkPalette.PAPER, 0.62))
	_batch_edge_lines()
	_batch.draw(self)
	_front.draw(self)
	# The thin gold trim is the one line drawn antialiased: on the slanted point it would show stair steps.
	var trim: PackedVector2Array = _blade.duplicate()
	trim.append(_blade[0])
	draw_polyline(trim, Color(InkPalette.GOLD, 0.85), 1.6, true)
	var baseline: float = size.y * (TOP + BOTTOM) * 0.5 + get_theme_default_font().get_ascent(FONT_SIZE) * 0.36
	draw_outlined(Vector2(GUARD_WIDTH + COLLAR_WIDTH + 14.0, baseline), value_text, FONT_SIZE, InkPalette.PAPER)


## The low-health warning (behind the blade, faded in and out by its layer's modulate): a red glow round the blade.
func _paint_danger(layer: CanvasItem) -> void:
	if _blade.is_empty():
		return
	var warn: InkBatch = InkBatch.new()
	HudGauge.outline(warn, _blade, 22.0, Color(InkPalette.SAMURAI_RED, 0.3))
	HudGauge.outline(warn, _blade, 13.0, Color(InkPalette.SAMURAI_RED, 0.9))
	warn.draw(layer)


## The hamon along the cutting edge and a glint on the spine, as far as the blade is filled.
func _batch_edge_lines() -> void:
	if ratio <= 0.0:
		return
	var x0: float = GUARD_WIDTH + COLLAR_WIDTH
	var top: float = size.y * TOP
	var bottom: float = size.y * BOTTOM
	var fill_end: float = x0 + (size.x - x0) * ratio
	var shoulder: float = size.x - (bottom - top) * 1.6
	var hamon_end: float = minf(fill_end, shoulder - 8.0)
	if hamon_end > x0 + 4.0:
		var hamon: PackedVector2Array = PackedVector2Array()
		for i: int in 9:
			var x: float = lerpf(x0 + 4.0, hamon_end, float(i) / 8.0)
			hamon.append(Vector2(x, bottom - 6.0 + sin(x * 0.11) * 1.4))
		_batch.stroke(hamon, 2.0, 2.0, Color(InkPalette.PAPER, 0.42))
	_batch.segment(Vector2(x0 + 2.0, top + 3.0), Vector2(minf(fill_end, shoulder), top + 3.5), 1.5, 1.5, Color(InkPalette.PAPER, 0.28))
