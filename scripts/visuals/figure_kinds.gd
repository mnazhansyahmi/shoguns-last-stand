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
	## Idle personality: how fast and how deep it breathes (and how much its lean follows the breath),
	## and how its weapon sways (amplitude rad, speed rad/s), its body leans, it shifts its weight
	## (crouch units), its head moves, and its hand wanders (pixels).
	var breath_hz: float = 0.3
	var breath_amp: float = 0.015
	var breath_lean: float = 0.012
	var idle_blade: Vector2 = Vector2(0.04, 1.7)
	var idle_lean: Vector2 = Vector2(0.0, 1.9)
	var idle_bob: Vector2 = Vector2.ZERO
	var idle_head: Vector2 = Vector2.ZERO
	var idle_grip: float = 0.0
	## The figure's one accent colour (summon buttons wear it).
	var accent: Color = InkPalette.PAPER
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
	## Carries a yumi (long bow) stowed on the back that the Bow skill takes out (FigurePainter `yumi_back`).
	var has_back_bow: bool = false


static func spec(kind: InkFigure.Kind) -> Spec:
	var s: Spec = Spec.new()
	match kind:
		InkFigure.Kind.SAMURAI:
			s.accent = InkPalette.SAMURAI_RED
			# Calm: slow deep breaths, a still blade, only the head turns now and then.
			s.breath_hz = 0.22
			s.breath_amp = 0.012
			s.breath_lean = 0.008
			s.idle_blade = Vector2(0.025, 1.1)
			s.idle_lean = Vector2(0.008, 0.9)
			s.idle_head = Vector2(0.035, 0.45)
			# Legs are drawn as flared hakama wedges (FigurePainter), so the stance is wide.
			s.stance = Vector2(6.5, -8.5)
			# Two hands on a long hilt: the back hand 9 units behind the front one.
			s.back_hand_on_weapon = Vector2(-9.0, 0.0)
			# Legs built like the Spear Guardian's: plain tapered limbs (the hakama flare is added in FigurePainter).
			s.thigh_w = Vector2(10.0, 9.0)
			s.shin_w = Vector2(9.0, 7.0)
			s.foot = 9.0
			s.head_top = 112.0
			s.shadow_width = 26.0
			s.springy = true
			s.cloth = true
			s.loose_armour = true
			s.has_back_bow = true
		InkFigure.Kind.ASHIGARU:
			s.accent = InkPalette.ASHIGARU_GOLD
			# Nervous foot soldier: shifts his weight, glances about, the spear never quite still.
			s.breath_hz = 0.38
			s.breath_lean = 0.018
			s.idle_blade = Vector2(0.06, 2.1)
			s.idle_lean = Vector2(0.025, 1.7)
			s.idle_bob = Vector2(1.0, 2.3)
			s.idle_head = Vector2(0.08, 1.0)
			s.idle_grip = 0.5
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
			s.accent = InkPalette.ARCHER_TEAL
			# Alert: scans the field, the bow hand always adjusting.
			s.breath_hz = 0.3
			s.idle_blade = Vector2(0.035, 1.6)
			s.idle_lean = Vector2(0.015, 1.4)
			s.idle_head = Vector2(0.11, 1.3)
			s.idle_grip = 0.5
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
			s.accent = InkPalette.HOLLOW_PURPLE
			# Unquiet: sways on its feet, the head jerks, the sword drifts.
			s.breath_hz = 0.24
			s.breath_lean = 0.02
			s.idle_blade = Vector2(0.09, 2.7)
			s.idle_lean = Vector2(0.045, 0.8)
			s.idle_bob = Vector2(1.3, 0.9)
			s.idle_head = Vector2(0.13, 2.5)
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
			s.accent = InkPalette.ONI_EMBER
			# Restless: heaves for breath, stomps from foot to foot, the club twitches.
			s.breath_hz = 0.6
			s.breath_amp = 0.03
			s.breath_lean = 0.03
			s.idle_blade = Vector2(0.08, 2.4)
			s.idle_lean = Vector2(0.06, 2.0)
			s.idle_bob = Vector2(2.6, 2.7)
			s.idle_head = Vector2(0.11, 1.7)
			s.idle_grip = 1.0
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
			s.accent = InkPalette.HEALER_JADE
			# Gentle: sways like grass, the head tilts softly, the wand drifts slowly.
			s.breath_hz = 0.26
			s.breath_amp = 0.014
			s.idle_blade = Vector2(0.055, 1.0)
			s.idle_lean = Vector2(0.022, 0.9)
			s.idle_bob = Vector2(0.6, 1.1)
			s.idle_head = Vector2(0.075, 0.7)
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
			s.accent = InkPalette.GUARDIAN_AZURE
			# Stoic: planted, hardly moves; a slow shift of the shield.
			s.breath_hz = 0.3
			s.idle_blade = Vector2(0.015, 1.2)
			s.idle_lean = Vector2(0.01, 1.0)
			s.idle_bob = Vector2(0.5, 0.8)
			s.idle_head = Vector2(0.04, 0.6)
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
			s.accent = InkPalette.ONMYOJI_MAGENTA
			# Serene: the talisman drifts by itself, the hand wanders, the body barely sways.
			s.breath_hz = 0.24
			s.idle_blade = Vector2(0.075, 1.4)
			s.idle_lean = Vector2(0.025, 0.8)
			s.idle_head = Vector2(0.085, 0.6)
			s.idle_grip = 0.9
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
			s.accent = InkPalette.HATAMOTO_ORANGE
			# Proud: upright, a steady naginata, a slow sweep of the eyes.
			s.breath_hz = 0.28
			s.idle_blade = Vector2(0.03, 1.3)
			s.idle_lean = Vector2(0.012, 1.2)
			s.idle_head = Vector2(0.05, 0.5)
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
		InkFigure.Kind.FALLEN_DAIMYO:
			s.accent = InkPalette.DAIMYO_CURSE
			# A boss: heavy and slow to breathe, the odachi held in two hands, nothing springs loose.
			s.hip_y = 46.0
			s.thigh = 23.0
			s.shin = 23.0
			s.thigh_w = Vector2(11.0, 9.5)
			s.shin_w = Vector2(9.5, 7.5)
			s.foot = 11.0
			s.stance = Vector2(8.0, -8.0)
			s.stride_len = 11.0
			s.shoulder_front = Vector2(7.0, -32.0)
			s.shoulder_back = Vector2(-6.0, -32.0)
			s.upper_arm = 13.5
			s.fore_arm = 13.5
			s.arm_w = Vector2(8.5, 7.0)
			s.fore_w = Vector2(7.0, 6.0)
			s.hand_r = 4.0
			s.neck = Vector2(3.0, -35.0)
			s.head_top = 118.0
			s.back_hand_on_weapon = Vector2(-16.0, 0.0)
			s.cadence = 7.5
			s.windup_rate = 12.0
			s.shadow_width = 34.0
			s.trail_span = Vector2(30.0, 108.0)
			s.trail_core = Color(InkPalette.DAIMYO_CURSE.lerp(InkPalette.PAPER, 0.35), 0.85)
			s.trail_edge = Color(InkPalette.DAIMYO_CURSE, 0.8)
			s.is_enemy = true
			s.death_accent = InkPalette.DAIMYO_CURSE
			s.springy = true
			# Proud and heavy: slow breath, a blade that hardly moves, a head that turns like a lord's.
			s.breath_hz = 0.2
			s.breath_amp = 0.012
			s.idle_blade = Vector2(0.025, 1.0)
			s.idle_lean = Vector2(0.015, 0.7)
			s.idle_head = Vector2(0.05, 0.4)
			s.idle_grip = 0.5
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
		InkFigure.Kind.FALLEN_DAIMYO:
			return _daimyo(state, heavy)
	return FigurePose.new()


## The samurai's key poses. Rule: the blade never passes through his body. Every pose keeps the
## blade (from the hands outward) in front of him, clear of the helmet, crest, armour and hakama;
## a test (test_art_style) checks it, along the swing too. Grips stay within the arm's reach
## (26) of the shoulder so the arms never stretch.
static func _samurai(state: StringName, step: int, heavy: bool) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			# Carried in two hands up and forward, the body leaning into the run.
			p = FigurePose.make(0.2, 1.5, Vector2(14.0, -24.0), -1.05).with_weight(2.0, 0.0)
		&"windup":
			match step:
				1: # rising cut: the katana low at the hip, point down and forward, the hips turned back, knees bent
					p = FigurePose.make(0.16, 8.0, Vector2(13.0, -11.0), 0.8).with_spread(1.6).with_weight(-3.0, 0.0)
				2: # thrust: drawn back to the hip, the point forward and a little up, the weight on the back foot
					p = FigurePose.make(-0.12, 7.0, Vector2(10.0, -15.0), -0.3).with_spread(1.7).with_weight(-5.0, 0.0)
				_: # downward cut: the katana raised high in front, the body coiled back, knees bent
					p = FigurePose.make(-0.2, 5.0, Vector2(21.0, -46.0), -1.4).with_head(-0.1).with_spread(1.55).with_weight(-5.0, 0.0)
		&"heavy_windup":
			p = FigurePose.make(-0.28, 10.0, Vector2(20.0, -49.0), -1.45).with_head(-0.16).with_spread(1.9).with_weight(-7.0, 0.0)
		&"strike":
			if heavy:
				# The full cut: hips driven over a deep front knee, the back foot planted, the point low in front.
				p = FigurePose.make(0.45, 13.0, Vector2(25.0, -17.0), 0.62).with_offset(2.0).with_spread(2.0).with_weight(9.0, 12.0)
			else:
				match step:
					1: # the rising cut finishing high at the front
						p = FigurePose.make(0.02, 7.0, Vector2(24.0, -34.0), -0.95).with_spread(1.7).with_weight(5.0, 8.0)
					2: # the thrust, lunging on a bent front knee
						p = FigurePose.make(0.38, 11.0, Vector2(27.0, -23.0), -0.12).with_offset(2.0).with_spread(1.95).with_weight(9.0, 12.0)
					_: # the downward cut
						p = FigurePose.make(0.32, 10.0, Vector2(24.0, -22.0), 0.45).with_spread(1.85).with_weight(8.0, 11.0)
		&"shoot":
			# The yumi at full draw (UnitVisual plays the whole shot from samurai_shoot).
			return samurai_shoot(SHOOT_RELEASE_TIME)
		&"war_cry":
			p = _samurai_war_cry_shout()
		&"cast":
			p = FigurePose.make(-0.02, 5.0, Vector2(21.0, -45.0), -1.25).with_head(-0.1).with_glow(1.0).with_spread(1.5).with_weight(-1.0, 0.0)
		&"dash":
			# A low forward thrust leads the charge.
			p = FigurePose.make(0.5, 10.0, Vector2(22.0, -18.0), -0.15).with_spread(1.6).with_weight(5.0, 6.0)
		&"hurt":
			p = FigurePose.make(-0.32, 3.0, Vector2(13.0, -14.0), -0.2).with_head(-0.35).with_offset(-5.0).with_weight(-3.0, 0.0)
		&"dead":
			# Falls with the body; the katana ends up lying on the ground (the body turns -1.45).
			p = FigurePose.make(0.0, 0.0, Vector2(14.0, -5.0), 1.5).with_head(-0.2)
		_:
			# Guard (chudan): both hands low in front of the belly, the point up toward the opponent's eyes, knees bent.
			p = FigurePose.make(0.05, 1.5, Vector2(17.0, -19.0), -0.62).with_spread(1.2).with_weight(1.0, 0.0)
	p.pivot = Vector2(5.0, -31.0)
	return p


## The Bow, in seconds from the key press: the samurai sheathes the katana and reaches back for the yumi on his
## back, pulls it out, draws, aims, and looses at SHOOT_RELEASE_TIME (when the arrow leaves, PlayerStats.bow_windup);
## then he follows through, stows the bow on his back and draws the katana again by SHOOT_TIME (windup + recovery,
## 0.3 s: the Bow fires every 0.4 s). The key poses are placed at fractions of SHOOT_TIME.
const SHOOT_RELEASE_TIME: float = 0.18
const SHOOT_TIME: float = 0.3
## The samurai's back hand rests here on the stowed yumi (torso space).
const BACK_BOW_GRIP: Vector2 = Vector2(-20.5, -31.0)
## The War Cry: he gathers, then (at WAR_CRY_SHOUT_TIME, PlayerStats.war_cry_windup) throws the katana up and shouts.
const WAR_CRY_SHOUT_TIME: float = 0.3

static var _shoot_keys: Array[Dictionary] = []


## The samurai's Bow pose `t` seconds into the shot (see SHOOT_RELEASE_TIME): smooth between the key poses.
static func samurai_shoot(t: float) -> FigurePose:
	if _shoot_keys.is_empty():
		_shoot_keys = [
			{"t": 0.0, "pose": _samurai(&"idle", 0, false)},
			# Reach back: katana sheathed, the free hand goes over the shoulder to the yumi.
			{"t": 0.14 * SHOOT_TIME, "pose": _shoot_key(-0.06, 3.0, Vector2(15.0, -27.0), -0.1, BACK_BOW_GRIP, 0.0, false)},
			# Pull it out: the bow is in the front hand, held out at head height.
			{"t": 0.28 * SHOOT_TIME, "pose": _shoot_key(0.04, 3.0, Vector2(24.0, -40.0), -0.06, Vector2(-14.0, -42.0), 0.0, true)},
			# Draw and aim.
			{"t": 0.56 * SHOOT_TIME, "pose": _shoot_key(0.1, 3.0, Vector2(25.0, -41.0), -0.06, Vector2(-14.0, -42.0), 1.0, true)},
			{"t": SHOOT_RELEASE_TIME, "pose": _shoot_key(0.1, 3.0, Vector2(25.0, -41.0), -0.06, Vector2(-14.0, -42.0), 1.0, true)},
			# Release: the string snaps forward, the drawing hand flings back, the bow hand kicks.
			{"t": 0.66 * SHOOT_TIME, "pose": _shoot_key(0.06, 3.0, Vector2(23.0, -40.0), -0.1, Vector2(-17.0, -36.0), 0.0, true)},
			{"t": 0.8 * SHOOT_TIME, "pose": _shoot_key(0.04, 3.0, Vector2(22.0, -39.0), -0.12, Vector2(-17.0, -37.0), 0.0, true)},
			# Stow: the bow goes back over the shoulder, the hand takes the katana again.
			{"t": 0.92 * SHOOT_TIME, "pose": _shoot_key(-0.02, 3.0, Vector2(16.0, -30.0), -0.2, BACK_BOW_GRIP, 0.0, true)},
			{"t": SHOOT_TIME, "pose": _samurai(&"idle", 0, false)},
		]
	var keys: Array[Dictionary] = _shoot_keys
	var result: FigurePose = FigurePose.new()
	if t <= float(keys[0]["t"]):
		result.copy_from(keys[0]["pose"] as FigurePose)
		return result
	for i: int in range(1, keys.size()):
		var until: float = keys[i]["t"]
		if t <= until:
			var from: float = keys[i - 1]["t"]
			result.copy_from(keys[i - 1]["pose"] as FigurePose)
			result.blend_toward(keys[i]["pose"] as FigurePose, smoothstep(0.0, 1.0, (t - from) / (until - from)))
			return result
	result.copy_from(keys[keys.size() - 1]["pose"] as FigurePose)
	return result


static func _shoot_key(lean: float, crouch: float, grip: Vector2, blade: float, back: Vector2, draw: float, bow_out: bool) -> FigurePose:
	var p: FigurePose = FigurePose.make(lean, crouch, grip, blade).with_back(back).with_bow(draw).with_sheathed(bow_out)
	p.spread = 1.45
	p.pivot = Vector2(5.0, -31.0)
	return p


## The War Cry's gathering (crouched, katana held low and pointing down) before the shout, which throws it up.
static func samurai_war_cry_gather() -> FigurePose:
	var p: FigurePose = FigurePose.make(0.18, 10.0, Vector2(16.0, -14.0), 0.9).with_head(0.12).with_spread(1.8).with_weight(2.0, 0.0)
	p.pivot = Vector2(5.0, -31.0)
	return p


## The shout: feet planted wide, the body arched back, the katana thrown straight up, the head up.
static func _samurai_war_cry_shout() -> FigurePose:
	return FigurePose.make(-0.12, 6.0, Vector2(19.0, -49.0), -1.35).with_head(-0.22).with_glow(0.6).with_spread(1.9)


## The title screen pose: hasso no kamae, katana raised in both hands beside the head, wide stance.
static func samurai_title_pose() -> FigurePose:
	var p: FigurePose = FigurePose.make(-0.02, 5.0, Vector2(21.0, -44.0), -1.25).with_head(-0.1).with_spread(1.8)
	p.pivot = Vector2(5.0, -31.0)
	return p


## How a state moves for springy kinds (see PoseSpring).
static func feel(kind: InkFigure.Kind, state: StringName, heavy: bool = false) -> PoseSpring.Feel:
	if kind == InkFigure.Kind.FALLEN_DAIMYO:
		return _daimyo_feel(state)
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
		&"war_cry":
			# Throws the katana up with a snap and overshoot, then holds.
			return PoseSpring.Feel.make(Vector2(24.0, 0.6), Vector2(34.0, 0.5), Vector2(28.0, 0.5))
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
	var hip: Vector2 = Vector2(pose_in.hip_shift, -(s.hip_y - pose_in.crouch))
	var torso: Transform2D = Transform2D(pose_in.lean, hip)
	var head: Transform2D = torso * Transform2D(pose_in.head_tilt, s.neck)
	var zones: Array[PackedVector2Array] = []
	# Do (chest armour) and the shoulder lames: narrow at the waist, broad at the chest, a little generous.
	zones.append(torso * PackedVector2Array([Vector2(-10.5, -1.0), Vector2(11.0, -1.0), Vector2(10.3, -10.0), Vector2(13.3, -19.0),
			Vector2(15.3, -26.0), Vector2(11.5, -31.0), Vector2(-10.5, -31.0), Vector2(-13.5, -26.0), Vector2(-12.0, -19.0),
			Vector2(-9.7, -10.0)]))
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
	return FigurePose.make(0.09, 2.0, Vector2(11.0, -14.0), -0.2).with_spread(1.1)


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
	var p: FigurePose
	match state:
		&"run":
			p = FigurePose.make(0.18, 2.0, Vector2(15.0, -16.0), 2.1)
		&"windup", &"heavy_windup":
			# The club is raised in front of the horn, standing up from the fist well clear of the head
			# (a test checks it); the slam then comes down in an arc in front of the body.
			p = FigurePose.make(-0.14, 2.0, Vector2(22.0, -68.0), -1.7)
		&"strike":
			p = FigurePose.make(0.32, 7.0, Vector2(30.0, -6.0), 1.2).with_offset(3.0)
		&"hurt":
			p = FigurePose.make(-0.12, 1.0, Vector2(18.0, -18.0), 0.7).with_head(-0.2)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(16.0, -10.0), 0.8)
		_:
			p = FigurePose.make(0.15, 3.0, Vector2(21.0, -17.0), 1.05).with_spread(1.1)
	p.pivot = Vector2(10.0, -43.0)
	return p


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
			p = FigurePose.make(0.07, 2.0, Vector2(10.0, -22.0), -0.14).with_back(Vector2(14.0, -15.0)).with_spread(1.2)
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
			p = FigurePose.make(-0.14, 5.0, Vector2(15.0, -40.0), -1.25).with_head(-0.08).with_spread(1.4).with_weight(-3.0, 0.0)
		&"strike":
			p = FigurePose.make(0.34, 8.0, Vector2(25.0, -17.0), 0.5).with_offset(2.0).with_spread(1.7).with_weight(5.0, 8.0)
		&"hurt":
			p = FigurePose.make(-0.3, 3.0, Vector2(11.0, -15.0), -0.3).with_head(-0.3).with_offset(-5.0).with_spread(1.4).with_weight(-3.0, 0.0)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(14.0, -5.0), 1.5).with_head(-0.2)
		_:
			p = FigurePose.make(0.05, 2.0, Vector2(13.0, -20.0), -0.85).with_spread(1.3)
	p.pivot = Vector2(6.0, -31.0)
	return p


## The Fallen Daimyo: an odachi in both hands. Wind-ups are big and readable (a boss is fought by
## reading them): `windup` coils the blade high behind him for the sweep (and crouches for the leap),
## `heavy_windup` raises it overhead (the slam; in the air during the leap), `cast` holds it straight up
## and glowing (the cursed wave and the summon), `strike` swings it (flat for a sweep, down for `heavy`).
static func _daimyo(state: StringName, heavy: bool) -> FigurePose:
	var p: FigurePose
	match state:
		&"run":
			p = FigurePose.make(0.2, 3.0, Vector2(13.0, -22.0), 0.0).with_spread(1.1)
		&"windup":
			p = FigurePose.make(-0.2, 8.0, Vector2(2.0, -26.0), -2.1).with_head(-0.12).with_spread(1.6)
		&"heavy_windup":
			p = FigurePose.make(-0.28, 9.0, Vector2(15.0, -46.0), -1.4).with_head(-0.16).with_spread(1.7)
		&"cast":
			p = FigurePose.make(-0.12, 4.0, Vector2(13.0, -42.0), -1.52).with_head(-0.22).with_glow(1.0).with_spread(1.45)
		&"strike":
			if heavy:
				p = FigurePose.make(0.42, 11.0, Vector2(26.0, -32.0), -0.1).with_offset(5.0).with_spread(1.8)
			else:
				p = FigurePose.make(0.3, 6.0, Vector2(28.0, -25.0), -0.05).with_offset(5.0).with_spread(1.7)
		&"hurt":
			p = FigurePose.make(-0.2, 3.0, Vector2(12.0, -22.0), 0.3).with_head(-0.25).with_offset(-3.0)
		&"dead":
			p = FigurePose.make(0.0, 0.0, Vector2(14.0, -5.0), 1.5).with_head(-0.2)
		_:
			# The blade carried low in front, the point well clear of the ground (a test checks it), shoulders hunched.
			p = FigurePose.make(0.1, 2.0, Vector2(12.0, -22.0), 0.2).with_spread(1.2)
	p.pivot = Vector2(7.0, -32.0)
	return p


## The Daimyo is heavy: his body and blade settle without bouncing (nearly critically damped), so the
## blade never swings past its pose and into the ground.
static func _daimyo_feel(state: StringName) -> PoseSpring.Feel:
	match state:
		&"strike":
			return PoseSpring.Feel.make(Vector2(30.0, 0.92), Vector2(42.0, 0.9), Vector2(46.0, 0.88))
		&"hurt":
			return PoseSpring.Feel.make(Vector2(34.0, 0.9), Vector2(40.0, 0.9), Vector2(40.0, 0.9))
		&"dead":
			return PoseSpring.Feel.make(Vector2(9.0, 1.0), Vector2(9.0, 1.0), Vector2(9.0, 1.0))
	return PoseSpring.Feel.make(Vector2(14.0, 0.95), Vector2(18.0, 0.92), Vector2(20.0, 0.9))


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
