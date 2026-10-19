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


static func spec(kind: InkFigure.Kind) -> Spec:
	var s: Spec = Spec.new()
	match kind:
		InkFigure.Kind.SAMURAI:
			s.thigh_w = Vector2(13.0, 12.0)
			s.shin_w = Vector2(12.0, 14.0)
			s.back_hand_on_weapon = Vector2(-7.0, 0.0)
			s.head_top = 104.0
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
	return FigurePose.new()


static func _samurai(state: StringName, step: int, heavy: bool) -> FigurePose:
	match state:
		&"run":
			return FigurePose.make(0.2, 3.0, Vector2(7.0, -10.0), 2.6)
		&"windup":
			match step:
				1: # rising cut: blade low behind
					return FigurePose.make(0.08, 4.0, Vector2(-6.0, -6.0), 2.55)
				2: # thrust: pulled back level
					return FigurePose.make(-0.04, 3.0, Vector2(-3.0, -20.0), -0.06)
			return FigurePose.make(-0.06, 2.0, Vector2(-1.0, -41.0), -2.35)
		&"heavy_windup":
			return FigurePose.make(-0.16, 7.0, Vector2(-6.0, -44.0), -2.95)
		&"strike":
			if heavy:
				return FigurePose.make(0.38, 9.0, Vector2(22.0, -2.0), 1.05).with_offset(4.0)
			match step:
				1:
					return FigurePose.make(0.12, 0.0, Vector2(17.0, -36.0), -1.05)
				2:
					return FigurePose.make(0.3, 5.0, Vector2(27.0, -21.0), -0.04).with_offset(5.0)
			return FigurePose.make(0.22, 4.0, Vector2(19.0, -6.0), 0.8)
		&"cast":
			return FigurePose.make(-0.02, 2.0, Vector2(3.0, -46.0), -1.57).with_glow(1.0)
		&"dash":
			return FigurePose.make(0.55, 9.0, Vector2(5.0, -9.0), 2.8)
		&"hurt":
			return FigurePose.make(-0.32, 2.0, Vector2(10.0, -12.0), -0.05).with_head(-0.35).with_offset(-5.0)
		&"dead":
			return FigurePose.make(0.0, 0.0, Vector2(12.0, -8.0), 0.4).with_head(-0.2)
	return FigurePose.make(0.04, 1.0, Vector2(13.0, -14.0), -0.4)


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
