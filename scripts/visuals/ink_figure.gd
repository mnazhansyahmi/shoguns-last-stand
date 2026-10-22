class_name InkFigure
extends Node2D
## A procedurally drawn ink-silhouette character (see docs/ART_BIBLE.md).
## UnitVisual writes the live pose and motion fields every frame, then calls refresh(), which
## solves a small skeleton (hips, two-bone IK legs and arms, torso, head, weapon) and moves one
## child FigurePart per body part. Parts draw shapes cached per kind (FigurePainter) once, so a
## frame costs a few transforms per part and no geometry work; only cloth and the Hollow
## Soldier's hem are repainted. Feet are at the origin and the figure faces +x; the parent
## mirrors it for facing left. Glowing spots are additive child parts that fade by alpha.

enum Kind { SAMURAI, ASHIGARU, YUMI_ARCHER, HOLLOW_SOLDIER, ONI_BRUTE, SHRINE_HEALER, SPEAR_GUARDIAN, ONMYOJI, HATAMOTO, FALLEN_DAIMYO,
	SPECTRAL_ARCHER, SHIELD_BEARER, FLYING_SPIRIT, BURNING_GENERAL }

## Figure units per figure height (all proportions are authored at height 100).
const UNIT: float = 100.0
## Rotation of a fallen body (backward around the feet).
const FALL_ANGLE: float = -1.45
const SHADOW_ALPHA: float = 0.3
## modulate at full hit flash: lightens near-black ink a little (it must stay a dark silhouette).
const FLASH_MODULATE: Color = Color(2.4, 2.3, 2.2, 1.0)
## modulate at the full gold flash of a rallied ally (the War Cry reaching it).
const GOLD_MODULATE: Color = Color(3.0, 2.2, 0.7, 1.0)

static var _additive: CanvasItemMaterial

@export var kind: Kind = Kind.SAMURAI:
	set = set_kind
## Body height in pixels (body_size.y of the unit's data).
@export var height: float = 110.0

var pose: FigurePose = FigurePose.new()
var spec: FigureKinds.Spec = FigureKinds.spec(Kind.SAMURAI)

# Motion written by UnitVisual.
var gait: LegGait = LegGait.new()
## Crowd variety (UnitVisual.enable_variation): an extra forward lean of the torso, an extra tilt of the head (and
## the hat on it), and a bare head where the kind has one (RosterSpriteArt.BARE_HEADS).
var hunch: float = 0.0
var head_cant: float = 0.0
var bare_head: bool = false:
	set(value):
		bare_head = value
		_apply_bare_head()
var gait_enabled: bool = false
var upright: bool = false
## Presentation-only equipment choice; combat figures show the stowed yumi by default.
var show_stowed_bow: bool = true
var stride: float = 0.0
var stride_phase: float = 0.0
var bob: float = 0.0
## -1..1 breathing cycle.
var breath: float = 0.0
## Random phase of the glow's flicker, so a crowd's lights do not pulse together.
var flicker_phase: float = 0.0
## A boss's phase (1..3): more of its lights show and they burn brighter (FigurePainter.glows rage_min).
var rage: int = 1
## 0 = standing still, 1 = running (cloth streams back).
var trail: float = 0.0
## Seconds, drives cloth flutter.
var clock: float = 0.0
## 0..1 hit flash (brightens the whole figure toward paper).
var flash: float = 0.0
## 0..1 gold flash (an ally the War Cry reaches).
var gold_flash: float = 0.0
## 0 = standing, 1 = lying on the ground.
var fall: float = 0.0
## Vertical scale (spawn rise).
var squash: float = 1.0
## Colour of a ring on the ground under the feet (alpha 0 = none). Marks the player in a crowd.
var ground_marker: Color = Color(0.0, 0.0, 0.0, 0.0):
	set = set_ground_marker

# Skeleton, solved by refresh(). Root space: feet at origin, figure units.
# The transforms map their space to this node's local pixels.
var root_xf: Transform2D = Transform2D.IDENTITY
var torso_xf: Transform2D = Transform2D.IDENTITY
var head_xf: Transform2D = Transform2D.IDENTITY
var weapon_xf: Transform2D = Transform2D.IDENTITY
## Weapon transform in torso space.
var weapon_local: Transform2D = Transform2D.IDENTITY
var hip: Vector2 = Vector2.ZERO
var front_ankle: Vector2 = Vector2.ZERO
var back_ankle: Vector2 = Vector2.ZERO
var front_knee: Vector2 = Vector2.ZERO
var back_knee: Vector2 = Vector2.ZERO
# Torso space.
var front_hand: Vector2 = Vector2.ZERO
var back_hand: Vector2 = Vector2.ZERO
var front_elbow: Vector2 = Vector2.ZERO
var back_elbow: Vector2 = Vector2.ZERO

## Cloth and loose armour that lag behind the body (null for kinds without any).
var secondary: SecondaryMotion

var _secondary_clock: float = 0.0
var _cloth_redraw_frame: int = -1
var _parts: Array[FigurePart] = []
var _part_slots: PackedInt32Array = PackedInt32Array()
var _dynamic_parts: Array[FigurePart] = []
var _fall_glows: Array[FigurePart] = []
## How deeply each of _fall_glows flickers (0 = steady), index for index.
var _glow_flicker: PackedFloat32Array = PackedFloat32Array()
## The rage level each of _fall_glows first shows at, index for index.
var _glow_rage_min: PackedInt32Array = PackedInt32Array()
var _pose_glows: Array[FigurePart] = []
var _bow_part: FigurePart
var _bow_step: int = -1
## The samurai's katana and his yumi stowed on his back.
var _weapon_part: FigurePart
var _back_bow_part: FigurePart
var _hem_part: FigurePart
var _hem_key: int = -1
var _blade_glow_part: FigurePart
var _slot_xf: Array[Transform2D] = []
var _has_armour: bool = false
var _has_skirt: bool = false
var _has_hakama: bool = false
var _arm_front_key: Vector2 = Vector2(INF, INF)
var _arm_back_key: Vector2 = Vector2(INF, INF)
var _upper_front: Transform2D
var _fore_front: Transform2D
var _upper_back: Transform2D
var _fore_back: Transform2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_parts()
	refresh()


static func additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = InkBrush.additive_material()
	return _additive


func _apply_bare_head() -> void:
	var head: FigurePart = get_node_or_null("head") as FigurePart
	if head == null:
		return
	head.art_mesh = RosterSpriteArt.bare_head_mesh(kind) if bare_head and RosterSpriteArt.BARE_HEADS.has(kind) else []
	head.queue_redraw()


func set_kind(value: Kind) -> void:
	kind = value
	spec = FigureKinds.spec(value)
	gait.reset()
	_arm_front_key = Vector2(INF, INF)
	_arm_back_key = Vector2(INF, INF)
	secondary = SecondaryMotion.new(spec.loose_armour) if spec.cloth or spec.loose_armour else null
	pose.copy_from(FigureKinds.pose(value, &"idle"))
	if is_inside_tree():
		_build_parts()
		refresh()


func set_ground_marker(value: Color) -> void:
	var changed: bool = value != ground_marker
	ground_marker = value
	if changed and is_inside_tree():
		_build_parts()
		refresh()


## Pixel scale from figure units.
func get_unit_scale() -> float:
	return height / UNIT


## Local y of the top of the head (or hat/horns), for health bars. Negative = above the feet.
func get_head_top_y() -> float:
	return -height * spec.head_top / UNIT


## Blade tip of the held weapon in local pixels.
func get_weapon_point(along: float) -> Vector2:
	return weapon_xf * Vector2(along, 0.0)


## Where the held weapon would be for `for_pose` (with the current body motion): the points
## `along_from` and `along_to` along it, in local pixels. Used to sweep slash trails.
func weapon_points_for(for_pose: FigurePose, along_from: float, along_to: float) -> PackedVector2Array:
	var hips: Transform2D = Transform2D(for_pose.lean, Vector2(0.0, -(spec.hip_y - for_pose.crouch)))
	var xf: Transform2D = _root_for(for_pose) * hips * Transform2D(for_pose.blade, for_pose.grip)
	return PackedVector2Array([xf * Vector2(along_from, 0.0), xf * Vector2(along_to, 0.0)])


## Points spread over the body (feet to head and hands), in local pixels. Death ink rises
## from these.
func get_body_points() -> PackedVector2Array:
	return PackedVector2Array([root_xf * front_ankle, root_xf * back_ankle,
			root_xf * front_knee, root_xf * back_knee, root_xf * hip, torso_xf * Vector2(0.0, spec.neck.y * 0.5),
			torso_xf * spec.shoulder_front, torso_xf * spec.shoulder_back, head_xf * Vector2(1.0, -8.0),
			torso_xf * front_hand, torso_xf * back_hand])


## Number of body part nodes (for tests and diagnostics).
func get_part_count() -> int:
	return _parts.size()


func _root_for(for_pose: FigurePose) -> Transform2D:
	var s: float = get_unit_scale()
	var lift: float = fall * spec.lie_lift
	# Spawn squash belongs to the upper body. Scaling the leg frame would shorten its bones.
	return Transform2D(fall * FALL_ANGLE, Vector2(s, s), 0.0,
			Vector2(for_pose.offset_x * s, -lift * s))


## Solves the skeleton from the pose fields and moves the parts.
func refresh() -> void:
	root_xf = _root_for(pose)

	hip = Vector2(pose.hip_shift, -(spec.hip_y - pose.crouch) - bob)
	var swing: float = sin(stride_phase) * stride * spec.stride_len
	var front_foot: Vector2 = Vector2(spec.stance.x * pose.spread + swing + pose.lunge, -maxf(0.0, cos(stride_phase)) * stride * spec.lift)
	var back_foot: Vector2 = Vector2(spec.stance.y * pose.spread - swing, -maxf(0.0, -cos(stride_phase)) * stride * spec.lift)
	if gait_enabled:
		front_foot = gait.targets[0] - Vector2(pose.offset_x, 0.0)
		back_foot = gait.targets[1] - Vector2(pose.offset_x, 0.0)
		hip.x += gait.hip_shift
	front_ankle = front_foot + Vector2(0.0, -_sole_height(gait.heel[0] if gait_enabled else 0.0))
	back_ankle = back_foot + Vector2(0.0, -_sole_height(gait.heel[1] if gait_enabled else 0.0))
	# Limit extreme authored lunges to horizontal reach, without scaling either bone.
	var reach_x: float = (spec.thigh + spec.shin) * 0.85
	if not gait_enabled:
		front_ankle.x = clampf(front_ankle.x, hip.x + 2.0 - reach_x, hip.x + 2.0 + reach_x)
		back_ankle.x = clampf(back_ankle.x, hip.x - 2.0 - reach_x, hip.x - 2.0 + reach_x)
	if upright:
		hip.x = (front_ankle.x + back_ankle.x) * 0.5 + sin(clock * 0.8) * 0.12
		var dx: float = maxf(absf(front_ankle.x - hip.x - 2.0), absf(back_ankle.x - hip.x + 2.0))
		var reach: float = spec.thigh + spec.shin - 0.06
		hip.y = -LegIK.SOLE - sqrt(maxf(0.0, reach * reach - dx * dx))
		if spec.heavy_gait:
			hip.y += 0.65 * (1.0 + sin(clock * 2.1))
	elif gait_enabled:
		# A continuous envelope from BOTH legs avoids a pelvis pop whenever the
		# selected support foot changes (especially during the flight interval).
		var front_dx: float = front_ankle.x - hip.x - 2.0
		var back_dx: float = back_ankle.x - hip.x + 2.0
		var standing_reach: float = spec.thigh + spec.shin - 0.3 - gait.run_weight * 0.6
		var widest: float = maxf(front_dx * front_dx, back_dx * back_dx)
		hip.y = -LegIK.SOLE - sqrt(maxf(0.0, standing_reach * standing_reach - widest)) - bob * 0.45
	hip = LegIK.fit_hip(hip, front_ankle, back_ankle, spec.thigh, spec.shin)
	front_knee = LegIK.knee(hip + Vector2(2.0, 0.0), front_ankle, spec.thigh, spec.shin)
	back_knee = LegIK.knee(hip + Vector2(-2.0, 0.0), back_ankle, spec.thigh, spec.shin)

	_lift_fallen_legs()
	torso_xf = root_xf * Transform2D(pose.lean + hunch + (gait.counter_turn if gait_enabled else 0.0), Vector2(1.0, (1.0 + spec.breath_amp * breath) * maxf(squash, 0.05)), 0.0, hip)
	head_xf = torso_xf * Transform2D(pose.head_tilt + head_cant + breath * 0.02, spec.neck)
	weapon_local = Transform2D(pose.blade, pose.grip)
	weapon_xf = torso_xf * weapon_local
	_rest_weapon_on_ground()
	weapon_local = torso_xf.affine_inverse() * weapon_xf
	if kind == Kind.ONI_BRUTE or FigureKinds.animation_kind(kind) == Kind.FALLEN_DAIMYO:
		# During transitions and ground clearance, the two grip targets must remain
		# inside both arm reach discs. Move the held weapon, never stretch a bone.
		for pass_index: int in 3:
			var fitted: Vector2 = weapon_local.origin
			var reach: float = spec.upper_arm + spec.fore_arm - 0.1
			fitted = spec.shoulder_front + (fitted - spec.shoulder_front).limit_length(reach)
			if not is_nan(spec.back_hand_on_weapon.x):
				var far_center: Vector2 = spec.shoulder_back - weapon_local.basis_xform(spec.back_hand_on_weapon)
				fitted = far_center + (fitted - far_center).limit_length(reach)
			if fitted.distance_squared_to(weapon_local.origin) < 0.000001: break
			weapon_local.origin = fitted
			weapon_xf = torso_xf * weapon_local
			_rest_weapon_on_ground()
			weapon_local = torso_xf.affine_inverse() * weapon_xf

	front_hand = weapon_local.origin
	var bow_hands: bool = FigureKinds.animation_kind(kind) == Kind.YUMI_ARCHER or (spec.has_back_bow and pose.sheathed > 0.5)
	if not is_nan(spec.back_hand_on_weapon.x) and not bow_hands:
		back_hand = weapon_local * spec.back_hand_on_weapon
	elif bow_hands:
		var drawn: float = float(FigurePainter.bow_step(pose.bow_draw)) / float(FigurePainter.BOW_STEPS)
		var nock: Vector2 = weapon_local * Vector2(FigurePainter.bow_nock_x(drawn), 0.0)
		back_hand = nock if FigureKinds.animation_kind(kind) == Kind.YUMI_ARCHER else pose.back_grip.lerp(nock, clampf(pose.bow_draw * 3.0, 0.0, 1.0))
		back_hand = back_hand.lerp(Vector2(-12.0, -30.0), pose.release)
	else:
		back_hand = pose.back_grip
	# Breathing and counter-rotation move the whole torso, not the arm joints within it.
	# Cache those local solutions until the grip actually changes (sub-pixel tolerance).
	if front_hand.distance_squared_to(_arm_front_key) > 0.000001:
		_arm_front_key = front_hand
		front_elbow = InkBrush.solve_joint(spec.shoulder_front, front_hand, spec.upper_arm, spec.fore_arm, 1.0)
		_upper_front = _segment_xf(Transform2D.IDENTITY, spec.shoulder_front, front_elbow, spec.upper_arm)
		_fore_front = _segment_xf(Transform2D.IDENTITY, front_elbow, front_hand, spec.fore_arm)
	if back_hand.distance_squared_to(_arm_back_key) > 0.000001:
		_arm_back_key = back_hand
		back_elbow = InkBrush.solve_joint(spec.shoulder_back, back_hand, spec.upper_arm, spec.fore_arm, 1.0)
		_upper_back = _segment_xf(Transform2D.IDENTITY, spec.shoulder_back, back_elbow, spec.upper_arm)
		_fore_back = _segment_xf(Transform2D.IDENTITY, back_elbow, back_hand, spec.fore_arm)

	_step_secondary()
	if _parts.is_empty():
		return
	_update_slots()
	var to_figure: Transform2D = global_transform.affine_inverse() if not _dynamic_parts.is_empty() else Transform2D.IDENTITY
	for i: int in _parts.size():
		_parts[i].transform = _slot_xf[_part_slots[i]]
		# Repaint may be 30 Hz, but the root stays attached to the moving bone
		# every frame. Cached local ribbon vertices follow this pinned origin.
		if secondary != null:
			var chain: ClothChain
			match _parts[i].part_name:
				&"tails":
					if not secondary.scarf.is_empty(): chain = secondary.scarf[0]
				&"sleeve_f": chain = secondary.sleeve_front
				&"sleeve_b": chain = secondary.sleeve_back
			if chain != null and not chain.points.is_empty():
				_parts[i].position = to_figure * chain.points[0]
		if secondary != null and kind == Kind.SHRINE_HEALER and _parts[i].part_name == &"mane":
			var tie: Vector2 = Vector2(-6.0, -10.0)
			_parts[i].transform *= Transform2D(0.0, tie) * Transform2D(secondary.ornament.value * 1.5, Vector2.ZERO) * Transform2D(0.0, -tie)
		if secondary != null and kind == Kind.HATAMOTO and _parts[i].part_name in [&"banner", &"hem"]:
			var pole: Vector2 = Vector2(-11.0, -12.0)
			_parts[i].transform *= Transform2D(0.0, pole) * Transform2D(secondary.ornament.value * 0.3, Vector2.ZERO) * Transform2D(0.0, -pole)
	# Ally ornaments need less repaint work than body poses. Physics and anchors
	# still advance at the full rate; the player's hair remains full-rate too.
	var cloth_frame: int = int(clock * 30.0)
	if kind == Kind.SAMURAI or cloth_frame != _cloth_redraw_frame:
		for part: FigurePart in _dynamic_parts:
			part.queue_redraw()
		_cloth_redraw_frame = cloth_frame
	if _bow_part != null:
		var step: int = FigurePainter.bow_step(pose.bow_draw)
		if step != _bow_step:
			_bow_step = step
			_bow_part.batch = FigurePainter.bow(pose.bow_draw, kind)
			_bow_part.queue_redraw()
		if spec.has_back_bow:
			_bow_part.visible = pose.bow_out >= 0.5
	if spec.has_back_bow:
		var drawing: bool = pose.sheathed > 0.5
		if _weapon_part != null:
			_weapon_part.visible = not drawing
		if _back_bow_part != null:
			_back_bow_part.visible = show_stowed_bow and pose.bow_out < 0.5
	if _hem_part != null:
		var own_hem: bool = kind == Kind.HOLLOW_SOLDIER
		var key: int = FigurePainter.hem_key(self) if own_hem else FigureTatters.key(self)
		if key != _hem_key:
			_hem_key = key
			_hem_part.batch = FigurePainter.hem(key) if own_hem else FigureTatters.batch(kind, key)
			_hem_part.queue_redraw()
	var lit: bool = pose.glow > 0.02
	if _blade_glow_part != null:
		_blade_glow_part.visible = lit and pose.sheathed <= 0.5
		_blade_glow_part.modulate.a = pose.glow
	for part: FigurePart in _pose_glows:
		part.visible = lit
		part.modulate.a = pose.glow
	var strength: float = 1.0 - fall * 0.7
	for i: int in _fall_glows.size():
		var pulse: float = 1.0
		if _glow_flicker[i] > 0.0:
			# Two uneven sine waves read as a flame, not a metronome; the phase is the figure's own.
			var wave: float = 0.5 + 0.3 * sin(clock * 5.3 + flicker_phase) + 0.2 * sin(clock * 8.9 + flicker_phase * 2.3)
			pulse = 1.0 - _glow_flicker[i] * (1.0 - wave)
		var burn: float = 1.0
		if kind == Kind.FALLEN_DAIMYO:
			burn = 0.7 + 0.15 * float(rage)
		_fall_glows[i].visible = rage >= _glow_rage_min[i]
		_fall_glows[i].modulate.a = strength * pulse * burn
	# Hit flash: brighten every part toward paper.
	var tint: Color = Color.WHITE.lerp(FLASH_MODULATE, flash) if flash > 0.0 else Color.WHITE
	modulate = tint.lerp(GOLD_MODULATE, gold_flash) if gold_flash > 0.0 else tint


## Lowest sole corner after heel-first swing rotation; no part of the foot can enter the ground.
func _sole_height(angle: float) -> float:
	return LegIK.SOLE * cos(angle) + maxf(-3.5 * sin(angle), spec.foot * sin(angle))


## How far down (y, in the space `xf` maps root space to) the lowest point of a leg reaches: its foot, or its hem.
func _lowest_contact(hip_point: Vector2, ankle: Vector2, xf: Transform2D) -> float:
	var contacts: FigurePainter.GroundContacts = FigurePainter.ground_contacts(kind)
	if contacts.flat:
		var lowest_flat: float = -INF
		for point: Vector2 in contacts.points:
			lowest_flat = maxf(lowest_flat, (xf * (ankle + point)).y)
		return lowest_flat
	var origin: Vector2 = hip_point if contacts.from_hip else InkBrush.solve_joint(hip_point, ankle, spec.thigh, spec.shin, -1.0)
	var offset: Vector2 = ankle - origin
	var frame: Transform2D = xf * Transform2D(offset.angle(), Vector2(maxf(offset.length(), 0.001) / contacts.length, 1.0), 0.0, origin)
	var lowest: float = -INF
	for point: Vector2 in contacts.points:
		lowest = maxf(lowest, (frame * point).y)
	return lowest


## While the body falls (it turns about the feet) the legs swing down through the ground: lift the whole body by the
## depth they would reach.
func _lift_fallen_legs() -> void:
	if fall <= 0.0:
		return
	var contacts: FigurePainter.GroundContacts = FigurePainter.ground_contacts(kind)
	if contacts.points.is_empty():
		return
	var lowest: float = maxf(_lowest_contact(hip + Vector2(2.0, 0.0), front_ankle, root_xf),
			_lowest_contact(hip + Vector2(-2.0, 0.0), back_ankle, root_xf))
	var dip: float = lowest - contacts.allow * get_unit_scale()
	if dip > 0.0:
		root_xf.origin.y -= dip


## A weapon never dips below the ground line (the feet are at y = 0): if its lowest point would, it is turned about
## the grip just far enough to rest on the line, so a slam, a dropped weapon or a spring overshoot ends on the
## ground and not in it.
func _rest_weapon_on_ground() -> void:
	var points: PackedVector2Array = FigurePainter.weapon_points(kind)
	if points.is_empty():
		return
	# Most of the time the weapon is well clear of the ground: one test of its bounding circle says so.
	var bound: Vector3 = FigurePainter.weapon_bound(kind)
	var centre: Vector2 = weapon_xf * Vector2(bound.x, bound.y)
	if centre.y + bound.z * maxf(weapon_xf.x.length(), weapon_xf.y.length()) <= 0.0:
		return
	for pass_index: int in 3:
		var lowest: float = -INF
		var low_point: Vector2 = Vector2.ZERO
		for point: Vector2 in points:
			var world: Vector2 = weapon_xf * point
			if world.y > lowest:
				lowest = world.y
				low_point = world
		if lowest <= 0.0:
			return
		var grip_point: Vector2 = weapon_xf.origin
		var arm: Vector2 = low_point - grip_point
		if arm.length() < 0.001:
			return
		# Turn it so the lowest point's height above the grip is exactly the grip's own height above the line.
		var sine: float = clampf(-grip_point.y / arm.length(), -1.0, 1.0)
		var current: float = arm.angle()
		var first: float = wrapf(asin(sine) - current, -PI, PI)
		var second: float = wrapf(PI - asin(sine) - current, -PI, PI)
		var turn: float = first if absf(first) < absf(second) else second
		weapon_xf = Transform2D(weapon_xf.x.rotated(turn), weapon_xf.y.rotated(turn), grip_point)


## Lets the cloth catch up with the time the figure's animator has advanced `clock` by. A long
## gap (the figure was off screen) restarts the cloth instead of whipping it.
func _step_secondary() -> void:
	var elapsed: float = clock - _secondary_clock
	_secondary_clock = clock
	if secondary == null or not is_inside_tree():
		return
	if elapsed <= 0.0:
		# Frozen icon/portrait bakers also need a seeded hair/cloth shape on
		# their very first frame; they never advance the animation clock.
		if not secondary.is_initialized(): secondary.step(self, 1.0 / 60.0)
		return
	if elapsed > 0.3:
		secondary = SecondaryMotion.new(spec.loose_armour)
		elapsed = 1.0 / 60.0
	secondary.step(self, minf(elapsed, 0.05))


## One transform per FigurePainter.Slot, from the solved skeleton.
func _update_slots() -> void:
	var s: float = get_unit_scale()
	if ground_marker.a > 0.0:
		_slot_xf[FigurePainter.Slot.MARKER] = Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)
	_slot_xf[FigurePainter.Slot.LOCAL] = Transform2D.IDENTITY
	_slot_xf[FigurePainter.Slot.THIGH_F] = _segment_xf(root_xf, hip + Vector2(2.0, 0.0), front_knee, spec.thigh)
	_slot_xf[FigurePainter.Slot.SHIN_F] = _segment_xf(root_xf, front_knee, front_ankle, spec.shin)
	_slot_xf[FigurePainter.Slot.FOOT_F] = root_xf * Transform2D(gait.heel[0] if gait_enabled else 0.0, front_ankle)
	_slot_xf[FigurePainter.Slot.THIGH_B] = _segment_xf(root_xf, hip + Vector2(-2.0, 0.0), back_knee, spec.thigh)
	_slot_xf[FigurePainter.Slot.SHIN_B] = _segment_xf(root_xf, back_knee, back_ankle, spec.shin)
	_slot_xf[FigurePainter.Slot.FOOT_B] = root_xf * Transform2D(gait.heel[1] if gait_enabled else 0.0, back_ankle)
	if _has_hakama:
		# Hakama legs span the whole leg, hip to ankle, and swing a little about the hip.
		var hip_front: Vector2 = hip + Vector2(2.0, 0.0)
		var hip_back: Vector2 = hip + Vector2(-2.0, 0.0)
		var swing_front: float = secondary.leg_front.value if secondary != null else 0.0
		var swing_back: float = secondary.leg_back.value if secondary != null else 0.0
		_slot_xf[FigurePainter.Slot.HAKAMA_F] = _segment_xf(root_xf, hip_front, hip_front + (front_ankle - hip_front).rotated(swing_front), spec.thigh + spec.shin)
		_slot_xf[FigurePainter.Slot.HAKAMA_B] = _segment_xf(root_xf, hip_back, hip_back + (back_ankle - hip_back).rotated(swing_back), spec.thigh + spec.shin)
	_slot_xf[FigurePainter.Slot.UPPER_F] = torso_xf * _upper_front
	_slot_xf[FigurePainter.Slot.FORE_F] = torso_xf * _fore_front
	_slot_xf[FigurePainter.Slot.HAND_F] = torso_xf * Transform2D(0.0, front_hand)
	_slot_xf[FigurePainter.Slot.UPPER_B] = torso_xf * _upper_back
	_slot_xf[FigurePainter.Slot.FORE_B] = torso_xf * _fore_back
	_slot_xf[FigurePainter.Slot.HAND_B] = torso_xf * Transform2D(0.0, back_hand)
	_slot_xf[FigurePainter.Slot.TORSO] = torso_xf
	_slot_xf[FigurePainter.Slot.HEAD] = head_xf
	_slot_xf[FigurePainter.Slot.WEAPON] = weapon_xf
	if _has_armour:
		# The pauldrons hang from the shoulder and swing with the upper arm (and lag behind it).
		var front_angle: float = secondary.sode_front.value if secondary != null and secondary.loose_armour else _arm_swing(front_elbow - spec.shoulder_front)
		var back_angle: float = secondary.sode_back.value if secondary != null and secondary.loose_armour else _arm_swing(back_elbow - spec.shoulder_back)
		_slot_xf[FigurePainter.Slot.PAULDRON_FRONT] = torso_xf * Transform2D(front_angle, spec.shoulder_front)
		_slot_xf[FigurePainter.Slot.PAULDRON_BACK] = torso_xf * Transform2D(back_angle, spec.shoulder_back + Vector2(-2.0, -1.0))
	if _has_skirt:
		# The skirt (hakama front panel, tassets, sash, scabbard) swings about the waist.
		var skirt_swing: float = secondary.skirt.value if secondary != null else 0.0
		var waist: Vector2 = Vector2(0.0, -3.0)
		_slot_xf[FigurePainter.Slot.SKIRT] = torso_xf * Transform2D(0.0, waist) * Transform2D(skirt_swing, Vector2.ZERO) * Transform2D(0.0, -waist)



## The swing of a shoulder guard for the direction of its upper arm.
static func _arm_swing(to_elbow: Vector2) -> float:
	return clampf(to_elbow.angle() - PI * 0.5, -0.9, 0.7) * 0.5


## Transform that lays a cached limb segment (0,0)->(length,0) from a to b in `space`.
## Stretches it if the joints are further apart than the limb (an unreachable IK target).
static func _segment_xf(space: Transform2D, a: Vector2, b: Vector2, length: float) -> Transform2D:
	var offset: Vector2 = b - a
	var direction: Vector2 = offset.normalized()
	return space * Transform2D(offset / length, Vector2(-direction.y, direction.x), a)


## The figure node itself draws only the ground shadow, once (it doesn't follow the pose).
func _draw() -> void:
	if kind == Kind.FLYING_SPIRIT:
		return # A ground shadow must not travel up with its airborne figure pivot.
	var shadow: InkBatch = FigurePainter.part(kind, &"shadow")
	if shadow != null:
		var s: float = get_unit_scale()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		shadow.draw(self)


## (Re)creates the part nodes for the current kind, back to front.
func _build_parts() -> void:
	# Anisotropic mip sampling preserves folds on the non-uniform torso/limb
	# frames without the crawling fine grain of unfiltered minification.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC if kind == Kind.SAMURAI else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	queue_redraw()
	for part: FigurePart in _parts:
		part.free()
	_parts.clear()
	_part_slots.resize(0)
	_dynamic_parts.clear()
	_cloth_redraw_frame = -1
	_fall_glows.clear()
	_glow_flicker.resize(0)
	_glow_rage_min.resize(0)
	_pose_glows.clear()
	_bow_part = null
	_bow_step = -1
	_weapon_part = null
	_back_bow_part = null
	_hem_part = null
	_hem_key = -1
	_blade_glow_part = null
	_slot_xf.resize(FigurePainter.Slot.size())
	var order: Array[StringName] = FigurePainter.layout(kind)
	_has_armour = order.has(&"pauldron_front")
	_has_skirt = order.has(&"skirt")
	_has_hakama = order.has(&"hakama_f")
	if ground_marker.a > 0.0:
		order.insert(0, &"marker")
	var by_name: Dictionary = {}
	for part_name: StringName in order:
		var part: FigurePart = FigurePart.new()
		part.name = String(part_name)
		part.figure = self
		part.part_name = part_name
		if part_name == &"marker":
			part.batch = _marker_batch()
		elif FigurePainter.DYNAMIC_PARTS.has(part_name) or (kind == Kind.SAMURAI and part_name == &"mane"):
			part.dynamic = true
			_dynamic_parts.append(part)
		elif part_name == &"bow":
			_bow_part = part
		elif part_name == &"hem":
			_hem_part = part
			part.material = Atmosphere.rim_material()
		else:
			part.batch = FigurePainter.part(kind, part_name)
			if part.batch != null and not part.batch.uvs.is_empty():
				part.material = Atmosphere.rim_material()
		if part_name == &"blade_glow":
			_blade_glow_part = part
			part.visible = false
		elif part_name == &"weapon":
			_weapon_part = part
		elif part_name == &"yumi_back":
			_back_bow_part = part
		if part_name == &"bow" and spec.has_back_bow:
			part.visible = false
		if kind == Kind.SAMURAI and SamuraiSpriteArt.has_part(part_name):
			if not part.dynamic:
				part.art = SamuraiSpriteArt.texture(part_name)
				part.art_frame = SamuraiSpriteArt.frame(part_name)
				if part_name == &"skirt":
					part.art_mesh = SamuraiSpriteArt.outline_mesh(part_name)
			# Painted layers carry their own ink edges; the procedural UV-flag rim shader
			# cannot be applied to a normal image texture.
			part.material = Atmosphere.painted_rim_material()
		elif kind == Kind.SAMURAI and part.dynamic:
			part.material = Atmosphere.painted_rim_material()
		elif RosterSpriteArt.has_part(kind, part_name):
			part.art = RosterSpriteArt.texture(kind, part_name)
			part.art_frame = RosterSpriteArt.frame(kind, part_name)
			part.material = Atmosphere.painted_rim_material()
		elif RosterSpriteArt.NAMES.has(kind) and part.dynamic:
			part.material = Atmosphere.painted_rim_material()
		if RosterSpriteArt.NAMES.has(kind) and part_name == &"mane":
			# The new head includes its painted hair; don't retain the former flat
			# silhouette or its extra horn behind it.
			part.visible = false
		if RosterSpriteArt.NAMES.has(kind):
			if part_name == &"torso" and not RosterSpriteArt.torso_patch(kind).is_empty():
				# Close the painted armhole the back arm would show through (and give a cut-off head its neck).
				part.art_patch = RosterSpriteArt.torso_patch(kind)
				part.patch_texture = RosterSpriteArt.atlas(kind)
			elif part_name in [&"upper_f", &"upper_b"]:
				part.art_trim = RosterSpriteArt.arm_trim(kind, part_name)
			elif part_name == &"shoulder_f":
				part.art_patch = RosterSpriteArt.shoulder_patch(kind, false)
				part.patch_texture = RosterSpriteArt.atlas(kind)
				part.art_frame = RosterSpriteArt.frame(kind, &"torso")
				part.material = Atmosphere.painted_rim_material()
			elif part_name in [&"pauldron_front", &"pauldron_back"]:
				# These were the upper arm's sleeve tube drawn a second time on the shoulder, open end and all; the
				# painted upper arms carry their own shoulder plates and the shoulder patches close the joint.
				part.visible = false
		elif kind == Kind.SAMURAI and part_name == &"hem":
			# A flat ink coat-tail behind his painted skirt, which has its own torn hem.
			part.visible = false
		if part_name == &"grip_b" and by_name.has(&"fore_b"):
			# The back hand's fingers over the hilt it grips: the fist end of the back forearm's layer, drawn again.
			var fore: FigurePart = by_name[&"fore_b"]
			if fore.art is AtlasTexture:
				part.art = fore.art
				part.art_frame = fore.art_frame
				part.art_trim = (fore.art as AtlasTexture).region.size.x * FigurePainter.GRIP_HAND_FROM
				part.material = fore.material
		if PaintedEquipment.cell(kind, part_name) >= 0:
			part.art = PaintedEquipment.texture(kind, part_name)
			part.art_frame = PaintedEquipment.frame(kind, part_name)
			part.material = Atmosphere.painted_rim_material()
		elif part_name in [&"bow", &"yumi_back"]:
			part.material = Atmosphere.painted_rim_material()
		add_child(part)
		_parts.append(part)
		_part_slots.append(FigurePainter.SLOTS[part_name])
		by_name[part_name] = part
	_apply_bare_head()
	for definition: Dictionary in FigurePainter.glows(kind):
		var glow: FigurePart = FigurePart.new()
		glow.material = additive_material()
		glow.glow_points = definition["points"]
		glow.glow_radii = definition["radii"]
		glow.glow_colors = definition["colors"]
		(by_name[definition["part"]] as FigurePart).add_child(glow)
		if definition["follows"] == &"pose_glow":
			glow.visible = false
			_pose_glows.append(glow)
		else:
			_fall_glows.append(glow)
			_glow_flicker.append(float(definition.get("flicker", 0.0)))
			_glow_rage_min.append(int(definition.get("rage_min", 1)))


## The ground ring under the player (unit space, scaled by the MARKER slot).
func _marker_batch() -> InkBatch:
	var marker: InkBatch = InkBatch.new()
	var ring: Vector2 = Vector2(spec.shadow_width * 1.25, 5.0)
	marker.ellipse(Vector2.ZERO, ring, Color(ground_marker, ground_marker.a * 0.3), 24)
	var outline: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, ring, 24)
	outline.append(outline[0])
	marker.stroke(outline, 2.2, 2.2, ground_marker)
	return marker
