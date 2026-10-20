class_name FigureTatters
extends RefCounted
## Ragged, fluttering cloth for every figure except the Hollow Soldier (which has its own hem in
## FigurePainter): a hem, cloak or banner with a torn free edge whose tips ripple in the wind. As with
## the Hollow's hem, each shape is built ONCE per kind, flutter phase and wind level (12 x 3) and
## cached; a figure only swaps between cached batches about a dozen times a second, from its own
## random clock, so a crowd's cloth never moves in step. Every batch carries the sun's rim light.
## Torso space: origin at the hips, +x forward, -y up.

const STEPS: int = 12
const WIND_LEVELS: int = 3

## Kind -> { key -> InkBatch }.
static var _cache: Dictionary = {}


## How one kind's tatters look.
class Def:
	## Top edge of the cloth: its back and front corners (for a flag: the pole's top and bottom).
	var back: Vector2 = Vector2(-10.0, 0.0)
	var front: Vector2 = Vector2(10.0, 0.0)
	## How far it hangs (for a flag: how far the free edge is from the pole), the number of torn
	## tips, and how uneven they are (0..1).
	var drop: float = 20.0
	var teeth: int = 5
	var ragged: float = 0.5
	## How far a tip moves in the breeze (units) and how fast the ripple runs (rad/s).
	var flutter: float = 1.8
	var speed: float = 7.0
	var color: Color = InkPalette.INK
	## A banner: hangs from a vertical edge, its torn edge is vertical.
	var flag: bool = false
	var seed_value: int = 1


## The tatters of a kind, or null for a kind without any.
static func def(kind: InkFigure.Kind) -> Def:
	var d: Def = Def.new()
	d.seed_value = int(kind) * 31 + 7
	match kind:
		InkFigure.Kind.SAMURAI:
			# A torn strip of under-robe trailing behind his hip.
			d.back = Vector2(-14.0, -3.0)
			d.front = Vector2(-2.0, -3.0)
			d.drop = 38.0
			d.teeth = 4
			d.ragged = 0.7
			d.flutter = 2.6
			d.speed = 6.0
			d.color = InkPalette.INK_BACK
		InkFigure.Kind.ASHIGARU:
			d.back = Vector2(-12.0, 5.0)
			d.front = Vector2(12.5, 5.0)
			d.drop = 17.0
			d.teeth = 6
			d.ragged = 0.8
			d.flutter = 1.8
		InkFigure.Kind.YUMI_ARCHER:
			# A short cloak hanging from the shoulders, behind the body.
			d.back = Vector2(-20.0, -27.0)
			d.front = Vector2(-4.0, -27.0)
			d.drop = 44.0
			d.teeth = 4
			d.ragged = 0.8
			d.flutter = 2.8
			d.speed = 6.5
			d.color = InkPalette.INK_BACK
		InkFigure.Kind.SHRINE_HEALER:
			d.back = Vector2(-16.0, 26.0)
			d.front = Vector2(17.0, 26.0)
			d.drop = 13.0
			d.teeth = 7
			d.ragged = 0.55
			d.flutter = 1.7
			d.speed = 4.5
		InkFigure.Kind.SPEAR_GUARDIAN:
			# A torn tabard hanging in front of the legs.
			d.back = Vector2(-7.0, 14.0)
			d.front = Vector2(9.0, 14.0)
			d.drop = 25.0
			d.teeth = 4
			d.ragged = 0.75
			d.flutter = 1.4
			d.speed = 5.0
		InkFigure.Kind.ONMYOJI:
			d.back = Vector2(-14.0, 28.0)
			d.front = Vector2(15.0, 28.0)
			d.drop = 12.0
			d.teeth = 6
			d.ragged = 0.55
			d.flutter = 1.7
			d.speed = 4.0
		InkFigure.Kind.HATAMOTO:
			# The flag on his back: its pole edge is fixed, its free edge is torn and ripples.
			d.back = Vector2(-11.7, -99.0)
			d.front = Vector2(-11.0, -63.0)
			d.drop = 22.0
			d.teeth = 6
			d.ragged = 0.9
			d.flutter = 3.4
			d.speed = 5.5
			d.color = InkPalette.HATAMOTO_ORANGE
			d.flag = true
		InkFigure.Kind.FALLEN_DAIMYO:
			# A long torn cloak from the shoulders, streaming behind him.
			d.back = Vector2(-21.0, -33.0)
			d.front = Vector2(-4.0, -33.0)
			d.drop = 78.0
			d.teeth = 6
			d.ragged = 0.85
			d.flutter = 3.4
			d.speed = 5.0
			d.color = InkPalette.INK_BACK
		InkFigure.Kind.ONI_BRUTE:
			# Strips of hide hanging under the loincloth.
			d.back = Vector2(-13.0, 3.0)
			d.front = Vector2(13.0, 3.0)
			d.drop = 24.0
			d.teeth = 5
			d.ragged = 0.9
			d.flutter = 1.9
			d.speed = 3.6
		_:
			return null
	return d


## True if the kind wears tatters of its own (the Hollow Soldier's hem lives in FigurePainter).
static func has_tatters(kind: InkFigure.Kind) -> bool:
	return def(kind) != null


## Which cached shape a figure shows now: its flutter phase x its wind level. A figure's clock
## starts at a random value, so neighbours are in different phases.
static func key(fig: InkFigure) -> int:
	var d: Def = def(fig.kind)
	var speed: float = d.speed if d != null else 6.0
	var step: int = int(fposmod(fig.clock * speed, TAU) / TAU * float(STEPS)) % STEPS
	var level: int = clampi(roundi(fig.trail * 2.0), 0, WIND_LEVELS - 1)
	return step * WIND_LEVELS + level


## The cached batch (with the rim light) for a kind and key.
static func batch(kind: InkFigure.Kind, cache_key: int) -> InkBatch:
	if not _cache.has(kind):
		_cache[kind] = {}
	var by_key: Dictionary = _cache[kind]
	if by_key.has(cache_key):
		return by_key[cache_key]
	var shape: InkBatch = InkBatch.new()
	var d: Def = def(kind)
	if d != null:
		_build(shape, d, cache_key)
		FigurePainter.tone_batch(kind, shape)
	var lit: InkBatch = shape.with_rim()
	by_key[cache_key] = lit
	return lit


static func _build(b: InkBatch, d: Def, cache_key: int) -> void:
	var phase: float = float(cache_key / WIND_LEVELS) / float(STEPS) * TAU
	var trail: float = float(cache_key % WIND_LEVELS) * 0.5
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	# The tear pattern is fixed per kind (not per phase): only the ripple changes between frames.
	rng.seed = d.seed_value
	var depth: PackedFloat32Array = PackedFloat32Array()
	var skew: PackedFloat32Array = PackedFloat32Array()
	var notch: PackedFloat32Array = PackedFloat32Array()
	for i: int in d.teeth:
		depth.append(rng.randf_range(1.0 - d.ragged * 0.55, 1.0))
		skew.append(rng.randf_range(-0.3, 0.3))
		notch.append(rng.randf_range(0.35, 0.65))
	var ring: PackedVector2Array = PackedVector2Array([d.back, d.front])
	var sway: float = d.flutter * (0.4 + trail)
	if d.flag:
		# Free edge runs up from the bottom of the pole to its top, tips pointing away from the pole.
		var free_x: float = d.back.x - d.drop
		for i: int in d.teeth:
			var u: float = (float(i) + 0.5) / float(d.teeth)
			var y: float = lerpf(d.front.y, d.back.y, u)
			var wave: float = sin(phase + float(i) * 1.7)
			ring.append(Vector2(free_x - (1.0 - depth[i]) * 14.0 + wave * sway, y + wave * sway * 0.4))
			var y_notch: float = lerpf(d.front.y, d.back.y, (float(i) + 1.0) / float(d.teeth))
			ring.append(Vector2(free_x + 5.0 + notch[i] * 6.0 * d.ragged + sin(phase + float(i) * 1.7 + 1.0) * sway * 0.5, y_notch))
	else:
		# Torn tips along the bottom, from the front corner back; tips and notches alternate.
		var span: float = d.front.x - d.back.x
		for i: int in d.teeth:
			var u: float = (float(i) + 0.5 + skew[i]) / float(d.teeth)
			var x: float = d.front.x - span * u
			var wave: float = sin(phase + float(i) * 1.7)
			ring.append(Vector2(x - trail * 2.0 * float(i % 2), d.front.y + d.drop * depth[i] + wave * sway))
			var u_notch: float = float(i + 1) / float(d.teeth)
			ring.append(Vector2(d.front.x - span * u_notch, d.front.y + d.drop * notch[i] * 0.8 + sin(phase + float(i) * 1.7 + 1.0) * sway * 0.5))
	b.fill(ring, d.color)
