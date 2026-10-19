class_name UltimateSweep
extends Control
## The Ultimate's ink-brush slash: one fast, thin calligraphy stroke drawn across the enemy area
## (screen space, on its own canvas layer). It is semi-transparent and slim on purpose, so the
## fight stays visible underneath; there is no screen wash and only a few small ink drops.
## It runs in REAL time (it divides out Engine.time_scale), so it keeps animating during the brief
## freeze when the slash lands, then fades. About 0.4 s in all.
## Visual only: the damage comes from UltimateSkill.

## The stroke is laid down in this long.
const SWEEP_TIME: float = 0.11
## After the freeze the stroke fades for this long.
const FADE_TIME: float = 0.25
const POINTS: int = 24
const SPLATTER: int = 6
const STREAKS: int = 3
## Widest half-width of the stroke as a fraction of the screen height (about 12 px at 1080 p).
const HALF_WIDTH: float = 0.017
## Overall opacity: you can see the battle through it.
const OPACITY: float = 0.85

var _age: float = 0.0
var _hold: float = 0.15
var _facing: int = 1
var _seed: int = 1
## Screen y the slash passes through (the enemies' chest height); negative = a default height.
var _focus_y: float = -1.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Per-point wobble of the stroke's width, fixed for the whole effect.
var _wobble: PackedFloat32Array = PackedFloat32Array()
var _splatter: Array[Vector3] = []
var _streaks: Array[Vector3] = []


## `hold` = how long the game stays frozen (real seconds); the stroke fades after it.
func setup(facing: int, hold: float, random_seed: int = 0, focus_y: float = -1.0) -> void:
	_facing = 1 if facing >= 0 else -1
	_focus_y = focus_y
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
	# Dry-brush streaks: (offset across, start u, end u).
	for i: int in STREAKS:
		var start: float = _rng.randf_range(0.05, 0.5)
		_streaks.append(Vector3(_rng.randf_range(-0.5, 0.5), start, minf(start + _rng.randf_range(0.25, 0.5), 1.0)))


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


## Centre line: a shallow rising slash through the height of the enemies, back to front.
func _center(u: float, view: Vector2) -> Vector2:
	var x: float = lerpf(0.02, 0.98, u) if _facing > 0 else lerpf(0.98, 0.02, u)
	var rise: float = lerpf(0.05, -0.05, u) - sin(PI * u) * 0.03
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
	# A fine crimson edge, the ink core, a few dry-brush streaks and a pale glint on the top edge.
	_ribbon(batch, centers, normals, halves, 1.35, -1.35, Color(InkPalette.SAMURAI_RED, 0.7 * alpha))
	_ribbon(batch, centers, normals, halves, 0.9, -0.9, Color(InkPalette.INK, 0.8 * alpha))
	for streak: Vector3 in _streaks:
		var from_index: int = floori(streak.y * float(count - 1))
		var to_index: int = mini(ceili(streak.z * float(count - 1)), count - 1)
		if to_index - from_index < 2:
			continue
		_ribbon_offset(batch, centers.slice(from_index, to_index + 1), normals.slice(from_index, to_index + 1),
				halves.slice(from_index, to_index + 1), streak.x, 0.12, Color(InkPalette.PAPER, 0.35 * alpha))
	_ribbon(batch, centers, normals, halves, 0.8, 0.62, Color(InkPalette.PAPER, 0.7 * alpha))
	batch.draw(self)

	# A few small ink drops near the stroke.
	var drops: InkBatch = InkBatch.new()
	for drop: Vector3 in _splatter:
		if drop.x > reveal:
			continue
		var index: int = clampi(roundi(drop.x / maxf(reveal, 0.001) * float(count - 1)), 0, count - 1)
		var at: Vector2 = centers[index] + normals[index] * drop.y * halves[index]
		drops.fill(InkEffect.blot_points(_rng_for(drop), at, drop.z * view.y, 0.85, 6), Color(InkPalette.INK, 0.75 * alpha))
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


## A thin band centred at `across` half-widths, `thickness` (fraction of the half width) wide.
func _ribbon_offset(batch: InkBatch, centers: PackedVector2Array, normals: PackedVector2Array, halves: PackedFloat32Array,
		across: float, thickness: float, color: Color) -> void:
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in centers.size():
		var taper: float = sin(PI * float(i) / float(maxi(centers.size() - 1, 1)))
		var mid: Vector2 = centers[i] + normals[i] * halves[i] * across
		outer.append(mid + normals[i] * halves[i] * thickness * taper)
		inner.append(mid - normals[i] * halves[i] * thickness * taper)
		colors.append(color)
	batch.ribbon(outer, inner, colors, colors)
