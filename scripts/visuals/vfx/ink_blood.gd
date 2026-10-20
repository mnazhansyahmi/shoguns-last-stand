class_name InkBlood
extends InkEffect
## Ink-style blood where a hit lands: a brush-stroke spray flung along the knockback and dark crimson drops that arc
## down to the ground (the ground then keeps a BloodStain). More of it on heavy hits, kills and the Spirit Slash.

const LIFETIME: float = 0.7
const GRAVITY: float = 1500.0

var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _alive: PackedByteArray = PackedByteArray()
## How far below the burst the ground is (pixels): drops that fall this far are gone.
var _ground_dy: float = 60.0
var _direction: float = 1.0
var _spray_length: float = 60.0
var _spray_bend: float = 0.4


## How many drops a hit throws: 8, 16 for a heavy hit, 18 for the Spirit Slash, and 8 more for a kill.
static func amount(heavy: bool, spirit: bool, killed: bool) -> int:
	var count: int = 8
	if heavy:
		count = 16
	if spirit:
		count = maxi(count, 18)
	if killed:
		count += 8
	return count


## `direction_x` is the knockback direction (+1 right, -1 left); `ground_dy` the distance down to the ground.
func setup(direction_x: float, ground_dy: float, heavy: bool, spirit: bool, killed: bool) -> void:
	lifetime = LIFETIME
	_ground_dy = maxf(ground_dy, 20.0)
	_direction = 1.0 if direction_x >= 0.0 else -1.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var count: int = amount(heavy, spirit, killed)
	var power: float = 1.0
	if heavy or spirit or killed:
		power = 1.4
	_spray_length = rng.randf_range(55.0, 80.0) * power
	_spray_bend = rng.randf_range(0.25, 0.6)
	for i: int in count:
		var angle: float = rng.randf_range(-1.1, 0.5)
		var speed: float = rng.randf_range(120.0, 520.0) * power
		var velocity: Vector2 = Vector2(cos(angle) * _direction, sin(angle)) * speed
		if i % 5 == 4:
			velocity.x *= -0.5
		_positions.append(Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-8.0, 8.0)))
		_velocities.append(velocity)
		_sizes.append(rng.randf_range(2.6, 5.4) * (1.4 if (heavy or spirit or killed) and i % 3 == 0 else 1.0))
		_alive.append(1)


## Drops still in the air.
func live_drops() -> int:
	var count: int = 0
	for flag: int in _alive:
		count += flag
	return count


func _advance(delta: float) -> void:
	for i: int in _positions.size():
		if _alive[i] == 0:
			continue
		_velocities[i].y += GRAVITY * delta
		_positions[i] += _velocities[i] * delta
		if _positions[i].y >= _ground_dy:
			_alive[i] = 0


func _draw() -> void:
	var p: float = progress()
	# The brush-stroke spray: a tapered curve thrown along the hit, gone in the first third.
	if p < 0.34:
		var fade: float = 1.0 - p / 0.34
		var reach: float = _spray_length * ease(minf(p / 0.2, 1.0), 0.4)
		var points: PackedVector2Array = PackedVector2Array()
		for step: int in 9:
			var t: float = float(step) / 8.0
			points.append(Vector2(_direction * reach * t, -reach * _spray_bend * sin(t * PI) * 0.6 + reach * 0.25 * t * t))
		InkBrush.stroke(self, points, 9.0 * fade + 2.0, 1.5, Color(InkPalette.BLOOD, 0.9 * fade))
	for i: int in _positions.size():
		if _alive[i] == 0:
			continue
		var velocity: Vector2 = _velocities[i]
		var tail: Vector2 = _positions[i] - velocity * 0.02
		var alpha: float = 1.0 - smoothstep(0.7, 1.0, p)
		InkBrush.stroke(self, PackedVector2Array([tail, _positions[i]]), _sizes[i] * 0.5, _sizes[i], Color(InkPalette.BLOOD, alpha))
		draw_circle(_positions[i], _sizes[i] * 0.55, Color(InkPalette.BLOOD, alpha))
