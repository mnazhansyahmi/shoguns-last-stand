class_name WarCryRing
extends InkEffect
## The War Cry: a gold ink ring bursts out along the ground to the full range of the cry and lingers there a
## moment, so the player sees exactly who is rallied, with sound-wave arcs leaving the samurai's mouth.

const LIFETIME: float = 0.85
## The ring reaches the full radius after this long, then holds while it fades.
const EXPAND_TIME: float = 0.4
const WAVE_TIME: float = 0.4
const WAVES: int = 3
const DROPS: int = 30
## The ring is the ground ellipse: its height is this fraction of its radius.
const FLATTEN: float = 0.2

var _radius: float = 700.0
var _mouth: Vector2 = Vector2.ZERO
var _facing: float = 1.0
var _drop_angles: PackedFloat32Array = PackedFloat32Array()
var _drop_sizes: PackedFloat32Array = PackedFloat32Array()


## `radius` is the range of the cry in pixels; `mouth` is the shout's origin relative to this node (the feet).
func setup(radius: float, mouth: Vector2, facing: float) -> void:
	lifetime = LIFETIME
	_radius = radius
	_mouth = mouth
	_facing = 1.0 if facing >= 0.0 else -1.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4177
	for i: int in DROPS:
		_drop_angles.append(TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(DROPS))
		_drop_sizes.append(rng.randf_range(3.0, 9.0))


## Radius of the ring now.
func reach() -> float:
	return _radius * ease(clampf(age / EXPAND_TIME, 0.0, 1.0), 0.3)


## Seconds after the cry until the ring has reached `distance` of a ring of `radius` (allies flash gold as it passes).
static func time_to_reach(distance: float, radius: float) -> float:
	return EXPAND_TIME * (1.0 - pow(1.0 - clampf(distance / maxf(radius, 1.0), 0.0, 1.0), 0.3))


func _draw() -> void:
	var fade: float = 1.0 - smoothstep(EXPAND_TIME, LIFETIME, age)
	var grow: float = reach()
	var ring: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, Vector2(grow, grow * FLATTEN), 48)
	ring.append(ring[0])
	var settling: float = 1.0 - clampf(age / EXPAND_TIME, 0.0, 1.0)
	# A wash inside the ring, then a dark ink line under the gold one (it reads as a brush stroke, not a glow).
	BambooOutskirtsPainter.soft(self, Vector2.ZERO, Vector2(grow, grow * FLATTEN) * 1.9, Color(InkPalette.GOLD, 0.16 * fade))
	InkBrush.stroke(self, ring, 22.0 * settling + 9.0, 22.0 * settling + 9.0, Color(InkPalette.INK, 0.5 * fade))
	InkBrush.stroke(self, ring, 14.0 * settling + 6.0, 14.0 * settling + 6.0, Color(InkPalette.GOLD_BRIGHT, 0.9 * fade))
	# Ink drops flung from the edge.
	for i: int in _drop_angles.size():
		var angle: float = _drop_angles[i]
		var out: float = 1.0 + 0.05 * _drop_sizes[i] * settling
		var spot: Vector2 = Vector2(cos(angle) * grow * out, sin(angle) * grow * FLATTEN * out)
		var size: float = _drop_sizes[i] * (0.5 + settling)
		draw_set_transform(spot, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, size, Color(InkPalette.GOLD, 0.85 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_waves()


## Arcs leaving the mouth, one after another.
func _draw_waves() -> void:
	if age >= WAVE_TIME + 0.2:
		return
	for i: int in WAVES:
		var local: float = (age - float(i) * 0.07) / WAVE_TIME
		if local <= 0.0 or local >= 1.0:
			continue
		var radius: float = 26.0 + 150.0 * ease(local, 0.5)
		var spread: float = 0.75 - 0.2 * local
		var arc: PackedVector2Array = PackedVector2Array()
		for step: int in 11:
			var angle: float = lerpf(-spread, spread, float(step) / 10.0)
			arc.append(_mouth + Vector2(cos(angle) * _facing, sin(angle)) * radius)
		var alpha: float = 1.0 - local
		InkBrush.stroke(self, arc, 9.0 * alpha + 2.0, 3.0, Color(InkPalette.GOLD_BRIGHT, 0.9 * alpha))
