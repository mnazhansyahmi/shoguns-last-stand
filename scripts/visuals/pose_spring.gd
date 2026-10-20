class_name PoseSpring
extends RefCounted
## Drives a FigurePose toward a target pose with spring-dampers instead of a plain blend, so a
## cut gets anticipation (the wind-up overshoots a little backward), a snap that accelerates into
## the target, and follow-through (the blade overshoots, then settles). Each group of channels
## has its own stiffness and damping: the blade is loose and whips, the body is heavier.
## Visual only. The hand follows an arc around the shoulder when the pose has a pivot.

## Physics sub-step. Springs this stiff are only stable below about 1 / (omega * 2).
const STEP: float = 1.0 / 120.0
const MAX_FRAME: float = 0.05
## The hand never reaches further than this from the shoulder (the arm is 26 long).
const MAX_REACH: float = 25.6


## How a state moves: natural frequency (rad/s) and damping ratio (1 = no overshoot, 0.5 = a
## clear overshoot) for the body, the hand and the blade.
class Feel:
	var body_omega: float = 12.0
	var body_zeta: float = 0.85
	var hand_omega: float = 14.0
	var hand_zeta: float = 0.8
	var blade_omega: float = 14.0
	var blade_zeta: float = 0.7

	static func make(body: Vector2, hand: Vector2, blade: Vector2) -> Feel:
		var feel: Feel = Feel.new()
		feel.body_omega = body.x
		feel.body_zeta = body.y
		feel.hand_omega = hand.x
		feel.hand_zeta = hand.y
		feel.blade_omega = blade.x
		feel.blade_zeta = blade.y
		return feel


var _lean: float = 0.0
var _crouch: float = 0.0
var _offset: float = 0.0
var _spread: float = 0.0
var _head: float = 0.0
var _blade: float = 0.0
var _hand_angle: float = 0.0
var _hand_radius: float = 0.0
var _back: Vector2 = Vector2.ZERO


## Forgets all motion (after a teleport or a hard pose change).
func stop() -> void:
	_lean = 0.0
	_crouch = 0.0
	_offset = 0.0
	_spread = 0.0
	_head = 0.0
	_blade = 0.0
	_hand_angle = 0.0
	_hand_radius = 0.0
	_back = Vector2.ZERO


## Gives the blade and hand a kick (radians/s), e.g. to start a cut with a small counter-swing.
func nudge(blade_speed: float, hand_angle_speed: float) -> void:
	_blade += blade_speed
	_hand_angle += hand_angle_speed


## Advances `pose` toward `target` by `delta` seconds.
func step(pose: FigurePose, target: FigurePose, feel: Feel, delta: float) -> void:
	var remaining: float = minf(delta, MAX_FRAME)
	var count: int = maxi(1, ceili(remaining / STEP - 0.001))
	var h: float = remaining / float(count)
	for i: int in count:
		_step_once(pose, target, feel, h)
	# Slow channels with no overshoot of their own.
	var settle: float = 1.0 - exp(-10.0 * remaining)
	pose.glow = lerpf(pose.glow, target.glow, settle)
	pose.bow_draw = lerpf(pose.bow_draw, target.bow_draw, settle)
	pose.release = lerpf(pose.release, target.release, settle)
	pose.sheathed = lerpf(pose.sheathed, target.sheathed, settle)
	pose.bow_out = lerpf(pose.bow_out, target.bow_out, settle)
	pose.pivot = target.pivot


func _step_once(pose: FigurePose, target: FigurePose, feel: Feel, h: float) -> void:
	var body_k: float = feel.body_omega * feel.body_omega
	var body_c: float = 2.0 * feel.body_zeta * feel.body_omega
	_lean += _accel(target.lean - pose.lean, _lean, body_k, body_c) * h
	pose.lean += _lean * h
	_crouch += _accel(target.crouch - pose.crouch, _crouch, body_k, body_c) * h
	pose.crouch += _crouch * h
	_offset += _accel(target.offset_x - pose.offset_x, _offset, body_k, body_c) * h
	pose.offset_x += _offset * h
	_spread += _accel(target.spread - pose.spread, _spread, body_k, body_c) * h
	pose.spread += _spread * h
	_head += _accel(target.head_tilt - pose.head_tilt, _head, body_k, body_c) * h
	pose.head_tilt += _head * h

	var blade_k: float = feel.blade_omega * feel.blade_omega
	var blade_c: float = 2.0 * feel.blade_zeta * feel.blade_omega
	_blade += _accel(target.blade - pose.blade, _blade, blade_k, blade_c) * h
	pose.blade += _blade * h

	var hand_k: float = feel.hand_omega * feel.hand_omega
	var hand_c: float = 2.0 * feel.hand_zeta * feel.hand_omega
	_back += (target.back_grip - pose.back_grip) * hand_k * h - _back * hand_c * h
	pose.back_grip += _back * h
	if is_nan(target.pivot.x):
		pose.grip = pose.grip.lerp(target.grip, 1.0 - exp(-feel.hand_omega * h))
		return
	# The hand swings around the shoulder: spring its angle and its distance from it.
	var from: Vector2 = pose.grip - target.pivot
	var to: Vector2 = target.grip - target.pivot
	var angle: float = from.angle()
	var radius: float = from.length()
	var turn_error: float = wrapf(to.angle() - angle, -PI, PI)
	_hand_angle += _accel(turn_error, _hand_angle, hand_k, hand_c) * h
	_hand_radius += _accel(to.length() - radius, _hand_radius, hand_k, hand_c) * h
	angle += _hand_angle * h
	radius = clampf(radius + _hand_radius * h, 2.0, MAX_REACH)
	pose.grip = target.pivot + Vector2.from_angle(angle) * radius


static func _accel(error: float, velocity: float, k: float, c: float) -> float:
	return k * error - c * velocity
