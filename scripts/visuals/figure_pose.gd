class_name FigurePose
extends RefCounted
## One key pose of an InkFigure. Positions are in torso space (origin at the hips, +x forward,
## -y up) in figure units (figure height = 100). UnitVisual blends the live pose toward the
## pose of the current animation state every frame.

## Torso rotation about the hips (radians, + leans forward).
var lean: float = 0.0
## How far the hips drop (figure units).
var crouch: float = 0.0
## Whole-body shift along x (figure units, + forward).
var offset_x: float = 0.0
## Front hand position.
var grip: Vector2 = Vector2(12.0, -14.0)
## Weapon angle at the grip (0 = pointing forward, -PI/2 = up).
var blade: float = 0.0
## Back hand position, for figures whose back hand is not on the weapon.
var back_grip: Vector2 = Vector2(0.0, -6.0)
var head_tilt: float = 0.0
## Spirit glow along the weapon (0..1).
var glow: float = 0.0
## Bow draw (0 = rest, 1 = full draw).
var bow_draw: float = 0.0
## Bow string release snap (0..1).
var release: float = 0.0
## How far apart the feet are, as a multiple of the kind's rest stance.
var spread: float = 1.0
## The katana is sheathed (hidden; 0..1, shown below 0.5) and the back hand is free: the samurai using the bow.
var sheathed: float = 0.0
## The samurai's yumi is in his hand (0..1, shown from 0.5) instead of stowed on his back.
var bow_out: float = 0.0
## The hips move this far forward over the feet (figure units): weight onto the front leg. The feet stay where they
## are, so a hip shifted forward bends the front knee and keeps the back foot planted.
var hip_shift: float = 0.0
## The front foot steps this far forward of its rest stance (the back foot stays planted).
var lunge: float = 0.0
## The front shoulder (torso space). When set, `grip` moves along arcs around it (the arm
## swings like a pendulum) instead of in straight lines. NAN x = straight lines.
var pivot: Vector2 = Vector2(NAN, 0.0)


static func make(p_lean: float, p_crouch: float, p_grip: Vector2, p_blade: float) -> FigurePose:
	var pose: FigurePose = FigurePose.new()
	pose.lean = p_lean
	pose.crouch = p_crouch
	pose.grip = p_grip
	pose.blade = p_blade
	return pose


func with_back(p_back_grip: Vector2) -> FigurePose:
	back_grip = p_back_grip
	return self


func with_head(p_head_tilt: float) -> FigurePose:
	head_tilt = p_head_tilt
	return self


func with_offset(p_offset_x: float) -> FigurePose:
	offset_x = p_offset_x
	return self


func with_glow(p_glow: float) -> FigurePose:
	glow = p_glow
	return self


func with_spread(p_spread: float) -> FigurePose:
	spread = p_spread
	return self


## Weight forward: hips `p_hip_shift` over the feet, the front foot stepping `p_lunge` ahead.
func with_weight(p_hip_shift: float, p_lunge: float) -> FigurePose:
	hip_shift = p_hip_shift
	lunge = p_lunge
	return self


func with_bow(p_draw: float, p_release: float = 0.0) -> FigurePose:
	bow_draw = p_draw
	release = p_release
	return self


## The samurai's katana is sheathed; with `p_bow_out` his yumi is in his hand.
func with_sheathed(p_bow_out: bool) -> FigurePose:
	sheathed = 1.0
	bow_out = 1.0 if p_bow_out else 0.0
	return self


## Moves every value a fraction `weight` (0..1) of the way toward `target`.
func blend_toward(target: FigurePose, weight: float) -> void:
	lean = lerpf(lean, target.lean, weight)
	crouch = lerpf(crouch, target.crouch, weight)
	offset_x = lerpf(offset_x, target.offset_x, weight)
	grip = arc_lerp(grip, target.grip, weight, pivot if not is_nan(pivot.x) else target.pivot)
	blade = lerpf(blade, target.blade, weight)
	back_grip = back_grip.lerp(target.back_grip, weight)
	head_tilt = lerpf(head_tilt, target.head_tilt, weight)
	glow = lerpf(glow, target.glow, weight)
	bow_draw = lerpf(bow_draw, target.bow_draw, weight)
	release = lerpf(release, target.release, weight)
	spread = lerpf(spread, target.spread, weight)
	hip_shift = lerpf(hip_shift, target.hip_shift, weight)
	lunge = lerpf(lunge, target.lunge, weight)
	sheathed = lerpf(sheathed, target.sheathed, weight)
	bow_out = lerpf(bow_out, target.bow_out, weight)


func copy_from(other: FigurePose) -> void:
	blend_toward(other, 1.0)
	pivot = other.pivot


## A point moved a fraction `weight` of the way from `from` to `to`: in a straight line, or (with
## a pivot) along the arc around it, so a swinging hand keeps its arm length.
static func arc_lerp(from: Vector2, to: Vector2, weight: float, around: Vector2) -> Vector2:
	if is_nan(around.x):
		return from.lerp(to, weight)
	var a: Vector2 = from - around
	var b: Vector2 = to - around
	if a.length_squared() < 0.0001 or b.length_squared() < 0.0001:
		return from.lerp(to, weight)
	var turn: float = wrapf(b.angle() - a.angle(), -PI, PI)
	return around + Vector2.from_angle(a.angle() + turn * weight) * lerpf(a.length(), b.length(), weight)
