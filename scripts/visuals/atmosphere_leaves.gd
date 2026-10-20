class_name AtmosphereLeaves
extends Node2D
## Red maple leaves and pale petals drifting down on the wind. Two instances make the depth: a
## background layer of small, dim leaves behind the fighters and a foreground layer of a few big,
## fast ones passing in front. They share the Atmosphere wind, so a gust carries them all. A leaf
## tumbles (it flips as it spins) and sways; one that leaves the screen is reborn upwind or above.
## Cheap by design: a few dozen leaves, simulated on packed arrays and drawn as one batch.
## Visual only: nothing here touches gameplay.

## Unit shapes (a leaf of radius 1): a centre diamond with a lobe each side, and a petal.
static var LEAF_PARTS: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(0.0, -1.0), Vector2(0.42, -0.05), Vector2(0.0, 0.95), Vector2(-0.42, -0.05)]),
	PackedVector2Array([Vector2(-0.12, -0.2), Vector2(-0.98, -0.4), Vector2(-0.82, 0.12), Vector2(-0.22, 0.38)]),
	PackedVector2Array([Vector2(0.12, -0.2), Vector2(0.98, -0.4), Vector2(0.82, 0.12), Vector2(0.22, 0.38)]),
]
static var PETAL: PackedVector2Array = PackedVector2Array([Vector2(0.0, -1.0), Vector2(0.62, -0.25), Vector2(0.42, 0.85),
		Vector2(-0.42, 0.85), Vector2(-0.62, -0.25)])
const MARGIN: float = 120.0

## Foreground leaves are bigger, faster and fully lit; background ones are small and dimmer.
@export var foreground: bool = false
@export var count: int = 24
@export var seed_value: int = 7

var _position: PackedVector2Array = PackedVector2Array()
var _velocity: PackedVector2Array = PackedVector2Array()
var _angle: PackedFloat32Array = PackedFloat32Array()
var _spin: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _color: PackedColorArray = PackedColorArray()
var _is_petal: PackedByteArray = PackedByteArray()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _clock: float = 0.0
var _started: bool = false
## Screen rectangles (HUD, touch controls) the leaves stay out of: a leaf over one is not drawn.
var keep_out: Array[Rect2] = []


func _ready() -> void:
	_rng.seed = seed_value
	_position.resize(count)
	_velocity.resize(count)
	_angle.resize(count)
	_spin.resize(count)
	_phase.resize(count)
	_size.resize(count)
	_color.resize(count)
	_is_petal.resize(count)
	for i: int in count:
		_respawn(i, true)


## Gives every leaf a new look from the (new) theme.
func apply_theme() -> void:
	for i: int in _position.size():
		_color[i] = _pick_color(i)


func _process(delta: float) -> void:
	var step: float = minf(delta, 0.05)
	_clock += step
	var view: Rect2 = _view_rect()
	if not _started:
		_started = true
		for i: int in count:
			_respawn(i, true, view)
	var wind: float = Atmosphere.wind_at(view.get_center().x)
	var push: float = 150.0 + (110.0 if foreground else 0.0)
	var speed_scale: float = 1.55 if foreground else 1.0
	for i: int in count:
		var size_factor: float = _size[i] / (15.0 if foreground else 12.0)
		var velocity: Vector2 = _velocity[i]
		# The wind carries the leaf sideways (lighter ones more); it sinks and sways as it falls.
		velocity.x = lerpf(velocity.x, wind * push * (1.3 - 0.4 * size_factor), minf(step * 1.2, 1.0))
		velocity.x += sin(_clock * 2.3 + _phase[i]) * 36.0 * step
		var fall: float = (_is_petal[i] * -14.0 + 52.0) * speed_scale * (0.8 + 0.3 * wind)
		velocity.y = lerpf(velocity.y, fall + sin(_clock * 3.1 + _phase[i] * 2.0) * 22.0, minf(step * 2.0, 1.0))
		_velocity[i] = velocity
		_position[i] += velocity * step
		_angle[i] += _spin[i] * step * (0.6 + wind)
		var p: Vector2 = _position[i]
		if p.y > view.end.y + MARGIN or p.x > view.end.x + MARGIN or p.x < view.position.x - MARGIN * 2.0:
			_respawn(i, false, view)
	queue_redraw()


func _draw() -> void:
	var batch: InkBatch = InkBatch.new()
	var to_screen: Transform2D = Transform2D.IDENTITY
	if not keep_out.is_empty() and is_inside_tree():
		to_screen = get_viewport().get_canvas_transform() * get_global_transform()
	for i: int in _position.size():
		if not keep_out.is_empty() and _in_keep_out(to_screen * _position[i], _size[i]):
			continue
		# A tumbling leaf: its width follows the cosine of its flip angle.
		var flip: float = cos(_clock * 2.6 + _phase[i] * 3.0)
		var xf: Transform2D = Transform2D(_angle[i], Vector2(_size[i] * (0.25 + 0.75 * absf(flip)), _size[i]), 0.0, _position[i])
		var color: Color = _color[i]
		if flip < 0.0:
			color = color.darkened(0.18)
		if _is_petal[i] == 1:
			batch.fill_convex(xf * PETAL, color)
		else:
			for part: PackedVector2Array in LEAF_PARTS:
				batch.fill_convex(xf * part, color)
	batch.draw(self)


## True if a leaf of `radius` (world px) at screen position `screen` touches a keep-out rectangle.
func _in_keep_out(screen: Vector2, radius: float) -> bool:
	for rect: Rect2 in keep_out:
		if rect.grow(radius * 1.5).has_point(screen):
			return true
	return false


## World rect the screen shows right now (falls back to the design screen without a viewport).
func _view_rect() -> Rect2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return Rect2(-100.0, 0.0, 1920.0, 1080.0)
	var rect: Rect2 = viewport.get_visible_rect()
	return viewport.get_canvas_transform().affine_inverse() * rect


## Puts leaf `i` back at the top or the upwind side of the screen (anywhere on it at the start).
func _respawn(i: int, anywhere: bool, view: Rect2 = Rect2(-100.0, 0.0, 1920.0, 1080.0)) -> void:
	var theme_now: AtmosphereTheme = Atmosphere.current()
	_is_petal[i] = 1 if _rng.randf() < theme_now.petal_share else 0
	var base_size: float = _rng.randf_range(11.0, 19.0) if foreground else _rng.randf_range(8.0, 15.0)
	_size[i] = base_size * (0.7 if _is_petal[i] == 1 else 1.0)
	if anywhere:
		_position[i] = Vector2(_rng.randf_range(view.position.x, view.end.x), _rng.randf_range(view.position.y, view.end.y))
	elif _rng.randf() < 0.65:
		_position[i] = Vector2(_rng.randf_range(view.position.x - MARGIN, view.end.x), view.position.y - _rng.randf_range(20.0, MARGIN))
	else:
		_position[i] = Vector2(view.position.x - _rng.randf_range(20.0, MARGIN), _rng.randf_range(view.position.y, view.end.y * 0.8))
	_velocity[i] = Vector2(_rng.randf_range(20.0, 80.0), _rng.randf_range(20.0, 60.0))
	_angle[i] = _rng.randf() * TAU
	_spin[i] = _rng.randf_range(-2.4, 2.4)
	_phase[i] = _rng.randf() * TAU
	_color[i] = _pick_color(i)


func _pick_color(i: int) -> Color:
	var theme_now: AtmosphereTheme = Atmosphere.current()
	var base: Color = theme_now.petal_color if _is_petal[i] == 1 else theme_now.leaf_colors[i % theme_now.leaf_colors.size()]
	return Color(base, 1.0 if foreground else 0.78)
