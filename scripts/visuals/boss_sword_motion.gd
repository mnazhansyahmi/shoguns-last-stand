class_name BossSwordMotion
extends RefCounted
## One rigid hilt drives both wrists. No independent blade spring or angle wrapping.
const HALF_GRIP: float = 8.0
const MAX_ANGULAR_SPEED: float = PI * 6.0 # 18 degrees per 60-Hz frame.
const FOLLOW_THROUGH: float = 0.06
var active: bool = false
var stage: StringName = &""
var _kind: BossAttackData.Kind
var _from: FigurePose = FigurePose.new()
var _to: FigurePose = FigurePose.new()
var _elapsed: float = 0.0
var _duration: float = 1.0
var _recover: float = -1.0


static func key_pose(phase: StringName, kind: BossAttackData.Kind) -> FigurePose:
	var angle: float = -0.24
	var lean: float = 0.06
	var crouch: float = 2.0
	if phase in [&"windup", &"air"]:
		angle = -2.60 if kind in [BossAttackData.Kind.SWEEP, BossAttackData.Kind.SLAM, BossAttackData.Kind.LEAP] else -1.90
		lean = -0.12
		crouch = 6.0
	elif phase == &"strike":
		angle = 0.40 if kind in [BossAttackData.Kind.SLAM, BossAttackData.Kind.LEAP] else 0.25
		lean = 0.17
		crouch = 8.0
	var center: Vector2 = Vector2(16.0, -31.0)
	var pose: FigurePose = FigurePose.make(lean, crouch, center + Vector2.from_angle(angle) * HALF_GRIP, angle)
	pose.spread = 1.4 if phase != &"recover" else 1.3
	pose.head_tilt = -0.08 if phase in [&"windup", &"air"] else 0.02
	return pose


func begin(phase: StringName, kind: BossAttackData.Kind, duration: float, pose: FigurePose) -> void:
	if phase == &"recover" and active and stage == &"strike" and _elapsed < _duration + FOLLOW_THROUGH:
		_recover = duration
		return
	active = true
	stage = phase
	_kind = kind
	_from.copy_from(pose)
	_to = key_pose(phase, kind)
	_elapsed = 0.0
	_duration = maxf(duration, (0.16 if pose.blade > -1.4 else 0.26) if phase == &"strike" else 0.12)
	_recover = -1.0


func step(pose: FigurePose, delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
	if stage in [&"windup", &"air"]: t = minf(t / 0.65, 1.0)
	var eased: float = t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
	var target_angle: float = lerpf(_from.blade, _to.blade, eased)
	# Start the fast cut at the end of the warning so its front arc coincides
	# with the gameplay impact, including a leap's descent. Summoning holds its chant.
	if stage in [&"windup", &"air"] and _kind != BossAttackData.Kind.SUMMON:
		var lead: float = smoothstep(maxf(0.0, _duration - 0.12), _duration, _elapsed)
		target_angle = lerpf(target_angle, -1.1, lead)
	var angle: float = move_toward(pose.blade, target_angle, MAX_ANGULAR_SPEED * delta)
	var from_center: Vector2 = _from.grip - Vector2.from_angle(_from.blade) * HALF_GRIP
	var to_center: Vector2 = _to.grip - Vector2.from_angle(_to.blade) * HALF_GRIP
	pose.copy_from(_from)
	pose.blend_toward(_to, eased)
	pose.blade = angle
	pose.grip = from_center.lerp(to_center, eased) + Vector2.from_angle(angle) * HALF_GRIP
	if _elapsed >= _duration and absf(angle - _to.blade) < 0.001:
		if stage == &"recover": active = false
		elif stage == &"strike" and _recover >= 0 and _elapsed >= _duration + FOLLOW_THROUGH:
			begin(&"recover", _kind, _recover, pose)
