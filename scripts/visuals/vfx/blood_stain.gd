class_name BloodStain
extends InkEffect
## What the blood leaves on the ground: a flat ink blot and a few spots around it that dry and fade away over several
## seconds. Drawn on the ground layer, under the characters.

const LIFETIME: float = 9.0
## The stain shows up after the drops have had time to fall.
const DELAY: float = 0.2
const FLATTEN: float = 0.3

var _blot: PackedVector2Array = PackedVector2Array()
var _spots: PackedVector2Array = PackedVector2Array()
var _spot_sizes: PackedFloat32Array = PackedFloat32Array()


## `size` 1 is a hit, about 2 a kill. `direction_x` is where the blood was thrown (the spots lie that way).
func setup(size: float, direction_x: float) -> void:
	lifetime = LIFETIME
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_blot = InkEffect.blot_points(rng, Vector2.ZERO, 9.0 * size, FLATTEN, 6)
	var count: int = 3 + roundi(3.0 * size)
	var dir: float = 1.0 if direction_x >= 0.0 else -1.0
	for i: int in count:
		_spots.append(Vector2(dir * rng.randf_range(-8.0, 70.0 * size), rng.randf_range(-3.0, 5.0)))
		_spot_sizes.append(rng.randf_range(1.5, 4.0) * (0.8 + 0.4 * size))


## How opaque the stain is now (0..1): in at once after the delay, then fading over its last two thirds.
func opacity() -> float:
	if age < DELAY:
		return 0.0
	return minf((age - DELAY) / 0.15, 1.0) * (1.0 - smoothstep(0.3, 1.0, progress()))


func _draw() -> void:
	var alpha: float = opacity()
	if alpha <= 0.0:
		return
	InkBrush.fill(self, _blot, Color(InkPalette.BLOOD_DARK, 0.85 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, FLATTEN))
	for i: int in _spots.size():
		draw_circle(_spots[i] / Vector2(1.0, FLATTEN), _spot_sizes[i], Color(InkPalette.BLOOD, 0.8 * alpha))
	draw_set_transform(Vector2.ZERO)
