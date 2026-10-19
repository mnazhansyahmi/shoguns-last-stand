class_name SpellBurst
extends InkEffect
## The Onmyoji's burst: a ring of ink and magenta racing across the ground to the burst radius, an
## ink blot at the centre and paper talismans flung outward. Visual only (the damage is applied
## by the Onmyoji through the normal hitbox validation).

const LIFETIME: float = 0.55
const SLIPS: int = 8

var _radius: float = 130.0
var _slips: Array[Vector3] = []
var _blot: PackedVector2Array = PackedVector2Array()


func setup(radius: float) -> void:
	lifetime = LIFETIME
	_radius = radius
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	z_index = 4
	# Talisman slips: (angle of flight, spin, height).
	for i: int in SLIPS:
		_slips.append(Vector3(TAU * float(i) / float(SLIPS) + rng.randf_range(-0.2, 0.2), rng.randf_range(-5.0, 5.0), rng.randf_range(0.5, 1.0)))
	_blot = InkEffect.blot_points(rng, Vector2.ZERO, _radius * 0.32, 0.5, 6)


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	var reach: float = _radius * ease(minf(p * 1.6, 1.0), 0.3)
	# Ink blot at the centre, shrinking away.
	var blot: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in _blot:
		blot.append(point * (1.0 + p * 0.5))
	InkBrush.fill(self, blot, Color(InkPalette.INK, 0.8 * fade))
	# Expanding ring: magenta edge over ink.
	var ring: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, Vector2(reach, reach * 0.2), 30)
	ring.append(ring[0])
	InkBrush.stroke(self, ring, 14.0 * fade + 3.0, 14.0 * fade + 3.0, Color(InkPalette.INK, 0.75 * fade))
	InkBrush.stroke(self, ring, 6.0 * fade + 1.5, 6.0 * fade + 1.5, Color(InkPalette.ONMYOJI_MAGENTA, 0.95 * fade))
	# Paper talismans fly out and up, spinning.
	var batch: InkBatch = InkBatch.new()
	for slip: Vector3 in _slips:
		var travel: float = reach * 0.95
		var at: Vector2 = Vector2(cos(slip.x) * travel, sin(slip.x) * travel * 0.2 - 60.0 * slip.z * sin(minf(p * 1.4, 1.0) * PI * 0.7))
		var angle: float = slip.y * p * 2.0
		var corners: PackedVector2Array = PackedVector2Array([Vector2(-4.0, -9.0), Vector2(4.0, -9.0), Vector2(4.0, 9.0), Vector2(-4.0, 9.0)])
		var xf: Transform2D = Transform2D(angle, at)
		batch.fill_convex(xf * corners, Color(InkPalette.PAPER, 0.95 * fade))
		batch.limb(xf * Vector2(0.0, -5.0), xf * Vector2(0.0, 5.0), 2.2, 2.2, Color(InkPalette.ONMYOJI_MAGENTA, fade))
	batch.draw(self)
