class_name InkFigure
extends Node2D
## A procedurally drawn ink-silhouette character (see docs/ART_BIBLE.md).
## UnitVisual writes the live pose and motion fields every frame, then calls refresh(), which
## solves the skeleton and redraws. Feet are at the origin and the figure faces +x; the parent
## mirrors it for facing left. Glowing parts (eyes, spirit blade) are drawn on an additive
## child layer. FigurePainter does the per-kind costume drawing.

enum Kind { SAMURAI, ASHIGARU, YUMI_ARCHER, HOLLOW_SOLDIER, ONI_BRUTE }

## Figure units per figure height (all proportions are authored at height 100).
const UNIT: float = 100.0
## Rotation of a fallen body (backward around the feet).
const FALL_ANGLE: float = -1.45
const SHADOW_ALPHA: float = 0.3

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
## 0 = standing still, 1 = running (cloth streams back).
var trail: float = 0.0
## Seconds, drives cloth flutter.
var clock: float = 0.0
## 0..1, lerps every ink colour toward paper (hit flash).
var flash: float = 0.0
## 0 = standing, 1 = lying on the ground.
var fall: float = 0.0
## Vertical scale (spawn rise).
var squash: float = 1.0

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

var _glow_points: PackedVector2Array = PackedVector2Array()
var _glow_radii: PackedFloat32Array = PackedFloat32Array()
var _glow_colors: PackedColorArray = PackedColorArray()
var _glow_layer: Node2D


func _ready() -> void:
	_glow_layer = Node2D.new()
	_glow_layer.name = "GlowLayer"
	_glow_layer.material = additive_material()
	add_child(_glow_layer)
	_glow_layer.draw.connect(_draw_glows)
	refresh()


static func additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = InkBrush.additive_material()
	return _additive


func set_kind(value: Kind) -> void:
	kind = value
	spec = FigureKinds.spec(value)
	pose.copy_from(FigureKinds.pose(value, &"idle"))
	if is_inside_tree():
		refresh()


## Pixel scale from figure units.
func get_unit_scale() -> float:
	return height / UNIT


## Local y of the top of the head (or hat/horns), for health bars. Negative = above the feet.
func get_head_top_y() -> float:
	return -height * spec.head_top / UNIT


## Blade tip of the held weapon in local pixels (used by slash trails).
func get_weapon_point(along: float) -> Vector2:
	return weapon_xf * Vector2(along, 0.0)


## Where the held weapon would be for `for_pose` (with the current body motion): the points
## `along_from` and `along_to` along it, in local pixels. Used to sweep slash trails.
func weapon_points_for(for_pose: FigurePose, along_from: float, along_to: float) -> PackedVector2Array:
	var xf: Transform2D = _root_for(for_pose) * Transform2D(for_pose.lean, Vector2(0.0, -(spec.hip_y - for_pose.crouch))) 			* Transform2D(for_pose.blade, for_pose.grip)
	return PackedVector2Array([xf * Vector2(along_from, 0.0), xf * Vector2(along_to, 0.0)])


## Points spread over the body (feet to head and hands), in local pixels. Death ink rises
## from these.
func get_body_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array([root_xf * front_ankle, root_xf * back_ankle,
			root_xf * front_knee, root_xf * back_knee, root_xf * hip, torso_xf * Vector2(0.0, spec.neck.y * 0.5),
			torso_xf * spec.shoulder_front, torso_xf * spec.shoulder_back, head_xf * Vector2(1.0, -8.0),
			torso_xf * front_hand, torso_xf * back_hand])
	return points


func _root_for(for_pose: FigurePose) -> Transform2D:
	var s: float = get_unit_scale()
	var lift: float = bob + fall * spec.lie_lift
	return Transform2D(fall * FALL_ANGLE, Vector2(s, s * maxf(squash, 0.05)), 0.0,
			Vector2(for_pose.offset_x * s, -lift * s))


## Solves the skeleton from the pose fields and redraws.
func refresh() -> void:
	root_xf = _root_for(pose)

	hip = Vector2(0.0, -(spec.hip_y - pose.crouch))
	var swing: float = sin(stride_phase) * stride * spec.stride_len
	var front_foot: Vector2 = Vector2(spec.stance.x + swing, -maxf(0.0, cos(stride_phase)) * stride * spec.lift)
	var back_foot: Vector2 = Vector2(spec.stance.y - swing, -maxf(0.0, -cos(stride_phase)) * stride * spec.lift)
	front_ankle = front_foot + Vector2(0.0, -2.5)
	back_ankle = back_foot + Vector2(0.0, -2.5)
	front_knee = InkBrush.solve_joint(hip + Vector2(2.0, 0.0), front_ankle, spec.thigh, spec.shin, -1.0)
	back_knee = InkBrush.solve_joint(hip + Vector2(-2.0, 0.0), back_ankle, spec.thigh, spec.shin, -1.0)

	torso_xf = root_xf * Transform2D(pose.lean, Vector2(1.0, 1.0 + 0.015 * breath), 0.0, hip)
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

	_glow_points.resize(0)
	_glow_radii.resize(0)
	_glow_colors.resize(0)
	FigurePainter.collect_glows(self)
	queue_redraw()
	if _glow_layer != null:
		_glow_layer.queue_redraw()


# --- Drawing helpers used by FigurePainter ----------------------------------

## A palette colour with the hit flash applied.
func ink(color: Color) -> Color:
	return color.lerp(InkPalette.PAPER, flash) if flash > 0.0 else color


func use(xf: Transform2D) -> void:
	draw_set_transform_matrix(xf)


## Adds a glow at `point` (in the space of `xf`), radius in figure units.
func add_glow(xf: Transform2D, point: Vector2, radius: float, color: Color) -> void:
	if color.a <= 0.0 or radius <= 0.0:
		return
	_glow_points.append(xf * point)
	_glow_radii.append(radius * get_unit_scale())
	_glow_colors.append(color)


func paint_leg(front: bool) -> void:
	var color: Color = ink(InkPalette.INK if front else InkPalette.INK_BACK)
	var hip_joint: Vector2 = hip + Vector2(2.0 if front else -2.0, 0.0)
	var knee: Vector2 = front_knee if front else back_knee
	var ankle: Vector2 = front_ankle if front else back_ankle
	use(root_xf)
	InkBrush.limb(self, hip_joint, knee, spec.thigh_w.x, spec.thigh_w.y, color)
	InkBrush.limb(self, knee, ankle, spec.shin_w.x, spec.shin_w.y, color)
	var sole: float = ankle.y + 2.5
	InkBrush.fill_convex(self, PackedVector2Array([Vector2(ankle.x - 3.5, ankle.y - 1.0),
			Vector2(ankle.x + 3.0, ankle.y - 1.5), Vector2(ankle.x + spec.foot, sole),
			Vector2(ankle.x - 3.5, sole)]), color)


func paint_arm(front: bool) -> void:
	var color: Color = ink(InkPalette.INK if front else InkPalette.INK_BACK)
	var shoulder: Vector2 = spec.shoulder_front if front else spec.shoulder_back
	var elbow: Vector2 = front_elbow if front else back_elbow
	var hand: Vector2 = front_hand if front else back_hand
	use(torso_xf)
	InkBrush.limb(self, shoulder, elbow, spec.arm_w.x, spec.arm_w.y, color)
	InkBrush.limb(self, elbow, hand, spec.fore_w.x, spec.fore_w.y, color)


func paint_hand(front: bool) -> void:
	use(torso_xf)
	draw_circle(front_hand if front else back_hand, spec.hand_r,
			ink(InkPalette.INK if front else InkPalette.INK_BACK))


func _draw() -> void:
	var s: float = get_unit_scale()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	InkBrush.ellipse(self, Vector2(pose.offset_x, 0.0), Vector2(spec.shadow_width * (1.0 + fall * 0.9), 3.2),
			Color(InkPalette.INK, SHADOW_ALPHA))
	FigurePainter.paint(self)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_glows() -> void:
	for i: int in _glow_points.size():
		InkBrush.glow(_glow_layer, _glow_points[i], _glow_radii[i], _glow_colors[i])
