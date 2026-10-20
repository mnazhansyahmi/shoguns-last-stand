class_name AttackTelegraph
extends Node2D
## A warning on the ground where a boss attack will land: an outline that is always visible and a fill
## that grows over the wind-up, so the player sees WHERE and WHEN. It frees itself when its time is up
## (or when the boss cancels it with dismiss()). Visual only: the damage comes from the boss's hitbox.

enum Shape { ELLIPSE, STRIP }

const LINGER: float = 0.12

var _shape: Shape = Shape.ELLIPSE
var _half: Vector2 = Vector2(100.0, 18.0)
var _duration: float = 1.0
var _age: float = 0.0
var _color: Color = InkPalette.DAIMYO_CURSE


## `size` is the full width and depth of the zone on the ground; `duration` the wind-up it counts down.
func setup(shape: Shape, size: Vector2, duration: float, color: Color = InkPalette.DAIMYO_CURSE) -> void:
	_shape = shape
	_half = size * 0.5
	_duration = maxf(duration, 0.05)
	_color = color
	z_index = 0


## 0..1 over the wind-up.
func progress() -> float:
	return clampf(_age / _duration, 0.0, 1.0)


func dismiss() -> void:
	queue_free()


func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration + LINGER:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var p: float = progress()
	var urgent: float = 0.5 + 0.5 * sin(_age * (10.0 + 16.0 * p))
	# A long strip lies over other fighters, so it is fainter than a zone around the boss.
	var fade: float = (1.0 - clampf((_age - _duration) / LINGER, 0.0, 1.0)) * (0.6 if _shape == Shape.STRIP else 1.0)
	var outline: PackedVector2Array = _outline(1.0)
	var fill: PackedVector2Array = _outline(0.15 + 0.85 * ease(p, 0.6))
	var batch: InkBatch = InkBatch.new()
	batch.fill_convex(outline, Color(_color, (0.1 + 0.08 * urgent) * fade))
	batch.fill_convex(fill, Color(_color, (0.18 + 0.4 * p) * fade))
	batch.draw(self)
	var edge: PackedVector2Array = outline.duplicate()
	edge.append(edge[0])
	var line: InkBatch = InkBatch.new()
	line.stroke(edge, 5.0, 5.0, Color(InkPalette.INK, 0.75 * fade))
	line.stroke(edge, 2.6, 2.6, Color(_color.lerp(InkPalette.PAPER, 0.25 * urgent), (0.7 + 0.3 * urgent) * fade))
	line.draw(self)


## The zone's outline, scaled about its centre (the strip grows from its back edge, like a charging wave).
func _outline(amount: float) -> PackedVector2Array:
	if _shape == Shape.STRIP:
		var right: float = -_half.x + _half.x * 2.0 * amount
		return PackedVector2Array([Vector2(-_half.x, -_half.y), Vector2(right, -_half.y), Vector2(right, _half.y), Vector2(-_half.x, _half.y)])
	return InkBrush.ellipse_points(Vector2.ZERO, _half * amount, 28)
