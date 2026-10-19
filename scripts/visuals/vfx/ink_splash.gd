class_name InkSplash
extends InkEffect
## Ground burst at a unit's feet when it appears. SUMMON: an ink splash with flying droplets
## and rising spirit glints (allies, samurai respawn). PORTAL_SMOKE: violet ink smoke rolling
## up (enemies stepping out of the portal).

enum Style { SUMMON, PORTAL_SMOKE }

const SUMMON_LIFETIME: float = 0.55
const SMOKE_LIFETIME: float = 0.6
const GRAVITY: float = 900.0

var _style: Style = Style.SUMMON
var _width: float = 50.0
var _blot: PackedVector2Array = PackedVector2Array()
var _drops: PackedVector2Array = PackedVector2Array()
var _drop_velocities: PackedVector2Array = PackedVector2Array()
var _motes: PackedVector2Array = PackedVector2Array()
var _mote_speeds: PackedFloat32Array = PackedFloat32Array()


## `width` = the unit's body width in pixels.
func setup(style: Style, width: float) -> void:
	_style = style
	_width = width
	lifetime = SUMMON_LIFETIME if style == Style.SUMMON else SMOKE_LIFETIME
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_blot = InkEffect.blot_points(rng, Vector2.ZERO, width, 0.26, 9)
	var drops: int = 10 if style == Style.SUMMON else 9
	for i: int in drops:
		if style == Style.SUMMON:
			_drops.append(Vector2(rng.randf_range(-width * 0.4, width * 0.4), -2.0))
			_drop_velocities.append(Vector2(rng.randf_range(-260.0, 260.0), -rng.randf_range(220.0, 460.0)))
		else:
			_drops.append(Vector2(rng.randf_range(-width * 0.6, width * 0.6), -rng.randf_range(0.0, 40.0)))
			_drop_velocities.append(Vector2(rng.randf_range(-30.0, 30.0), -rng.randf_range(60.0, 140.0)))
	if style == Style.SUMMON:
		for i: int in 6:
			_motes.append(Vector2(rng.randf_range(-width * 0.5, width * 0.5), -rng.randf_range(0.0, 30.0)))
			_mote_speeds.append(rng.randf_range(90.0, 170.0))


func _advance(delta: float) -> void:
	for i: int in _drops.size():
		_drops[i] += _drop_velocities[i] * delta
		if _style == Style.SUMMON:
			_drop_velocities[i].y += GRAVITY * delta
	for i: int in _motes.size():
		_motes[i].y -= _mote_speeds[i] * delta


func _draw() -> void:
	var p: float = progress()
	var fade: float = 1.0 - p
	if _style == Style.PORTAL_SMOKE:
		var smoke: Color = InkPalette.INK.lerp(InkPalette.HOLLOW_PURPLE, 0.35)
		for i: int in _drops.size():
			var size: float = _width * (0.7 + 0.9 * p)
			BambooOutskirtsPainter.soft(self, _drops[i], Vector2(size, size * 0.8), Color(smoke, 0.55 * fade))
		return
	var spread: float = 0.45 + 0.75 * ease(minf(p * 3.0, 1.0), 0.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(spread, spread))
	InkBrush.fill(self, _blot, Color(InkPalette.INK, 0.85 * pow(fade, 0.6)))
	draw_set_transform(Vector2.ZERO)
	for i: int in _drops.size():
		if _drops[i].y < 2.0:
			draw_circle(_drops[i], 3.2 * (1.0 - p * 0.5), Color(InkPalette.INK, 0.9 * fade))
	for i: int in _motes.size():
		BambooOutskirtsPainter.soft(self, _motes[i], Vector2(14.0, 14.0), Color(InkPalette.SPIRIT, 0.9 * fade))
		draw_circle(_motes[i], 1.8, Color(InkPalette.PAPER, fade))
