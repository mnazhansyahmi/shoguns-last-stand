class_name UltimateSweep
extends Control
## The Ultimate's ink-brush sweep: one huge calligraphy stroke slashed across the whole screen
## (screen space, drawn on its own canvas layer), with a paper-white flash, a dark wash and ink
## splatter. It runs in REAL time (it divides out Engine.time_scale), so it keeps animating while
## the game is frozen for the dramatic pause, then fades out as the game resumes.
## Visual only: the damage comes from UltimateSkill.

## The stroke is laid down in this long.
const SWEEP_TIME: float = 0.15
const FLASH_TIME: float = 0.14
## After the pause the stroke fades for this long.
const FADE_TIME: float = 0.35
const POINTS: int = 30
const SPLATTER: int = 26
const STREAKS: int = 7

var _age: float = 0.0
var _hold: float = 0.4
var _facing: int = 1
var _seed: int = 1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Per-point wobble of the stroke's width, fixed for the whole effect.
var _wobble: PackedFloat32Array = PackedFloat32Array()
var _splatter: Array[Vector3] = []
var _streaks: Array[Vector3] = []
var _drips: Array[Vector3] = []


## `hold` = how long the game stays frozen (real seconds); the stroke fades after it.
func setup(facing: int, hold: float, random_seed: int = 0) -> void:
	_facing = 1 if facing >= 0 else -1
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
		_splatter.append(Vector3(_rng.randf_range(0.04, 0.98), _rng.randf_range(-1.7, 1.7), _rng.randf_range(0.012, 0.05)))
	# Dry-brush streaks: (offset across, start u, end u).
	for i: int in STREAKS:
		var start: float = _rng.randf_range(0.0, 0.55)
		_streaks.append(Vector3(_rng.randf_range(-0.8, 0.8), start, minf(start + _rng.randf_range(0.2, 0.55), 1.0)))
	# Drips hanging from the lower edge: (u, length as a fraction of the height, speed).
	for i: int in 7:
		_drips.append(Vector3(_rng.randf_range(0.12, 0.9), _rng.randf_range(0.03, 0.1), _rng.randf_range(0.6, 1.4)))


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
	var fade: float = 1.0 - smoothstep(_hold, _hold + FADE_TIME, _age)
	# Dark wash: it comes in with the flash and clears with the stroke.
	var wash: float = 0.42 * smoothstep(0.0, 0.12, _age) * fade
	draw_rect(Rect2(Vector2.ZERO, view), Color(InkPalette.INK, wash))
	var flash: float = 1.0 - clampf(_age / FLASH_TIME, 0.0, 1.0)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view), Color(InkPalette.PAPER, 0.6 * flash * flash))
	var reveal: float = ease(clampf(_age / SWEEP_TIME, 0.0, 1.0), 0.4)
	if reveal <= 0.0:
		return
	_draw_stroke(view, reveal, fade)


## Centre line of the stroke: a long crescent from the back of the screen to the front.
func _center(u: float, view: Vector2) -> Vector2:
	var x: float = lerpf(-0.12, 1.12, u) if _facing > 0 else lerpf(1.12, -0.12, u)
	var y: float = 0.66 - sin(PI * u) * 0.24
	return Vector2(x * view.x, y * view.y)


func _half_width(u: float, index: int, view: Vector2) -> float:
	var profile: float = pow(maxf(sin(PI * u), 0.0), 0.65)
	return view.y * 0.115 * profile * (0.88 + 0.12 * _wobble[index])


func _draw_stroke(view: Vector2, reveal: float, fade: float) -> void:
	var count: int = maxi(2, ceili(float(POINTS) * reveal))
	var centers: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector2Array = PackedVector2Array()
	var halves: PackedFloat32Array = PackedFloat32Array()
	for i: int in count:
		var u: float = reveal * float(i) / float(count - 1)
		var here: Vector2 = _center(u, view)
		var ahead: Vector2 = _center(minf(u + 0.01, 1.0), view)
		var behind: Vector2 = _center(maxf(u - 0.01, 0.0), view)
		var direction: Vector2 = (ahead - behind).normalized()
		centers.append(here)
		normals.append(direction.orthogonal())
		halves.append(_half_width(u, mini(i, POINTS - 1), view))

	# Crimson bleeds out from under the ink, then the black core, then the pale highlight.
	var batch: InkBatch = InkBatch.new()
	_ribbon(batch, centers, normals, halves, 1.3, -1.3, Color(InkPalette.SAMURAI_RED, 0.92 * fade))
	_ribbon(batch, centers, normals, halves, 0.96, -0.92, Color(InkPalette.INK, 0.97 * fade))
	# Dry-brush streaks: bristle marks across the core that break up the stroke.
	for streak: Vector3 in _streaks:
		var from_index: int = floori(streak.y * float(count - 1))
		var to_index: int = mini(ceili(streak.z * float(count - 1)), count - 1)
		if to_index - from_index < 2:
			continue
		var part_c: PackedVector2Array = centers.slice(from_index, to_index + 1)
		var part_n: PackedVector2Array = normals.slice(from_index, to_index + 1)
		var part_h: PackedFloat32Array = halves.slice(from_index, to_index + 1)
		_ribbon_offset(batch, part_c, part_n, part_h, streak.x, 0.035, Color(InkPalette.INK_DETAIL, 0.9 * fade))
	_ribbon(batch, centers, normals, halves, 0.86, 0.80, Color(InkPalette.PAPER, 0.85 * fade))
	batch.draw(self)

	# Splatter and drips around the stroke.
	var drops: InkBatch = InkBatch.new()
	for drop: Vector3 in _splatter:
		if drop.x > reveal:
			continue
		var index: int = clampi(roundi(drop.x / maxf(reveal, 0.001) * float(count - 1)), 0, count - 1)
		var at: Vector2 = centers[index] + normals[index] * drop.y * (halves[index] + view.y * 0.03)
		var color: Color = Color(InkPalette.INK if drop.y * drop.y < 2.2 else InkPalette.SAMURAI_RED, 0.95 * fade)
		drops.fill(InkEffect.blot_points(_rng_for(drop), at, drop.z * view.y, 0.85, 7), color)
	for drip: Vector3 in _drips:
		if drip.x > reveal:
			continue
		var index: int = clampi(roundi(drip.x / maxf(reveal, 0.001) * float(count - 1)), 0, count - 1)
		var top: Vector2 = centers[index] + Vector2(0.0, halves[index] * 0.9)
		var grown: float = clampf((_age - SWEEP_TIME) * drip.z, 0.0, 1.0)
		var length: float = view.y * drip.y * grown
		if length > 2.0:
			drops.stroke(PackedVector2Array([top, top + Vector2(0.0, length)]), 5.0, 3.0, Color(InkPalette.INK, 0.95 * fade))
			drops.circle(top + Vector2(0.0, length + 3.0), 5.0, Color(InkPalette.INK, 0.95 * fade))
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
