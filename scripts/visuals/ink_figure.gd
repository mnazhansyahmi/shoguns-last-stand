class_name InkFigure
extends Node2D
## A procedurally drawn ink-silhouette character (see docs/ART_BIBLE.md).
## UnitVisual writes the live pose and motion fields every frame, then calls refresh(), which
## solves a small skeleton (hips, two-bone IK legs and arms, torso, head, weapon) and moves one
## child FigurePart per body part. Parts draw shapes cached per kind (FigurePainter) once, so a
## frame costs a few transforms per part and no geometry work; only cloth and the Hollow
## Soldier's hem are repainted. Feet are at the origin and the figure faces +x; the parent
## mirrors it for facing left. Glowing spots are additive child parts that fade by alpha.

enum Kind { SAMURAI, ASHIGARU, YUMI_ARCHER, HOLLOW_SOLDIER, ONI_BRUTE, SHRINE_HEALER, SPEAR_GUARDIAN, ONMYOJI, HATAMOTO }

## Figure units per figure height (all proportions are authored at height 100).
const UNIT: float = 100.0
## Rotation of a fallen body (backward around the feet).
const FALL_ANGLE: float = -1.45
const SHADOW_ALPHA: float = 0.3
## modulate at full hit flash: lightens near-black ink a little (it must stay a dark silhouette).
const FLASH_MODULATE: Color = Color(2.4, 2.3, 2.2, 1.0)

static var _additive: CanvasItemMaterial

@export var kind: Kind = Kind.SAMURAI:
	set = set_kind
## Body height in pixels (body_size.y of the unit's data).
@export var height: float = 110.0

var pose: FigurePose = FigurePose.new()
var spec: FigureKinds.Spec = FigureKinds.spec(Kind.SAMURAI)

# Motion written by UnitVisual.
var stride: float = 0.0
var stride_phase: float = 0.0
var bob: float = 0.0
## -1..1 breathing cycle.
var breath: float = 0.0
## Random phase of the glow's flicker, so a crowd's lights do not pulse together.
var flicker_phase: float = 0.0
## 0 = standing still, 1 = running (cloth streams back).
var trail: float = 0.0
## Seconds, drives cloth flutter.
var clock: float = 0.0
## 0..1 hit flash (brightens the whole figure toward paper).
var flash: float = 0.0
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
var _parts: Array[FigurePart] = []
var _part_slots: PackedInt32Array = PackedInt32Array()
var _dynamic_parts: Array[FigurePart] = []
var _fall_glows: Array[FigurePart] = []
## How deeply each of _fall_glows flickers (0 = steady), index for index.
var _glow_flicker: PackedFloat32Array = PackedFloat32Array()
var _pose_glows: Array[FigurePart] = []
var _bow_part: FigurePart
var _bow_step: int = -1
var _hem_part: FigurePart
var _hem_key: int = -1
var _blade_glow_part: FigurePart
var _slot_xf: Array[Transform2D] = []


func _ready() -> void:
	_build_parts()
	refresh()


static func additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = InkBrush.additive_material()
	return _additive


func set_kind(value: Kind) -> void:
	kind = value
	spec = FigureKinds.spec(value)
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
	var lift: float = bob + fall * spec.lie_lift
	return Transform2D(fall * FALL_ANGLE, Vector2(s, s * maxf(squash, 0.05)), 0.0,
			Vector2(for_pose.offset_x * s, -lift * s))


## Solves the skeleton from the pose fields and moves the parts.
func refresh() -> void:
	root_xf = _root_for(pose)

	hip = Vector2(0.0, -(spec.hip_y - pose.crouch))
	var swing: float = sin(stride_phase) * stride * spec.stride_len
	var front_foot: Vector2 = Vector2(spec.stance.x * pose.spread + swing, -maxf(0.0, cos(stride_phase)) * stride * spec.lift)
	var back_foot: Vector2 = Vector2(spec.stance.y * pose.spread - swing, -maxf(0.0, -cos(stride_phase)) * stride * spec.lift)
	front_ankle = front_foot + Vector2(0.0, -2.5)
	back_ankle = back_foot + Vector2(0.0, -2.5)
	front_knee = InkBrush.solve_joint(hip + Vector2(2.0, 0.0), front_ankle, spec.thigh, spec.shin, -1.0)
	back_knee = InkBrush.solve_joint(hip + Vector2(-2.0, 0.0), back_ankle, spec.thigh, spec.shin, -1.0)

	torso_xf = root_xf * Transform2D(pose.lean, Vector2(1.0, 1.0 + spec.breath_amp * breath), 0.0, hip)
	head_xf = torso_xf * Transform2D(pose.head_tilt + breath * 0.02, spec.neck)
	weapon_local = Transform2D(pose.blade, pose.grip)
	weapon_xf = torso_xf * weapon_local

	front_hand = pose.grip
	if not is_nan(spec.back_hand_on_weapon.x):
		back_hand = weapon_local * spec.back_hand_on_weapon
	elif kind == Kind.YUMI_ARCHER:
		var nock: Vector2 = weapon_local * Vector2(FigurePainter.bow_nock_x(pose.bow_draw), 0.0)
		back_hand = pose.back_grip.lerp(nock, clampf(pose.bow_draw * 3.0, 0.0, 1.0))
		back_hand = back_hand.lerp(Vector2(-12.0, -30.0), pose.release)
	else:
		back_hand = pose.back_grip
	front_elbow = InkBrush.solve_joint(spec.shoulder_front, front_hand, spec.upper_arm, spec.fore_arm, 1.0)
	back_elbow = InkBrush.solve_joint(spec.shoulder_back, back_hand, spec.upper_arm, spec.fore_arm, 1.0)

	_step_secondary()
	if _parts.is_empty():
		return
	_update_slots()
	for i: int in _parts.size():
		_parts[i].transform = _slot_xf[_part_slots[i]]
	for part: FigurePart in _dynamic_parts:
		part.queue_redraw()
	if _bow_part != null:
		var step: int = FigurePainter.bow_step(pose.bow_draw)
		if step != _bow_step:
			_bow_step = step
			_bow_part.batch = FigurePainter.bow(pose.bow_draw)
			_bow_part.queue_redraw()
	if _hem_part != null:
		var own_hem: bool = kind == Kind.HOLLOW_SOLDIER
		var key: int = FigurePainter.hem_key(self) if own_hem else FigureTatters.key(self)
		if key != _hem_key:
			_hem_key = key
			_hem_part.batch = FigurePainter.hem(key) if own_hem else FigureTatters.batch(kind, key)
			_hem_part.queue_redraw()
	var lit: bool = pose.glow > 0.02
	if _blade_glow_part != null:
		_blade_glow_part.visible = lit
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
		_fall_glows[i].modulate.a = strength * pulse
	# Hit flash: brighten every part toward paper.
	modulate = Color.WHITE.lerp(FLASH_MODULATE, flash) if flash > 0.0 else Color.WHITE


## Lets the cloth catch up with the time the figure's animator has advanced `clock` by. A long
## gap (the figure was off screen) restarts the cloth instead of whipping it.
func _step_secondary() -> void:
	var elapsed: float = clock - _secondary_clock
	_secondary_clock = clock
	if secondary == null or elapsed <= 0.0 or not is_inside_tree():
		return
	if elapsed > 0.3:
		secondary = SecondaryMotion.new(spec.loose_armour)
		elapsed = 1.0 / 60.0
	secondary.step(self, minf(elapsed, 0.05))


## One transform per FigurePainter.Slot, from the solved skeleton.
func _update_slots() -> void:
	var s: float = get_unit_scale()
	_slot_xf[FigurePainter.Slot.SHADOW] = Transform2D(0.0, Vector2(s * (1.0 + fall * 0.9), s), 0.0, Vector2(pose.offset_x * s, 0.0))
	_slot_xf[FigurePainter.Slot.MARKER] = Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)
	_slot_xf[FigurePainter.Slot.LOCAL] = Transform2D.IDENTITY
	_slot_xf[FigurePainter.Slot.THIGH_F] = _segment_xf(root_xf, hip + Vector2(2.0, 0.0), front_knee, spec.thigh)
	_slot_xf[FigurePainter.Slot.SHIN_F] = _segment_xf(root_xf, front_knee, front_ankle, spec.shin)
	_slot_xf[FigurePainter.Slot.FOOT_F] = root_xf * Transform2D(0.0, front_ankle)
	_slot_xf[FigurePainter.Slot.THIGH_B] = _segment_xf(root_xf, hip + Vector2(-2.0, 0.0), back_knee, spec.thigh)
	_slot_xf[FigurePainter.Slot.SHIN_B] = _segment_xf(root_xf, back_knee, back_ankle, spec.shin)
	_slot_xf[FigurePainter.Slot.FOOT_B] = root_xf * Transform2D(0.0, back_ankle)
	# Hakama legs span the whole leg, hip to ankle, and swing a little about the hip.
	var hip_front: Vector2 = hip + Vector2(2.0, 0.0)
	var hip_back: Vector2 = hip + Vector2(-2.0, 0.0)
	var swing_front: float = secondary.leg_front.value if secondary != null else 0.0
	var swing_back: float = secondary.leg_back.value if secondary != null else 0.0
	_slot_xf[FigurePainter.Slot.HAKAMA_F] = _segment_xf(root_xf, hip_front, hip_front + (front_ankle - hip_front).rotated(swing_front), spec.thigh + spec.shin)
	_slot_xf[FigurePainter.Slot.HAKAMA_B] = _segment_xf(root_xf, hip_back, hip_back + (back_ankle - hip_back).rotated(swing_back), spec.thigh + spec.shin)
	_slot_xf[FigurePainter.Slot.UPPER_F] = _segment_xf(torso_xf, spec.shoulder_front, front_elbow, spec.upper_arm)
	_slot_xf[FigurePainter.Slot.FORE_F] = _segment_xf(torso_xf, front_elbow, front_hand, spec.fore_arm)
	_slot_xf[FigurePainter.Slot.HAND_F] = torso_xf * Transform2D(0.0, front_hand)
	_slot_xf[FigurePainter.Slot.UPPER_B] = _segment_xf(torso_xf, spec.shoulder_back, back_elbow, spec.upper_arm)
	_slot_xf[FigurePainter.Slot.FORE_B] = _segment_xf(torso_xf, back_elbow, back_hand, spec.fore_arm)
	_slot_xf[FigurePainter.Slot.HAND_B] = torso_xf * Transform2D(0.0, back_hand)
	_slot_xf[FigurePainter.Slot.TORSO] = torso_xf
	_slot_xf[FigurePainter.Slot.HEAD] = head_xf
	_slot_xf[FigurePainter.Slot.WEAPON] = weapon_xf
	# The pauldrons hang from the shoulder and swing with the upper arm (and lag behind it).
	var front_angle: float = secondary.sode_front.value if secondary != null and secondary.loose_armour else _arm_swing(front_elbow - spec.shoulder_front)
	var back_angle: float = secondary.sode_back.value if secondary != null and secondary.loose_armour else _arm_swing(back_elbow - spec.shoulder_back)
	_slot_xf[FigurePainter.Slot.PAULDRON_FRONT] = torso_xf * Transform2D(front_angle, spec.shoulder_front)
	_slot_xf[FigurePainter.Slot.PAULDRON_BACK] = torso_xf * Transform2D(back_angle, spec.shoulder_back + Vector2(-2.0, -1.0))
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
	return space * Transform2D(offset.angle(), Vector2(maxf(offset.length(), 0.001) / length, 1.0), 0.0, a)


## The figure node itself draws only the ground shadow, once (it doesn't follow the pose).
func _draw() -> void:
	var shadow: InkBatch = FigurePainter.part(kind, &"shadow")
	if shadow != null:
		var s: float = get_unit_scale()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		shadow.draw(self)


## (Re)creates the part nodes for the current kind, back to front.
func _build_parts() -> void:
	queue_redraw()
	for part: FigurePart in _parts:
		part.free()
	_parts.clear()
	_part_slots.resize(0)
	_dynamic_parts.clear()
	_fall_glows.clear()
	_glow_flicker.resize(0)
	_pose_glows.clear()
	_bow_part = null
	_bow_step = -1
	_hem_part = null
	_hem_key = -1
	_blade_glow_part = null
	_slot_xf.resize(FigurePainter.Slot.size())
	var order: Array[StringName] = FigurePainter.layout(kind)
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
		elif FigurePainter.DYNAMIC_PARTS.has(part_name):
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
		add_child(part)
		_parts.append(part)
		_part_slots.append(FigurePainter.SLOTS[part_name])
		by_name[part_name] = part
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


## The ground ring under the player (unit space, scaled by the MARKER slot).
func _marker_batch() -> InkBatch:
	var marker: InkBatch = InkBatch.new()
	var ring: Vector2 = Vector2(spec.shadow_width * 1.25, 5.0)
	marker.ellipse(Vector2.ZERO, ring, Color(ground_marker, ground_marker.a * 0.3), 24)
	var outline: PackedVector2Array = InkBrush.ellipse_points(Vector2.ZERO, ring, 24)
	outline.append(outline[0])
	marker.stroke(outline, 2.2, 2.2, ground_marker)
	return marker
