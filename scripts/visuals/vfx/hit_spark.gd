class_name HitSpark
extends InkEffect
## Impact burst where a hit lands: short sparks flying along the knockback, a paper flash, and
## an ink blot on heavy hits and kills. Colours say who was hit (see `Target`).

enum Target { ENEMY, DEFENDER, STRUCTURE }

const LIFETIME: float = 0.25

var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _lengths: PackedFloat32Array = PackedFloat32Array()
var _color: Color = InkPalette.GOLD_BRIGHT
var _blot: PackedVector2Array = PackedVector2Array()
var _heavy: bool = false
## The blot is triangulated once, here, and every frame's shapes go out in one draw command.
var _blot_triangles: PackedInt32Array = PackedInt32Array()
var _batch: InkBatch = InkBatch.new()


## `direction_x` is the knockback direction (+1 right, -1 left, 0 = all around).
func setup(direction_x: float, heavy: bool, killed: bool, target: Target) -> void:
	lifetime = LIFETIME
	_heavy = heavy
	match target:
		Target.ENEMY:
			_color = InkPalette.GOLD_BRIGHT
		Target.DEFENDER:
			_color = InkPalette.SAMURAI_RED.lightened(0.15)
		Target.STRUCTURE:
			_color = InkPalette.MIST
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var count: int = 10 if heavy or killed else 7
	var base_angle: float = 0.0 if direction_x >= 0.0 else PI
	for i: int in count:
		var spread: float = rng.randf_range(-1.1, 1.1) if direction_x != 0.0 else rng.randf_range(-PI, PI)
		if i % 4 == 3:
			spread += PI  # a few sparks kick back the other way
		var speed: float = rng.randf_range(380.0, 720.0) * (1.3 if heavy else 1.0)
		_positions.append(Vector2.ZERO)
		_velocities.append(Vector2.from_angle(base_angle + spread) * speed)
		_lengths.append(rng.randf_range(14.0, 30.0) * (1.3 if heavy else 1.0))
	if heavy or killed:
		_blot = InkEffect.blot_points(rng, Vector2.ZERO, 13.0 if heavy else 10.0, 0.8, 7)
		_blot_triangles = Geometry2D.triangulate_polygon(_blot)


func _advance(delta: float) -> void:
	var drag: float = exp(-9.0 * delta)
	for i: int in _positions.size():
		_positions[i] += _velocities[i] * delta
		_velocities[i] *= drag


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	_batch.clear()
	if not _blot_triangles.is_empty():
		_batch.fill_triangulated(_blot, _blot_triangles, Color(InkPalette.INK, 0.7 * fade), 0.7 + 0.6 * p)
	if p < 0.35:
		_batch.disc(Vector2.ZERO, (16.0 if _heavy else 11.0) * (1.0 - p), Color(InkPalette.PAPER, (0.35 - p) * 2.4), 16)
	var color: Color = Color(_color, fade)
	for i: int in _positions.size():
		var direction: Vector2 = _velocities[i].normalized() if _velocities[i].length_squared() > 1.0 else Vector2.RIGHT
		_batch.segment(_positions[i] - direction * _lengths[i] * fade, _positions[i], 1.4, 5.0, color)
	_batch.draw(self)
