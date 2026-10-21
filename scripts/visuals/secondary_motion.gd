class_name SecondaryMotion
extends RefCounted
## Secondary motion for an InkFigure: parts that lag behind the body instead of being rigid
## (see docs/ART_BIBLE.md, Animation rules). Cloth tails and sleeve flaps are ClothChains in world
## space (inertia, whip on turning); the hakama, the armour skirt (with the scabbard) and the
## shoulder lames swing on damped springs driven by how fast the body moves. InkFigure steps it from
## refresh() using the change in its `clock`; the painter reads the results. Visual only.

const STEP: float = 1.0 / 120.0
## Walking speed that counts as "1" when turning velocity into sway (px/s).
const RUN_SPEED: float = 210.0
## A jump in position bigger than this in one step is a teleport: cloth snaps instead of whipping.
const TELEPORT: float = 160.0


## A damped spring on one number.
class Spring:
	var value: float = 0.0
	var velocity: float = 0.0

	func step(target: float, omega: float, zeta: float, delta: float) -> void:
		var count: int = maxi(1, ceili(delta / SecondaryMotion.STEP - 0.001))
		var h: float = delta / float(count)
		for i: int in count:
			velocity += (omega * omega * (target - value) - 2.0 * zeta * omega * velocity) * h
			value += velocity * h


var scarf: Array[ClothChain] = []
var sleeve_front: ClothChain
var sleeve_back: ClothChain
var hair: ClothChain
var ornament: Spring = Spring.new()
## Swing of the armour skirt, scabbard and hakama front panel about the waist (rad, + = hem back).
var skirt: Spring = Spring.new()
## Swing of each hakama leg about its hip.
var leg_front: Spring = Spring.new()
var leg_back: Spring = Spring.new()
## Extra swing of the shoulder lames on top of the arm's own.
var sode_front: Spring = Spring.new()
var sode_back: Spring = Spring.new()

## Hakama, skirt, sleeves and shoulder lames swing too (only the samurai).
var loose_armour: bool = false
var _last_hip: Vector2 = Vector2.ZERO
var _seeded: bool = false


func is_initialized() -> bool:
	return _seeded


func _init(with_loose_armour: bool) -> void:
	loose_armour = with_loose_armour


## Moves everything on by `delta` seconds from the figure's current skeleton.
func step(fig: InkFigure, delta: float) -> void:
	var to_world: Transform2D = fig.global_transform
	var hip_world: Vector2 = to_world * (fig.root_xf * fig.hip)
	var forward_speed: float = 0.0
	if _seeded:
		var moved: Vector2 = hip_world - _last_hip
		if moved.length() > TELEPORT:
			_seeded = false
		else:
			# Along the way the figure faces: + = moving forward.
			forward_speed = to_world.basis_xform_inv(moved / delta).x
	_last_hip = hip_world
	var s: float = fig.get_unit_scale()
	_step_chains(fig, to_world, delta, s, not _seeded)
	if fig.kind == InkFigure.Kind.SAMURAI:
		_step_hair(fig, delta, not _seeded)
	var amount: float = 0.15 if GameSettings.reduced_decorative_motion else 1.0
	var wind: float = sin(fig.clock * 2.3) * 0.045 * amount
	ornament.step(wind + clampf(forward_speed / RUN_SPEED, -1.5, 1.5) * 0.11 * amount, 11.0, 0.6, delta)
	_seeded = true
	if not loose_armour:
		return
	var drive: float = clampf(forward_speed / RUN_SPEED, -2.5, 2.5)
	var breath: float = fig.breath * 0.015 * amount
	skirt.step(drive * 0.2 + breath, 13.0, 0.32, delta)
	leg_front.step(drive * 0.12, 11.0, 0.38, delta)
	leg_back.step(drive * 0.14 + breath, 9.5, 0.42, delta)
	var arm_front: Vector2 = fig.front_elbow - fig.spec.shoulder_front
	var arm_back: Vector2 = fig.back_elbow - fig.spec.shoulder_back
	sode_front.step(clampf(arm_front.angle() - PI * 0.5, -0.9, 0.7) * 0.5 + drive * 0.1, 17.0, 0.4, delta)
	sode_back.step(clampf(arm_back.angle() - PI * 0.5, -0.9, 0.7) * 0.5 + drive * 0.1, 15.0, 0.45, delta)


## World-space rest positions of the scarf / headband tail `tail` (point 0 = the anchor).
func tail_rest(fig: InkFigure, tail: int) -> PackedVector2Array:
	var spec: Array = _tail_spec(fig.kind)
	var anchor: Vector2 = _tail_anchor(fig)
	var counts: Array = spec[0]
	var segment: float = spec[1]
	var s: float = fig.get_unit_scale()
	var count: int = counts[tail]
	var rest: PackedVector2Array = PackedVector2Array()
	rest.append(anchor)
	var phase: float = float(tail) * 1.9
	var frequency: float = _cloth_response(fig.kind).x
	for i: int in range(1, count + 1):
		var k: float = float(i)
		var stream: Vector2 = Vector2(-k * (0.85 + 0.35 * fig.trail), k * (0.62 - 0.45 * fig.trail) + float(tail) * k * 0.22)
		var amount: float = 0.15 if GameSettings.reduced_decorative_motion else 1.0
		var wave: float = sin(fig.clock * (frequency + fig.trail * 4.0) - k * 0.9 + phase) * k * 0.7 * (0.85 + fig.trail) * amount
		rest.append(anchor + fig.global_transform.basis_xform((stream * segment + Vector2(0.0, wave)) * s))
	return rest


func _step_hair(fig: InkFigure, delta: float, snap: bool) -> void:
	var scale_now: float = fig.get_unit_scale() * absf(fig.global_scale.y)
	if hair == null:
		hair = ClothChain.new(6, 5.2 * scale_now)
		snap = true
	hair.link = 5.2 * scale_now
	var anchor: Vector2 = fig.global_transform * (fig.head_xf * Vector2(-4.0, -14.0))
	var rest: PackedVector2Array = PackedVector2Array([anchor])
	var amount: float = 0.15 if GameSettings.reduced_decorative_motion else 1.0
	for i: int in range(1, 7):
		var k: float = float(i)
		var flutter: float = sin(fig.clock * 2.4 - k * 0.65) * k * 0.45 * amount
		var offset: Vector2 = Vector2(-k * 5.0, -k * (0.2 + fig.trail * 0.6) + flutter)
		var target: Vector2 = anchor + fig.global_transform.basis_xform(offset * fig.get_unit_scale())
		rest.append(rest[-1] + (target - rest[-1]).normalized() * hair.link)
	if snap or GameSettings.reduced_decorative_motion:
		hair.reset(rest)
	else:
		hair.step(delta, rest, 130.0, 6.5)


## Where the tails are pinned (scarf at the neck, headband behind the head), in world pixels.
func _tail_anchor(fig: InkFigure) -> Vector2:
	if fig.kind == InkFigure.Kind.SAMURAI:
		return fig.global_transform * (fig.torso_xf * Vector2(-6.0, -4.0))
	if fig.kind in [InkFigure.Kind.SPEAR_GUARDIAN, InkFigure.Kind.HATAMOTO]:
		return fig.global_transform * (fig.torso_xf * Vector2(-7.0, -6.0))
	if fig.kind == InkFigure.Kind.ONMYOJI:
		return fig.global_transform * (fig.head_xf * Vector2(-7.0, -18.0))
	return fig.global_transform * (fig.head_xf * Vector2(-6.0, -9.5))


## [segment counts per tail, link length in figure units].
func _tail_spec(kind: InkFigure.Kind) -> Array:
	if kind == InkFigure.Kind.SAMURAI:
		return [[8, 7], 4.6]
	match kind:
		InkFigure.Kind.ASHIGARU: return [[5, 4], 2.8]
		InkFigure.Kind.YUMI_ARCHER: return [[5, 4], 3.6]
		InkFigure.Kind.SHRINE_HEALER: return [[5, 4], 3.2]
		InkFigure.Kind.SPEAR_GUARDIAN: return [[3, 3], 3.0]
		InkFigure.Kind.ONMYOJI: return [[5, 4], 4.0]
		_: return [[4, 3], 4.0]


## Frequency, restoring pull and damping reflect each ally's cloth weight.
func _cloth_response(kind: InkFigure.Kind) -> Vector3:
	match kind:
		InkFigure.Kind.ASHIGARU: return Vector3(3.3, 480.0, 6.0)
		InkFigure.Kind.YUMI_ARCHER: return Vector3(3.8, 520.0, 6.0)
		InkFigure.Kind.SHRINE_HEALER: return Vector3(2.0, 260.0, 7.0)
		InkFigure.Kind.SPEAR_GUARDIAN: return Vector3(2.1, 900.0, 8.0)
		InkFigure.Kind.ONMYOJI: return Vector3(2.4, 330.0, 6.5)
		InkFigure.Kind.HATAMOTO: return Vector3(2.5, 700.0, 7.0)
		_: return Vector3(3.0, 650.0, 5.0)


func _step_chains(fig: InkFigure, to_world: Transform2D, delta: float, s: float, snap: bool) -> void:
	var world_scale: float = absf(to_world.get_scale().y)
	if fig.spec.cloth:
		var tail_spec: Array = _tail_spec(fig.kind)
		var counts: Array = tail_spec[0]
		var link: float = float(tail_spec[1]) * 1.07 * s * world_scale
		if scarf.is_empty():
			for count: int in counts:
				scarf.append(ClothChain.new(count, link))
			snap = true
		for tail: int in scarf.size():
			var rest: PackedVector2Array = tail_rest(fig, tail)
			scarf[tail].link = link
			if snap or GameSettings.reduced_decorative_motion:
				scarf[tail].reset(rest)
			else:
				var response: Vector3 = _cloth_response(fig.kind)
				scarf[tail].step(delta, rest, response.y, response.z)
	if not loose_armour:
		return
	var sleeve_link: float = fig.spec.sleeve_link * s * world_scale
	if sleeve_front == null:
		sleeve_front = ClothChain.new(2, sleeve_link)
		sleeve_back = ClothChain.new(2, sleeve_link)
		snap = true
	sleeve_front.link = sleeve_link
	sleeve_back.link = sleeve_link
	_step_sleeve(fig, to_world, sleeve_front, fig.spec.shoulder_front, fig.front_elbow, delta, s, snap)
	_step_sleeve(fig, to_world, sleeve_back, fig.spec.shoulder_back, fig.back_elbow, delta, s, snap)


func _step_sleeve(fig: InkFigure, to_world: Transform2D, chain: ClothChain, shoulder: Vector2, elbow: Vector2,
		delta: float, s: float, snap: bool) -> void:
	var anchor: Vector2 = to_world * (fig.torso_xf * shoulder.lerp(elbow, 0.75))
	var hang: Vector2 = Vector2(0.0, 1.0) * s * absf(to_world.get_scale().y)
	var side: Vector2 = to_world.basis_xform(Vector2(-0.35, 0.0)) * s
	if not GameSettings.reduced_decorative_motion:
		side += to_world.basis_xform(Vector2(sin(fig.clock * 2.4) * 0.35, 0.0)) * s
	var link: float = fig.spec.sleeve_link
	var rest: PackedVector2Array = PackedVector2Array([anchor, anchor + hang * link + side * link, anchor + hang * link * 1.96 + side * link * 1.92])
	if snap:
		chain.reset(rest)
	else:
		chain.step(delta, rest, 420.0, 5.5)
