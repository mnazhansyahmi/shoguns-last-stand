class_name ClothChain
extends RefCounted
## A hanging strip of cloth (scarf, headband tail, sleeve flap) as a chain of points in WORLD
## space. The first point is pinned to an anchor on the body; the others follow it with inertia
## (Verlet integration), a soft pull toward a rest shape and a fixed link length, so cloth lags
## behind running, whips when the figure turns and settles after a lunge. Visual only.

## Physics sub-step (the chain is stable at this step for the stiffness used).
const STEP: float = 1.0 / 120.0

var points: PackedVector2Array = PackedVector2Array()
var previous: PackedVector2Array = PackedVector2Array()
## Length of one link in world pixels.
var link: float = 5.0
var _delta: float = -1.0
var _stiffness: float = -1.0
var _damping: float = -1.0
var _substeps: int = 1
var _keep: float = 1.0
var _pulls: PackedFloat64Array = PackedFloat64Array()


func _init(count: int, link_length: float) -> void:
	link = link_length
	points.resize(count + 1)
	previous.resize(count + 1)


## Puts every point on its rest position with no motion.
func reset(rest: PackedVector2Array) -> void:
	for i: int in mini(points.size(), rest.size()):
		points[i] = rest[i]
		previous[i] = rest[i]


## Advances the chain by `delta`. `rest` holds the target shape in world space (point 0 is the
## anchor). `stiffness` is the pull toward the rest shape (1/s^2) and `damping` the velocity loss (1/s).
func step(delta: float, rest: PackedVector2Array, stiffness: float, damping: float) -> void:
	if delta != _delta or stiffness != _stiffness or damping != _damping or _pulls.size() != points.size():
		_delta = delta
		_stiffness = stiffness
		_damping = damping
		_substeps = maxi(1, ceili(delta / STEP - 0.001))
		var h: float = delta / float(_substeps)
		_keep = exp(-damping * h)
		_pulls.resize(points.size())
		for i: int in range(1, points.size()):
			_pulls[i] = stiffness * (1.0 + 3.0 / float(i)) * h * h
	# Packed arrays are shared references. Keep local aliases for the inner
	# loops while preserving the existing in-place update semantics.
	var current: PackedVector2Array = points
	var old: PackedVector2Array = previous
	for n: int in _substeps:
		current[0] = rest[0]
		old[0] = rest[0]
		for i: int in range(1, current.size()):
			var here: Vector2 = current[i]
			var velocity: Vector2 = (here - old[i]) * _keep
			old[i] = here
			# Stiffer near the root, so the cloth leaves the body in the rest direction and whips at the tip.
			current[i] = here + velocity + (rest[i] - here) * _pulls[i]
		# Keep every link its length, root to tip.
		for i: int in range(1, current.size()):
			var offset: Vector2 = current[i] - current[i - 1]
			var length: float = offset.length()
			if length > 0.0001:
				current[i] = current[i - 1] + offset * (link / length)
			else:
				current[i] = current[i - 1] + Vector2(0.0, link)


## The chain's points in another space (e.g. a figure's local pixels).
func points_in(space: Transform2D) -> PackedVector2Array:
	return space * points
