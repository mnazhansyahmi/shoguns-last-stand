class_name FireBurst
extends InkEffect
## The small explosion of the Onmyoji's fireball: a white-hot flash, flame tongues thrown out in every direction over
## an ink blot, a ring of fire along the ground to the blast radius and embers flying up. Visual only (the damage is
## applied by the Fireball).

const LIFETIME: float = 0.5
const TONGUES: int = 9
const EMBERS: int = 12

var _radius: float = 110.0
var _tongues: PackedFloat32Array = PackedFloat32Array()
var _lengths: PackedFloat32Array = PackedFloat32Array()
var _embers: PackedVector2Array = PackedVector2Array()
var _blot: PackedVector2Array = PackedVector2Array()


func setup(radius: float) -> void:
	lifetime = LIFETIME
	_radius = radius
	z_index = 4
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for i: int in TONGUES:
		_tongues.append(TAU * (float(i) + rng.randf_range(-0.25, 0.25)) / float(TONGUES))
		_lengths.append(rng.randf_range(0.55, 1.0))
	for i: int in EMBERS:
		_embers.append(Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(0.4, 1.0)))
	_blot = InkEffect.blot_points(rng, Vector2.ZERO, radius * 0.3, 0.9, 6)


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	var reach: float = _radius * 0.8 * ease(minf(p * 1.8, 1.0), 0.35)
	# The ink blot under the fire, and the ring of fire racing out along the ground.
	var blot: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in _blot:
		blot.append(point * (0.8 + p * 0.7))
	InkBrush.fill(self, blot, Color(InkPalette.INK, 0.7 * fade))
	var grow: float = ease(minf(p * 1.6, 1.0), 0.3)
	var ring: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, Vector2(_radius * grow, _radius * 0.2 * grow), 30)
	ring.append(ring[0])
	InkBrush.stroke(self, ring, 10.0 * fade + 2.0, 10.0 * fade + 2.0, Color(InkPalette.INK, 0.6 * fade))
	InkBrush.stroke(self, ring, 5.0 * fade + 1.0, 5.0 * fade + 1.0, Color(InkPalette.HATAMOTO_ORANGE, 0.9 * fade))
	# Flame tongues: wide at the root, pointed, fading from paper to orange to ember.
	for i: int in TONGUES:
		var angle: float = _tongues[i]
		var length: float = reach * _lengths[i]
		var direction: Vector2 = Vector2.from_angle(angle)
		var side: Vector2 = direction.orthogonal() * (13.0 * fade + 2.0)
		var base: Vector2 = direction * reach * 0.15
		draw_colored_polygon(PackedVector2Array([base + side, direction * length, base - side]), Color(InkPalette.ONI_EMBER, 0.85 * fade))
		draw_colored_polygon(PackedVector2Array([base + side * 0.6, direction * length * 0.8, base - side * 0.6]), Color(InkPalette.HATAMOTO_ORANGE, 0.9 * fade))
	# The hot flash at the start.
	if p < 0.3:
		draw_circle(Vector2.ZERO, _radius * 0.4 * (1.0 - p / 0.3) + 6.0, Color(InkPalette.PAPER, 0.9 * (1.0 - p / 0.3)))
	# Embers flying up.
	for ember: Vector2 in _embers:
		var at: Vector2 = Vector2(ember.x * reach * 0.9, -ember.y * 90.0 * ease(p, 0.5))
		draw_circle(at, 3.0 * fade + 0.5, Color(InkPalette.HATAMOTO_ORANGE, fade))
