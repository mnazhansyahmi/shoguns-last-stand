class_name PortraitMotion
extends InkFigure
## The title uses the articulated combat figure with an authored resting pose.
## Each limb, the head, hair and cloth have independent frames; no image warp.

var reduced_motion: bool = false


func _ready() -> void:
	height = 100.0
	show_stowed_bow = false
	super._ready()
	set_kind(Kind.SAMURAI)
	spec.back_hand_on_weapon = Vector2(NAN, 0.0)
	var weapon: FigurePart = get_node("weapon") as FigurePart
	# A resting one-handed hold: the hand around the middle of the hilt (the sword slid 4 units forward along its
	# axis), so the pommel stays clear of his chest instead of crowding it.
	weapon.art_frame = Transform2D(0.0, Vector2(0.78, 0.8), 0.0, Vector2(4.0, 0.0)) * weapon.art_frame
	upright = true
	set_time(0.0)


func set_time(seconds: float) -> void:
	clock = seconds
	var amount: float = 0.15 if reduced_motion else 1.0
	breath = sin(seconds * TAU * 0.22) * amount
	pose.lean = 0.015 + sin(seconds * 0.8) * 0.007 * amount
	pose.crouch = 0.0
	pose.spread = 1.1
	pose.grip = Vector2(17.0, -10.0) + Vector2(0.3, 0.4) * breath
	pose.back_grip = Vector2(-12.0, -8.0) + Vector2(0.1, 0.25) * breath
	pose.blade = 0.7 + sin(seconds * 0.9) * 0.012 * amount
	pose.head_tilt = -0.03 + sin(seconds * 0.65) * 0.018 * amount
	refresh()
