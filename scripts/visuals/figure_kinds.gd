class_name FigureKinds
extends RefCounted
## Proportions and key poses for each InkFigure kind (see docs/ART_BIBLE.md, Proportions).
## Units: figure height = 100. Torso space: origin at the hips, +x forward, -y up.


class Spec:
	var hip_y: float = 46.0
	var thigh: float = 23.0
	var shin: float = 23.0
	## Leg widths: (at hip, at knee) and (at knee, at ankle).
	var thigh_w: Vector2 = Vector2(9.0, 8.0)
	var shin_w: Vector2 = Vector2(8.0, 6.0)
	var foot: float = 8.0
	## Rest x of the front and back foot.
	var stance: Vector2 = Vector2(6.0, -7.0)
	var stride_len: float = 13.0
	var lift: float = 7.0
	var shoulder_front: Vector2 = Vector2(5.0, -31.0)
	var shoulder_back: Vector2 = Vector2(-4.0, -31.0)
	var upper_arm: float = 13.0
	var fore_arm: float = 13.0
	var arm_w: Vector2 = Vector2(6.0, 5.0)
	var fore_w: Vector2 = Vector2(5.0, 4.0)
	var hand_r: float = 3.2
	var neck: Vector2 = Vector2(2.0, -34.0)
	## Top of the head (or hat/horns) above the feet, for health bar placement.
	var head_top: float = 100.0
	## Where the back hand holds the weapon (weapon space). NAN x = back hand is free.
	var back_hand_on_weapon: Vector2 = Vector2(NAN, 0.0)
	## Stride cycle speed while running (radians per second).
	var cadence: float = 13.0
	## How fast the windup pose is reached (higher = snappier; the Oni telegraphs).
	var windup_rate: float = 20.0
	## Lift while lying dead so the body rests on the ground, not in it.
	var lie_lift: float = 8.0
	var shadow_width: float = 22.0
	## Slash trail: the stretch of the weapon it follows (x..y along the weapon; y = 0 means no
	## trail) and its colours (paper core at the cutting edge, `trail_edge` outside).
	var trail_span: Vector2 = Vector2(10.0, 74.0)
	var trail_core: Color = InkPalette.PAPER
	var trail_edge: Color = InkPalette.SAMURAI_RED
	## Defenders summon in with an ink splash; enemies step out of violet smoke.
	var is_enemy: bool = false
	## Colour of the motes rising when the body dissolves.
	var death_accent: Color = InkPalette.SPIRIT
	## Strikes slam the ground with a shockwave of this radius (0 = none).
	var slam_radius: float = 0.0
	## Poses are followed with spring-dampers (anticipation, overshoot, follow-through) and the
	## hand swings on arcs around the shoulder, instead of a plain blend.
	var springy: bool = false
	## Cloth tails (scarf, headband) hang from chains that lag behind the body.
	var cloth: bool = false
	## Loose armour that swings too: hakama, skirt with scabbard, sleeve flaps, shoulder lames.
	var loose_armour: bool = false
	## Sleeve flaps (kinds that have sleeve parts): link length in figure units and the strip's
	## width at the shoulder end and at the tip.
	var sleeve_link: float = 5.2
	var sleeve_width: Vector2 = Vector2(7.5, 3.0)


static func spec(kind: InkFigure.Kind) -> Spec:
	var s: Spec = Spec.new()
	match kind:
		InkFigure.Kind.SAMURAI:
			# Legs are drawn as flared hakama wedges (FigurePainter), so the stance is wide.
			s.stance = Vector2(10.0, -10.0)
			s.back_hand_on_weapon = Vector2(-7.0, 0.0)
			s.head_top = 112.0
			s.shadow_width = 26.0
			s.springy = true
			s.cloth = true
			s.loose_armour = true
		InkFigure.Kind.ASHIGARU:
			s.hip_y = 44.0
			s.thigh = 22.0
			s.shin = 22.0
			s.thigh_w = Vector2(8.5, 7.5)
			s.shin_w = Vector2(7.0, 5.5)
			s.shoulder_front = Vector2(5.0, -29.0)
			s.shoulder_back = Vector2(-4.0, -29.0)
			s.upper_arm = 12.5
			s.fore_arm = 12.5
			s.neck = Vector2(2.0, -31.0)
			s.head_top = 94.0
			s.back_hand_on_weapon = Vector2(-20.0, 0.0)
			s.cadence = 12.0
			s.windup_rate = 16.0
			s.trail_span = Vector2(60.0, 86.0)
			s.trail_core = Color(InkPalette.PAPER, 0.8)
			s.trail_edge = InkPalette.ASHIGARU_GOLD
		InkFigure.Kind.YUMI_ARCHER:
			s.hip_y = 44.0
			s.thigh = 22.0
			s.shin = 22.0
			s.thigh_w = Vector2(10.5, 10.0)
			s.shin_w = Vector2(10.0, 11.5)
			s.shoulder_front = Vector2(5.0, -29.0)
			s.shoulder_back = Vector2(-4.0, -29.0)
			s.upper_arm = 12.5
			s.fore_arm = 12.5
			s.neck = Vector2(2.0, -31.0)
			s.head_top = 94.0
			s.cadence = 12.0
			s.windup_rate = 9.0
			s.trail_span = Vector2.ZERO
			s.cloth = true
		InkFigure.Kind.HOLLOW_SOLDIER:
			s.hip_y = 45.0
			s.thigh_w = Vector2(7.0, 5.5)
			s.shin_w = Vector2(5.5, 4.5)
			s.stance = Vector2(7.0, -6.0)
			s.shoulder_front = Vector2(6.0, -30.0)
			s.shoulder_back = Vector2(-3.0, -30.0)
			s.upper_arm = 14.0
			s.fore_arm = 15.0
			s.arm_w = Vector2(5.0, 4.5)
			s.fore_w = Vector2(4.5, 4.0)
			s.neck = Vector2(7.0, -31.0)
			s.head_top = 100.0
			s.cadence = 8.0
			s.windup_rate = 9.0
			s.trail_span = Vector2(8.0, 52.0)
			s.trail_core = Color(InkPalette.HOLLOW_PURPLE.lerp(InkPalette.PAPER, 0.35), 0.75)
			s.trail_edge = Color(InkPalette.INK, 0.75)
			s.is_enemy = true
			s.death_accent = InkPalette.HOLLOW_PURPLE
		InkFigure.Kind.ONI_BRUTE:
			s.hip_y = 40.0
			s.thigh = 20.0
			s.shin = 20.0
			s.thigh_w = Vector2(15.0, 12.5)
			s.shin_w = Vector2(12.5, 11.0)
			s.foot = 12.0
			s.stance = Vector2(9.0, -9.0)
			s.stride_len = 11.0
			s.lift = 6.0
			s.shoulder_front = Vector2(10.0, -43.0)
			s.shoulder_back = Vector2(-10.0, -44.0)
			s.upper_arm = 19.0
			s.fore_arm = 19.0
			s.arm_w = Vector2(12.0, 10.0)
			s.fore_w = Vector2(10.0, 9.0)
			s.hand_r = 6.0
			s.neck = Vector2(6.0, -46.0)
			s.head_top = 112.0
			s.back_hand_on_weapon = Vector2(-10.0, 0.0)
			s.cadence = 6.5
			s.windup_rate = 4.5
			s.lie_lift = 14.0
			s.shadow_width = 34.0
			s.trail_span = Vector2(18.0, 68.0)
			s.trail_core = Color(InkPalette.ONI_EMBER.lerp(InkPalette.PAPER, 0.2), 0.8)
			s.trail_edge = Color(InkPalette.INK, 0.8)
			s.is_enemy = true
			s.death_accent = InkPalette.ONI_EMBER
			s.slam_radius = 170.0
		InkFigure.Kind.SHRINE_HEALER:
			s.hip_y = 44.0
			s.thigh = 22.0
			s.shin = 22.0
			s.thigh_w = Vector2(7.0, 6.0)
			s.shin_w = Vector2(6.0, 5.0)
			s.stance = Vector2(5.0, -5.0)
			s.shoulder_front = Vector2(5.0, -29.0)
			s.shoulder_back = Vector2(-4.0, -29.0)
			s.upper_arm = 12.5
			s.fore_arm = 12.5
			s.arm_w = Vector2(5.0, 4.5)
			s.fore_w = Vector2(4.5, 3.8)
			s.hand_r = 2.9
			s.neck = Vector2(2.0, -31.0)
			s.head_top = 98.0
			s.cadence = 11.0
			s.windup_rate = 12.0
			s.trail_span = Vector2.ZERO
			s.death_accent = InkPalette.HEALER_JADE
			s.loose_armour = true
			s.sleeve_link = 6.5
			s.sleeve_width = Vector2(10.0, 5.0)
		InkFigure.Kind.SPEAR_GUARDIAN:
			s.hip_y = 44.0
			s.thigh = 22.0
			s.shin = 22.0
			s.thigh_w = Vector2(10.0, 9.0)
			s.shin_w = Vector2(9.0, 7.0)
			s.foot = 10.0
			s.stance = Vector2(7.0, -7.0)
			s.stride_len = 11.0
			s.shoulder_front = Vector2(7.0, -30.0)
			s.shoulder_back = Vector2(-6.0, -30.0)
			s.upper_arm = 13.0
			s.fore_arm = 13.0
			s.arm_w = Vector2(8.0, 7.0)
			s.fore_w = Vector2(7.0, 6.0)
			s.hand_r = 3.8
			s.neck = Vector2(3.0, -32.0)
			s.head_top = 101.0
			s.cadence = 9.0
			s.windup_rate = 11.0
			s.shadow_width = 26.0
			s.trail_span = Vector2(62.0, 112.0)
			s.trail_core = Color(InkPalette.PAPER, 0.75)
			s.trail_edge = InkPalette.GUARDIAN_AZURE
			s.death_accent = InkPalette.GUARDIAN_AZURE
		InkFigure.Kind.ONMYOJI:
			s.hip_y = 44.0
			s.thigh = 22.0
			s.shin = 22.0
			s.thigh_w = Vector2(7.0, 6.0)
			s.shin_w = Vector2(6.0, 5.0)
			s.stance = Vector2(5.0, -5.0)
			s.shoulder_front = Vector2(5.0, -29.0)
			s.shoulder_back = Vector2(-4.0, -29.0)
			s.upper_arm = 12.5
			s.fore_arm = 12.5
			s.arm_w = Vector2(5.0, 4.5)
			s.fore_w = Vector2(4.5, 3.8)
			s.hand_r = 2.9
			s.neck = Vector2(2.0, -31.0)
			s.head_top = 108.0
			s.cadence = 10.0
			s.windup_rate = 10.0
			s.trail_span = Vector2.ZERO
			s.death_accent = InkPalette.ONMYOJI_MAGENTA
			s.loose_armour = true
			s.sleeve_link = 7.0
			s.sleeve_width = Vector2(11.0, 5.0)
		InkFigure.Kind.HATAMOTO:
			s.hip_y = 45.0
			s.thigh = 22.5
			s.shin = 22.5
			s.thigh_w = Vector2(9.5, 8.5)
			s.shin_w = Vector2(8.5, 6.5)
			s.foot = 9.0
			s.stance = Vector2(7.0, -7.0)
			s.stride_len = 12.0
			s.shoulder_front = Vector2(6.0, -31.0)
			s.shoulder_back = Vector2(-5.0, -31.0)
			s.upper_arm = 13.0
			s.fore_arm = 13.0
			s.arm_w = Vector2(7.0, 6.0)
			s.fore_w = Vector2(6.0, 5.0)
			s.hand_r = 3.4
			s.neck = Vector2(2.0, -34.0)
			s.head_top = 112.0
			s.back_hand_on_weapon = Vector2(-18.0, 0.0)
			s.cadence = 11.0
			s.windup_rate = 16.0
			s.shadow_width = 25.0
			s.trail_span = Vector2(48.0, 112.0)
			s.trail_core = Color(InkPalette.PAPER, 0.85)
			s.trail_edge = InkPalette.HATAMOTO_ORANGE
			s.death_accent = InkPalette.HATAMOTO_ORANGE
			s.springy = true
			s.loose_armour = true
	return s


## The key pose for an animation state. `step` is the combo step (0..2) for windup/strike;
## `heavy` selects the heavy attack poses.
static func pose(kind: InkFigure.Kind, state: StringName, step: int = 0, heavy: bool = false) -> FigurePose:
	match kind:
		InkFigure.Kind.SAMURAI:
			return _samurai(state, step, heavy)
		InkFigure.Kind.ASHIGARU:
			return _ashigaru(state)
		InkFigure.Kind.YUMI_ARCHER:
			return _archer(state)
		InkFigure.Kind.HOLLOW_SOLDIER:
			return _hollow(state)
		InkFigure.Kind.ONI_BRUTE:
			return _oni(state)
		InkFigure.Kind.SHRINE_HEALER:
			return _healer(state)
		InkFigure.Kind.SPEAR_GUARDIAN:
			return _guardian(state)
		InkFigure.Kind.ONMYOJI:
			return _onmyoji(state)
		InkFigure.Kind.HATAMOTO:
			return _hatamoto(state)
	return FigurePose.new()


## The samurai's key poses. Rule: the blade never passes through his body. Every pose keeps the
## blade (from the hands outward) in front of him, clear of the helmet, crest, armour and hakama;
## a test (test_art_style) checks it, along the swing too. Grips stay within the arm's reach
## (26) of the shoulder so the arms never stretch.
static func _samurai(state: StringName, step: int, heavy: bool) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			# Blade carried forward and up, out of the legs' way.
			p = FigurePose.make(0.2, 3.0, Vector2(14.0, -18.0), -0.62)
		&"windup":
			match step:
				1: # rising cut: blade low in front, edge turned down
					p = FigurePose.make(0.1, 5.0, Vector2(17.0, -10.0), 0.68).with_spread(1.4)
				2: # thrust: drawn back to the hip, point forward
					p = FigurePose.make(-0.06, 3.0, Vector2(14.0, -13.0), -0.1).with_spread(1.45)
				_: # downward cut: raised blade, body coiled back
					p = FigurePose.make(-0.14, 3.0, Vector2(20.0, -44.0), -1.2).with_head(-0.08).with_spread(1.35)
		&"heavy_windup":
			p = FigurePose.make(-0.22, 8.0, Vector2(19.0, -45.0), -1.3).with_head(-0.14).with_spread(1.6)
		&"strike":
			if heavy:
				p = FigurePose.make(0.4, 9.0, Vector2(25.0, -17.0), 0.62).with_offset(4.0).with_spread(1.7)
			else:
				match step:
					1:
						p = FigurePose.make(0.1, 1.0, Vector2(24.0, -36.0), -0.95).with_spread(1.4)
					2:
						p = FigurePose.make(0.3, 5.0, Vector2(27.0, -22.0), -0.05).with_offset(5.0).with_spread(1.6)
					_:
						p = FigurePose.make(0.22, 4.0, Vector2(25.0, -18.0), 0.55).with_spread(1.5)
		&"cast":
			p = FigurePose.make(-0.02, 3.0, Vector2(21.0, -45.0), -1.25).with_head(-0.1).with_glow(1.0).with_spread(1.4)
		&"dash":
			# A forward thrust leads the charge.
			p = FigurePose.make(0.5, 9.0, Vector2(20.0, -16.0), -0.1).with_spread(1.5)
		&"hurt":
			p = FigurePose.make(-0.32, 2.0, Vector2(13.0, -14.0), -0.2).with_head(-0.35).with_offset(-5.0)
		&"dead":
			# Falls with the body; the katana ends up lying on the ground (the body turns -1.45).
			p = FigurePose.make(0.0, 0.0, Vector2(14.0, -5.0), 1.5).with_head(-0.2)
		_:
			# Guard (seigan): blade forward at the opponent's eyes, feet planted wide.
			p = FigurePose.make(0.04, 2.0, Vector2(14.0, -17.0), -0.5).with_spread(1.3)
	p.pivot = Vector2(5.0, -31.0)
	return p


## The title screen pose: hasso no kamae, katana raised in both hands beside the head, wide stance.
static func samurai_title_pose() -> FigurePose:
	var p: FigurePose = FigurePose.make(-0.02, 5.0, Vector2(21.0, -44.0), -1.25).with_head(-0.1).with_spread(1.8)
	p.pivot = Vector2(5.0, -31.0)
	return p


## How a state moves for springy kinds (see PoseSpring).
static func feel(kind: InkFigure.Kind, state: StringName, heavy: bool = false) -> PoseSpring.Feel:
	if kind == InkFigure.Kind.HATAMOTO:
		return _hatamoto_feel(state)
	if kind != InkFigure.Kind.SAMURAI:
		return PoseSpring.Feel.new()
	match state:
		&"windup":
			# Loose and quick: the hand and blade overshoot the raised pose (anticipation).
			return PoseSpring.Feel.make(Vector2(22.0, 0.7), Vector2(30.0, 0.6), Vector2(28.0, 0.5))
		&"heavy_windup":
			return PoseSpring.Feel.make(Vector2(11.0, 0.72), Vector2(15.0, 0.62), Vector2(14.0, 0.55))
		&"strike":
			# Accelerates into the cut, overshoots, settles (follow-through).
			if heavy:
				return PoseSpring.Feel.make(Vector2(34.0, 0.62), Vector2(48.0, 0.5), Vector2(52.0, 0.42))
			return PoseSpring.Feel.make(Vector2(40.0, 0.62), Vector2(62.0, 0.5), Vector2(66.0, 0.42))
		&"cast":
			return PoseSpring.Feel.make(Vector2(14.0, 0.8), Vector2(18.0, 0.72), Vector2(16.0, 0.7))
		&"dash", &"hurt":
			return PoseSpring.Feel.make(Vector2(42.0, 0.55), Vector2(50.0, 0.55), Vector2(50.0, 0.5))
		&"dead":
			return PoseSpring.Feel.make(Vector2(9.0, 1.0), Vector2(9.0, 1.0), Vector2(9.0, 1.0))
	return PoseSpring.Feel.make(Vector2(12.0, 0.85), Vector2(15.0, 0.8), Vector2(15.0, 0.68))


## The samurai's solid body for the "blade never clips him" test: polygons in root space (feet
## at the origin, y up is negative, figure units) for a pose. They follow the drawn armour
## (see FigurePainter._build_samurai), a little generously.
static func samurai_body_zones(pose_in: FigurePose) -> Array[PackedVector2Array]:
	var s: Spec = spec(InkFigure.Kind.SAMURAI)
	var hip: Vector2 = Vector2(0.0, -(s.hip_y - pose_in.crouch))
	var torso: Transform2D = Transform2D(pose_in.lean, hip)
	var head: Transform2D = torso * Transform2D(pose_in.head_tilt, s.neck)
	var zones: Array[PackedVector2Array] = []
	# Do (chest armour) and the shoulder lames.
	zones.append(torso * PackedVector2Array([Vector2(-15.0, -3.0), Vector2(15.0, -3.0), Vector2(16.0, -14.0),
			Vector2(17.0, -26.0), Vector2(13.0, -33.0), Vector2(-13.0, -33.0), Vector2(-16.0, -22.0)]))
	# Kusazuri and the hakama: one wide triangle down to the ground.
	zones.append(PackedVector2Array([hip + Vector2(-12.0, -2.0), hip + Vector2(12.0, -2.0), Vector2(27.0, 0.0),
			Vector2(-27.0, 0.0)]))
	# Face, kabuto bowl, visor and the neck guard.
	zones.append(head * PackedVector2Array([Vector2(-9.0, -12.0), Vector2(-4.0, -20.5), Vector2(6.0, -20.5),
			Vector2(11.0, -13.0), Vector2(16.0, -11.0), Vector2(15.0, -7.0), Vector2(10.0, 1.0), Vector2(0.0, 1.0),
			Vector2(-18.0, 2.0), Vector2(-19.0, -6.0)]))
	# The crescent crest, a thick arc above the helmet.
	var arc: PackedVector2Array = PackedVector2Array()
	for i: int in 11:
		arc.append(head * (Vector2(6.0, -28.0) + Vector2.from_angle(lerpf(PI + 0.4, -0.4, float(i) / 10.0) ) * 11.0))
	for polygon: PackedVector2Array in Geometry2D.offset_polyline(arc, 2.6):
		zones.append(polygon)
	return zones


static func _ashigaru(state: StringName) -> FigurePose:
	match state:
		&"run":
			return FigurePose.make(0.16, 2.0, Vector2(9.0, -17.0), -1.2)
		&"windup", &"heavy_windup":
			return FigurePose.make(-0.06, 2.0, Vector2(-1.0, -17.0), -0.1).with_offset(-2.0)
		&"strike":
			return FigurePose.make(0.22, 3.0, Vector2(24.0, -17.0), -0.05).with_offset(3.0)
		&"hurt":
			return FigurePose.make(-0.3, 1.0, Vector2(8.0, -14.0), -0.3).with_head(-0.3).with_offset(-4.0)
		&"dead":
			return FigurePose.make(0.0, 0.0, Vector2(10.0, -10.0), 0.2)
	return FigurePose.make(0.05, 1.0, Vector2(12.0, -15.0), -0.12)


static func _archer(state: StringName) -> FigurePose:
	match state:
		&"run":
			return FigurePose.make(0.15, 2.0, Vector2(11.0, -14.0), 0.7)
		&"windup", &"heavy_windup":
			return FigurePose.make(-0.06, 2.0, Vector2(21.0, -27.0), 0.0).with_bow(1.0)
		&"strike":
			return FigurePose.make(-0.02, 2.0, Vector2(21.0, -27.0), -0.02).with_bow(0.0, 1.0)
		&"hurt":
			return FigurePose.make(-0.3, 1.0, Vector2(10.0, -16.0), 0.4).with_head(-0.3).with_offset(-4.0)
		&"dead":
			return FigurePose.make(0.0, 0.0, Vector2(12.0, -12.0), 0.9)
	return FigurePose.make(0.02, 1.0, Vector2(12.0, -20.0), 0.18)


static func _hollow(state: StringName) -> FigurePose:
	match state:
		&"run":
			return FigurePose.make(0.36, 2.0, Vector2(12.0, -6.0), 1.2).with_back(Vector2(4.0, -8.0)).with_head(0.15)
		&"windup", &"heavy_windup":
			return FigurePose.make(0.12, 2.0, Vector2(-2.0, -38.0), -2.3).with_back(Vector2(-6.0, -14.0))
		&"strike":
			return FigurePose.make(0.42, 3.0, Vector2(20.0, -6.0), 0.85).with_back(Vector2(-6.0, -10.0)).with_offset(3.0)
		&"hurt":
			return FigurePose.make(0.0, 1.0, Vector2(8.0, -6.0), 1.2).with_back(Vector2(-2.0, -4.0)).with_head(-0.3).with_offset(-4.0)
		&"dead":
			return FigurePose.make(0.0, 0.0, Vector2(10.0, -4.0), 1.4).with_back(Vector2(0.0, -2.0))
	return FigurePose.make(0.28, 1.0, Vector2(13.0, -6.0), 0.95).with_back(Vector2(2.0, -5.0)).with_head(0.2)


static func _oni(state: StringName) -> FigurePose:
	match state:
		&"run":
			return FigurePose.make(0.18, 2.0, Vector2(15.0, -16.0), 2.1)
		&"windup", &"heavy_windup":
			return FigurePose.make(-0.14, 2.0, Vector2(3.0, -58.0), -2.6)
		&"strike":
			return FigurePose.make(0.32, 7.0, Vector2(30.0, -6.0), 1.2).with_offset(3.0)
		&"hurt":
			return FigurePose.make(-0.12, 1.0, Vector2(18.0, -18.0), 0.7).with_head(-0.2)
		&"dead":
			return FigurePose.make(0.0, 0.0, Vector2(16.0, -10.0), 0.8)
	return FigurePose.make(0.1, 1.0, Vector2(21.0, -17.0), 1.05)


## Shrine Healer: the gohei (wand with paper streamers) is held upright, raised to bless, and
## swept forward to release the healing.
static func _healer(state: StringName) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			p = FigurePose.make(0.14, 2.0, Vector2(11.0, -20.0), -1.1)
		&"windup", &"heavy_windup", &"cast":
			p = FigurePose.make(-0.08, 2.0, Vector2(15.0, -33.0), -1.45).with_back(Vector2(8.0, -26.0)).with_head(-0.12)
		&"strike":
			p = FigurePose.make(0.1, 2.0, Vector2(24.0, -24.0), -0.55).with_back(Vector2(14.0, -22.0))
		&"hurt":
			p = FigurePose.make(-0.3, 1.0, Vector2(9.0, -17.0), -0.8).with_head(-0.3).with_offset(-4.0)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(10.0, -8.0), 0.3)
		_:
			p = FigurePose.make(0.03, 1.0, Vector2(11.0, -19.0), -1.25).with_back(Vector2(5.0, -15.0))
	return p


## Spear Guardian: shield forward on the back arm, spear levelled over it; the thrust drives
## the whole body forward behind the shield.
static func _guardian(state: StringName) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			p = FigurePose.make(0.16, 2.0, Vector2(10.0, -22.0), -0.12).with_back(Vector2(11.0, -13.0))
		&"windup", &"heavy_windup":
			p = FigurePose.make(-0.1, 3.0, Vector2(-1.0, -22.0), -0.08).with_back(Vector2(12.0, -14.0)).with_offset(-3.0)
		&"strike":
			p = FigurePose.make(0.26, 4.0, Vector2(26.0, -22.0), -0.05).with_back(Vector2(15.0, -13.0)).with_offset(5.0)
		&"hurt":
			p = FigurePose.make(-0.18, 2.0, Vector2(8.0, -22.0), -0.2).with_back(Vector2(14.0, -20.0)).with_head(-0.2).with_offset(-2.0)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(10.0, -10.0), 0.3).with_back(Vector2(4.0, -6.0))
		_:
			p = FigurePose.make(0.04, 1.0, Vector2(10.0, -22.0), -0.14).with_back(Vector2(13.0, -15.0))
	return p


## Onmyoji: a paper talisman (ofuda) held up between two fingers, thrown forward when casting.
static func _onmyoji(state: StringName) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			p = FigurePose.make(0.12, 2.0, Vector2(11.0, -21.0), -1.2)
		&"windup", &"heavy_windup", &"cast":
			p = FigurePose.make(-0.1, 2.0, Vector2(14.0, -36.0), -1.5).with_back(Vector2(9.0, -29.0)).with_head(-0.15)
		&"strike":
			p = FigurePose.make(0.12, 2.0, Vector2(25.0, -28.0), -0.25).with_back(Vector2(13.0, -24.0))
		&"hurt":
			p = FigurePose.make(-0.28, 1.0, Vector2(9.0, -20.0), -0.9).with_head(-0.3).with_offset(-4.0)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(10.0, -8.0), 0.3)
		_:
			p = FigurePose.make(0.03, 1.0, Vector2(12.0, -22.0), -1.3).with_back(Vector2(6.0, -17.0))
	return p


## Hatamoto: a naginata held angled across the body, swept in a wide arc. Springy like the samurai.
static func _hatamoto(state: StringName) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			p = FigurePose.make(0.18, 3.0, Vector2(13.0, -19.0), -0.95)
		&"windup", &"heavy_windup":
			p = FigurePose.make(-0.14, 4.0, Vector2(15.0, -40.0), -1.25).with_head(-0.08).with_spread(1.25)
		&"strike":
			p = FigurePose.make(0.34, 6.0, Vector2(25.0, -17.0), 0.5).with_offset(4.0).with_spread(1.5)
		&"hurt":
			p = FigurePose.make(-0.3, 2.0, Vector2(11.0, -15.0), -0.3).with_head(-0.3).with_offset(-5.0)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(14.0, -5.0), 1.5).with_head(-0.2)
		_:
			p = FigurePose.make(0.05, 2.0, Vector2(13.0, -20.0), -0.85).with_spread(1.15)
	p.pivot = Vector2(6.0, -31.0)
	return p


static func _hatamoto_feel(state: StringName) -> PoseSpring.Feel:
	match state:
		&"windup", &"heavy_windup":
			return PoseSpring.Feel.make(Vector2(18.0, 0.72), Vector2(24.0, 0.62), Vector2(22.0, 0.55))
		&"strike":
			return PoseSpring.Feel.make(Vector2(34.0, 0.62), Vector2(52.0, 0.5), Vector2(56.0, 0.44))
		&"hurt":
			return PoseSpring.Feel.make(Vector2(42.0, 0.55), Vector2(50.0, 0.55), Vector2(50.0, 0.5))
		&"dead":
			return PoseSpring.Feel.make(Vector2(9.0, 1.0), Vector2(9.0, 1.0), Vector2(9.0, 1.0))
	return PoseSpring.Feel.make(Vector2(12.0, 0.85), Vector2(15.0, 0.8), Vector2(15.0, 0.68))
