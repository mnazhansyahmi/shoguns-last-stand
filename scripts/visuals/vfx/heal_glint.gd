class_name HealGlint
extends InkEffect
## A healing blessing: a jade ring on the ground and jade motes rising around the healed ally.
## Visual only.

const LIFETIME: float = 0.7
const MOTES: int = 9

var _height: float = 100.0
var _motes: Array[Vector3] = []


## `height` = the healed ally's body height (the motes rise that far).
func setup(height: float) -> void:
	lifetime = LIFETIME
	_height = height
	z_index = 4
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	# (x offset, start delay 0..0.4, sway phase)
	for i: int in MOTES:
		_motes.append(Vector3(rng.randf_range(-22.0, 22.0), rng.randf_range(0.0, 0.4), rng.randf_range(0.0, TAU)))


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	var ring: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, Vector2(34.0 + 22.0 * p, (34.0 + 22.0 * p) * 0.22), 24)
	ring.append(ring[0])
	InkBrush.stroke(self, ring, 5.0 * fade + 1.5, 5.0 * fade + 1.5, Color(InkPalette.HEALER_JADE, 0.9 * fade))
	var batch: InkBatch = InkBatch.new()
	for mote: Vector3 in _motes:
		var t: float = clampf((p - mote.y * 0.5) / (1.0 - mote.y * 0.5), 0.0, 1.0)
		if t <= 0.0:
			continue
		var at: Vector2 = Vector2(mote.x + sin(t * 5.0 + mote.z) * 6.0, -t * _height * 0.9)
		var size: float = 4.0 * (1.0 - t * 0.5)
		batch.fill_convex(PackedVector2Array([at + Vector2(0.0, -size * 1.6), at + Vector2(size, 0.0), at + Vector2(0.0, size * 1.6), at + Vector2(-size, 0.0)]),
				Color(InkPalette.HEALER_JADE, 0.95 * (1.0 - t * t)))
		batch.circle(at, size * 0.35, Color(InkPalette.PAPER, 0.9 * (1.0 - t * t)))
	batch.draw(self)
