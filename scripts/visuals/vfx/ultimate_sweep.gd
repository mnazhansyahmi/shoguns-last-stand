class_name UltimateSweep
extends Control
## The Ultimate's brush slash: one fast crescent of crimson light with a pale core, drawn in front of the
## samurai (screen space, on its own canvas layer). It is a short, bold arc, NOT a line across the whole
## screen (a stroke from the gate to the right edge read as long thin dark lines), and it has no dark
## ink in it, so it never hides the fight; there is no screen wash and only a few small crimson drops.
## It runs in REAL time (it divides out Engine.time_scale), so it keeps animating during the brief
## freeze when the slash lands, then fades. About 0.4 s in all.
## Visual only: the damage comes from UltimateSkill.

## The stroke is laid down in this long.
const SWEEP_TIME: float = 0.11
## After the freeze the stroke fades for this long.
const FADE_TIME: float = 0.25
const POINTS: int = 24
const SPLATTER: int = 5
## How far the crescent reaches in front of the samurai, as a fraction of the screen width.
const REACH: float = 0.3
## Widest half-width of the stroke as a fraction of the screen height (about 34 px at 1080 p).
const HALF_WIDTH: float = 0.032
## Overall opacity: you can see the battle through it.
const OPACITY: float = 0.8

var _age: float = 0.0
var _hold: float = 0.15
var _facing: int = 1
var _seed: int = 1
## Screen y the slash passes through (the enemies' chest height); negative = a default height.
var _focus_y: float = -1.0
## Screen x the slash starts from (the samurai); negative = a default place.
var _focus_x: float = -1.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Per-point wobble of the stroke's width, fixed for the whole effect.
var _wobble: PackedFloat32Array = PackedFloat32Array()
var _splatter: Array[Vector3] = []


## `hold` = how long the game stays frozen (real seconds); the stroke fades after it.
func setup(facing: int, hold: float, random_seed: int = 0, focus_y: float = -1.0, focus_x: float = -1.0) -> void:
	_facing = 1 if facing >= 0 else -1
	_focus_y = focus_y
	_focus_x = focus_x
	_hold = maxf(hold, SWEEP_TIME)
	_seed = random_seed if random_seed != 0 else int(Time.get_ticks_usec() % 100000) + 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = _seed
	for i: int in POINTS:
		_wobble.append(_rng.randf_range(-1.0, 1.0))
	# Splatter: (u along the stroke, offset across it in half-widths, radius as a fraction of the height).
	for i: int in SPLATTER:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		_splatter.append(Vector3(_rng.randf_range(0.1, 0.95), side * _rng.randf_range(1.6, 2.6), _rng.randf_range(0.004, 0.0085)))


func _process(delta: float) -> void:
	_age += minf(delta / maxf(Engine.time_scale, 0.001), 0.1)
	if _age >= _hold + FADE_TIME:
		queue_free()
		return
	queue_redraw()


## Real seconds since the sweep began.
func get_age() -> float:
	return _age


## Total real lifetime.
func get_lifetime() -> float:
	return _hold + FADE_TIME


func _draw() -> void:
	var view: Vector2 = size
	if view.x < 2.0:
		return
	var reveal: float = ease(clampf(_age / SWEEP_TIME, 0.0, 1.0), 0.4)
	if reveal <= 0.0:
		return
	var fade: float = 1.0 - smoothstep(_hold, _hold + FADE_TIME, _age)
	_draw_stroke(view, reveal, fade * OPACITY)


## Centre line: a short rising crescent from the samurai forward, through the height of the enemies.
func _center(u: float, view: Vector2) -> Vector2:
	var start_x: float = _focus_x / view.x if _focus_x >= 0.0 else 0.4
	var x: float = clampf(start_x + float(_facing) * lerpf(0.03, REACH, u), 0.02, 0.98)
	var rise: float = lerpf(0.06, -0.06, u) - sin(PI * u) * 0.05
	var y: float = (_focus_y / view.y if _focus_y >= 0.0 else 0.6) + rise
	return Vector2(x * view.x, y * view.y)


func _half_width(u: float, index: int, view: Vector2) -> float:
	var profile: float = pow(maxf(sin(PI * u), 0.0), 0.8)
	return view.y * HALF_WIDTH * profile * (0.9 + 0.1 * _wobble[index])


func _draw_stroke(view: Vector2, reveal: float, alpha: float) -> void:
	var count: int = maxi(2, ceili(float(POINTS) * reveal))
	var centers: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector2Array = PackedVector2Array()
	var halves: PackedFloat32Array = PackedFloat32Array()
	for i: int in count:
		var u: float = reveal * float(i) / float(count - 1)
		var here: Vector2 = _center(u, view)
		var ahead: Vector2 = _center(minf(u + 0.01, 1.0), view)
		var behind: Vector2 = _center(maxf(u - 0.01, 0.0), view)
		centers.append(here)
		normals.append((ahead - behind).normalized().orthogonal())
		halves.append(_half_width(u, mini(i, POINTS - 1), view))

	var batch: InkBatch = InkBatch.new()
	# A crimson glow edge, a bright crimson body and a pale core: light, not ink.
	_ribbon(batch, centers, normals, halves, 1.3, -1.3, Color(InkPalette.SAMURAI_RED, 0.45 * alpha))
	_ribbon(batch, centers, normals, halves, 0.95, -0.95, Color(InkPalette.SAMURAI_RED.lightened(0.1), 0.8 * alpha))
	_ribbon(batch, centers, normals, halves, 0.5, -0.35, Color(InkPalette.PAPER, 0.85 * alpha))
	batch.draw(self)

	# A few small crimson drops near the stroke.
	var drops: InkBatch = InkBatch.new()
	for drop: Vector3 in _splatter:
		if drop.x > reveal:
			continue
		var index: int = clampi(roundi(drop.x / maxf(reveal, 0.001) * float(count - 1)), 0, count - 1)
		var at: Vector2 = centers[index] + normals[index] * drop.y * halves[index]
		drops.fill(InkEffect.blot_points(_rng_for(drop), at, drop.z * view.y, 0.85, 6), Color(InkPalette.SAMURAI_RED, 0.7 * alpha))
	drops.draw(self)


## A deterministic generator per splatter drop, so a drop keeps its shape every frame.
func _rng_for(drop: Vector3) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(drop.x * 100000.0) + _seed
	return rng


## A band along the stroke between two across-offsets (in units of the half width).
func _ribbon(batch: InkBatch, centers: PackedVector2Array, normals: PackedVector2Array, halves: PackedFloat32Array,
		upper: float, lower: float, color: Color) -> void:
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in centers.size():
		outer.append(centers[i] + normals[i] * halves[i] * upper)
		inner.append(centers[i] + normals[i] * halves[i] * lower)
		colors.append(color)
	batch.ribbon(outer, inner, colors, colors)
