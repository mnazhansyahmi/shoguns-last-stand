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


func with_bow(p_draw: float, p_release: float = 0.0) -> FigurePose:
	bow_draw = p_draw
	release = p_release
	return self


## Moves every value a fraction `weight` (0..1) of the way toward `target`.
func blend_toward(target: FigurePose, weight: float) -> void:
	lean = lerpf(lean, target.lean, weight)
	crouch = lerpf(crouch, target.crouch, weight)
	offset_x = lerpf(offset_x, target.offset_x, weight)
	grip = grip.lerp(target.grip, weight)
	blade = lerpf(blade, target.blade, weight)
	back_grip = back_grip.lerp(target.back_grip, weight)
	head_tilt = lerpf(head_tilt, target.head_tilt, weight)
	glow = lerpf(glow, target.glow, weight)
	bow_draw = lerpf(bow_draw, target.bow_draw, weight)
	release = lerpf(release, target.release, weight)
	spread = lerpf(spread, target.spread, weight)


func copy_from(other: FigurePose) -> void:
	blend_toward(other, 1.0)
