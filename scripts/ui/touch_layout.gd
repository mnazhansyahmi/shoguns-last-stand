class_name TouchLayout
extends RefCounted
## Pure layout math for the touch controls, so it can be tested without nodes.
## Rects are in viewport (canvas) units. The design height is 1080 units.
##
## Touch target size: iPhone 16 is 393 pt tall in landscape and the canvas is 1080 units tall
## (stretch aspect "expand" keeps the height), so 44 pt is about 1080 × 44 / 393 ≈ 121 units.

const MARGIN: float = 36.0
const MIN_TOUCH_TARGET: float = 121.0
const JOYSTICK_SIZE: Vector2 = Vector2(320.0, 320.0)
const ACTION_CLUSTER_SIZE: Vector2 = Vector2(470.0, 350.0)
const SUMMON_CLUSTER_SIZE: Vector2 = Vector2(380.0, 170.0)
## Right-handed positions inside the action cluster (Attack nearest the thumb's corner).
const ACTION_BUTTONS: Dictionary = {
	"attack": Rect2(280.0, 160.0, 190.0, 190.0),
	"heavy": Rect2(110.0, 200.0, 150.0, 150.0),
	"dash": Rect2(300.0, 0.0, 150.0, 150.0),
	"slash": Rect2(120.0, 30.0, 150.0, 150.0),
}
const SUMMON_BUTTONS: Dictionary = {
	"summon_1": Rect2(0.0, 0.0, 170.0, 170.0),
	"summon_2": Rect2(210.0, 0.0, 170.0, 170.0),
}


static func clamp_scale(ui_scale: float) -> float:
	return clampf(ui_scale, GameSettings.MIN_UI_SCALE, GameSettings.MAX_UI_SCALE)


## Cluster rects: "joystick", "actions", "summons". Left-handed mirrors joystick and actions.
static func compute(viewport_size: Vector2, safe_rect: Rect2, ui_scale: float, left_handed: bool) -> Dictionary:
	var scale_factor: float = clamp_scale(ui_scale)
	var safe: Rect2 = safe_rect.intersection(Rect2(Vector2.ZERO, viewport_size))
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		safe = Rect2(Vector2.ZERO, viewport_size)
	var joystick_size: Vector2 = JOYSTICK_SIZE * scale_factor
	var actions_size: Vector2 = ACTION_CLUSTER_SIZE * scale_factor
	var summons_size: Vector2 = SUMMON_CLUSTER_SIZE * scale_factor
	var left_x: float = safe.position.x + MARGIN
	var right_x: float = safe.end.x - MARGIN
	var bottom_y: float = safe.end.y - MARGIN

	var joystick: Rect2 = Rect2(Vector2(left_x, bottom_y - joystick_size.y), joystick_size)
	var actions: Rect2 = Rect2(Vector2(right_x - actions_size.x, bottom_y - actions_size.y), actions_size)
	if left_handed:
		joystick.position.x = right_x - joystick_size.x
		actions.position.x = left_x
	var summons: Rect2 = Rect2(Vector2(safe.get_center().x - summons_size.x * 0.5, bottom_y - summons_size.y), summons_size)
	# On narrow screens or large UI scales, lift the summons above the side clusters.
	if summons.intersects(joystick) or summons.intersects(actions):
		summons.position.y = minf(joystick.position.y, actions.position.y) - MARGIN - summons_size.y
	return {"joystick": joystick, "actions": actions, "summons": summons}


## Button rects local to the action cluster, mirrored for left-handed play.
static func action_button_rects(ui_scale: float, left_handed: bool) -> Dictionary:
	var scale_factor: float = clamp_scale(ui_scale)
	var result: Dictionary = {}
	for key: String in ACTION_BUTTONS:
		var rect: Rect2 = ACTION_BUTTONS[key]
		if left_handed:
			rect.position.x = ACTION_CLUSTER_SIZE.x - rect.end.x
		result[key] = Rect2(rect.position * scale_factor, rect.size * scale_factor)
	return result


static func summon_button_rects(ui_scale: float) -> Dictionary:
	var scale_factor: float = clamp_scale(ui_scale)
	var result: Dictionary = {}
	for key: String in SUMMON_BUTTONS:
		var rect: Rect2 = SUMMON_BUTTONS[key]
		result[key] = Rect2(rect.position * scale_factor, rect.size * scale_factor)
	return result


## Smallest button edge at this UI scale (must stay >= MIN_TOUCH_TARGET).
static func smallest_touch_target(ui_scale: float) -> float:
	var smallest: float = JOYSTICK_SIZE.x
	for rect: Rect2 in ACTION_BUTTONS.values() + SUMMON_BUTTONS.values():
		smallest = minf(smallest, minf(rect.size.x, rect.size.y))
	return smallest * clamp_scale(ui_scale)


## The OS safe area (notch, home indicator) converted to viewport units. Full rect on desktop.
static func get_safe_rect(viewport: Viewport) -> Rect2:
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var full: Rect2 = Rect2(Vector2.ZERO, viewport_size)
	if not OS.has_feature("mobile"):
		return full
	var window_size: Vector2i = DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return full
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var factor: Vector2 = viewport_size / Vector2(window_size)
	var position: Vector2 = Vector2(safe.position - DisplayServer.window_get_position()) * factor
	var rect: Rect2 = Rect2(position, Vector2(safe.size) * factor).intersection(full)
	return rect if rect.size.x > 0.0 and rect.size.y > 0.0 else full
