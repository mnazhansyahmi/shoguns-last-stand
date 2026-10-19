class_name ShockRing
extends InkEffect
## Ground shockwave of a heavy slam (Oni Brute): a flattened ink ring racing outward with dust
## rolling up behind it.

const LIFETIME: float = 0.32

var _radius: float = 150.0
var _dust: PackedVector2Array = PackedVector2Array()


func setup(radius: float) -> void:
	lifetime = LIFETIME
	_radius = radius
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for i: int in 7:
		_dust.append(Vector2(rng.randf_range(-radius, radius) * 0.7, -rng.randf_range(4.0, 20.0)))


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	var reach: float = _radius * ease(p, 0.35)
	for i: int in _dust.size():
		var dust: Vector2 = _dust[i] * (0.4 + p) + Vector2(0.0, -30.0 * p)
		BambooOutskirtsPainter.soft(self, dust, Vector2(90.0, 50.0) * (0.6 + p),
				Color(InkPalette.INK_BACK.lerp(InkPalette.MIST, 0.4), 0.45 * fade))
	var ring: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, Vector2(reach, reach * 0.18), 28)
	ring.append(ring[0])
	InkBrush.stroke(self, ring, 10.0 * fade + 2.0, 10.0 * fade + 2.0, Color(InkPalette.INK, 0.6 * fade))
