class_name LegGait
extends RefCounted
## World-space stance anchors survive body bob, pose blending, speed changes and mirroring.
## Only swing feet may move. Phase is distance-driven: a stopped actor cannot moonwalk.
var phase: float = 0.0
## The phase a fresh stance starts from (each soldier of a crowd its own, so they never march in step).
var start_phase: float = 0.0
var targets: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var planted: Array[bool] = [true, true]
var heel: Array[float] = [0.0, 0.0]
var hip_shift: float = 0.0
var bob: float = 0.0
var counter_turn: float = 0.0
var run_weight: float = 0.0
var _anchors: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _starts: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _previous: Vector2 = Vector2.ZERO
var _basis: Vector2 = Vector2.RIGHT
var _ready: bool = false
var _last_rate: float = 1.0
var _direction: float = 1.0
var _extent: float = 0.0
## The frame of the last step, and whether that step left both feet planted with nothing moving: the same frame
## again would give exactly the same stance, so it is skipped.
var _last_frame: Transform2D = Transform2D.IDENTITY
var _at_rest: bool = false


func reset() -> void:
	_ready = false
	_at_rest = false
	_extent = 0.0


func is_settled() -> bool:
	return _at_rest


func step(frame: Transform2D, spec: FigureKinds.Spec, delta: float) -> void:
	if _at_rest and frame == _last_frame:
		return
	var inverse: Transform2D = frame.affine_inverse()
	if not _ready or frame.origin.distance_to(_previous) > 160.0 or frame.x.dot(_basis) < 0.0:
		var width: float = (spec.stance.x - spec.stance.y) * 0.5
		_anchors[0] = frame * Vector2(width, 0.0)
		_anchors[1] = frame * Vector2(-width, 0.0)
		_previous = frame.origin
		_basis = frame.x
		phase = start_phase
		planted = [true, true]
		_ready = true
	var travel: float = (inverse * frame.origin - inverse * _previous).x
	_previous = frame.origin
	var speed: float = absf(travel) / maxf(delta, 0.0001)
	var moving: bool = speed > 0.5
	if moving:
		_direction = signf(travel)
	# Heavy figures keep long support times; the Hollow drags one leg and never flies.
	run_weight = smoothstep(spec.run_speed * 0.7, spec.run_speed * 1.2, speed) if not spec.heavy_gait and not spec.limp else 0.0
	var duty: float = lerpf(0.64, 0.43, run_weight)
	# Longer steps at speed avoid the old rapid shuffle. The reach cap is still
	# inside the two-bone envelope; heavy and limping figures keep their character.
	var length_factor: float = lerpf(0.65, 1.75, clampf(speed / spec.run_speed, 0.0, 1.0))
	if spec.heavy_gait or spec.limp:
		length_factor = lerpf(0.65, 1.2, clampf(speed / spec.run_speed, 0.0, 1.0))
	var desired_extent: float = minf(spec.stride_len * length_factor, (spec.thigh + spec.shin) * 0.5)
	_extent = desired_extent if _extent <= 0.0 else lerpf(_extent, desired_extent, 1.0 - exp(-12.0 * delta))
	var extent: float = _extent
	var cycle_distance: float = 2.0 * extent / duty
	if moving:
		_last_rate = speed / cycle_distance
		phase = fposmod(phase + absf(travel) / cycle_distance, 1.0)
	elif not planted[0] or not planted[1]:
		phase = fposmod(phase + _last_rate * delta, 1.0)
	for side: int in 2:
		var own_phase: float = fposmod(phase + side * 0.5, 1.0)
		var own_duty: float = duty + (0.09 if spec.limp and side == 1 else 0.0)
		var support: bool = own_phase < own_duty
		if not moving and planted[side]:
			support = true
		if not support:
			if planted[side]:
				_starts[side] = _anchors[side]
			planted[side] = false
			var swing: float = (own_phase - own_duty) / (1.0 - own_duty)
			var reach: float = extent * (0.72 if spec.limp and side == 1 else 1.0)
			var landing: Vector2 = frame * Vector2(_direction * reach + (2.0 if side == 0 else -2.0), 0.0)
			var world: Vector2 = _starts[side].lerp(landing, smoothstep(0.0, 1.0, swing))
			targets[side] = inverse * world
			# Zero vertical velocity at takeoff and touchdown instead of a sharp
			# triangular-looking lift. Heel rolls gently flat before full contact.
			var arc: float = sin(PI * swing)
			targets[side].y = -arc * arc * spec.lift * (0.35 if spec.limp and side == 1 else 1.0) * (1.0 + run_weight * 0.5)
			heel[side] = -0.18 * smoothstep(0.35, 0.7, swing) * (1.0 - smoothstep(0.85, 1.0, swing))
			_anchors[side] = frame * Vector2(targets[side].x, 0.0)
		else:
			planted[side] = true
			targets[side] = inverse * _anchors[side]
			targets[side].y = 0.0
			heel[side] = 0.0
	# contact/down/passing/up: two compressions and rises per full left/right cycle.
	var wave: float = -sin(phase * TAU * 2.0)
	bob = (0.6 + run_weight * 1.4) * wave if moving else 0.0
	var stance_center: float = (targets[0].x + targets[1].x) * 0.5
	# The former hard switch between feet also snapped the pelvis horizontally.
	# Both trajectories contribute continuously through double support and flight.
	hip_shift = clampf(stance_center * 0.12, -1.4, 1.4) if moving else stance_center
	counter_turn = sin(phase * TAU) * (0.018 if spec.heavy_gait else 0.035) if moving else 0.0
	_last_frame = frame
	_at_rest = not moving and planted[0] and planted[1]
