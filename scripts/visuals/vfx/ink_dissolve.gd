class_name InkDissolve
extends InkEffect
## A fallen body breaking into ink: droplets rise from points over the body, drift and fade,
## with a few motes in the unit's colour (violet/ember sparks for enemies, spirit light for
## defenders). Timed to finish within the corpse time.

const LIFETIME: float = 0.45

var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _accent: Color = InkPalette.SPIRIT


## `sources` = points over the body in this node's space; `scale_factor` sizes the droplets.
func setup(sources: PackedVector2Array, accent: Color, scale_factor: float) -> void:
	lifetime = LIFETIME
	_accent = accent
	if sources.is_empty():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var count: int = int(18.0 * clampf(scale_factor, 1.0, 2.0))
	for i: int in count:
		var source: Vector2 = sources[rng.randi_range(0, sources.size() - 1)]
		_positions.append(source + Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-8.0, 8.0)) * scale_factor)
		_velocities.append(Vector2(rng.randf_range(-40.0, 40.0), -rng.randf_range(30.0, 110.0)) * scale_factor)
		_sizes.append(rng.randf_range(2.5, 5.5) * scale_factor)


func _advance(delta: float) -> void:
	for i: int in _positions.size():
		_velocities[i].y -= 160.0 * delta
		_positions[i] += _velocities[i] * delta


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	for i: int in _positions.size():
		if i % 4 == 0:
			BambooOutskirtsPainter.soft(self, _positions[i], Vector2.ONE * _sizes[i] * 4.0, Color(_accent, 0.8 * fade))
		else:
			draw_circle(_positions[i], _sizes[i] * (1.0 - 0.6 * p), Color(InkPalette.INK, 0.85 * fade))
