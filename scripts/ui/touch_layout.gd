class_name TouchLayout
extends RefCounted
## Pure layout math for the touch controls, so it can be tested without nodes.
## Rects are in viewport (canvas) units. The design height is 1080 units.
##
## Touch target size: iPhone 16 is 393 pt tall in landscape and the canvas is 1080 units tall
## (stretch aspect "expand" keeps the height), so 44 pt is about 1080 × 44 / 393 ≈ 121 units.

const MARGIN: float = 36.0
const MIN_TOUCH_TARGET: float = 121.0
## Gap kept between the ground line (unit feet) and the top of the joystick/action clusters.
const GROUND_CLEARANCE: float = 24.0
## Touch widgets at rest are drawn at this opacity; held widgets are fully opaque.
const IDLE_OPACITY: float = 0.6
const JOYSTICK_SIZE: Vector2 = Vector2(320.0, 320.0)
const ACTION_CLUSTER_SIZE: Vector2 = Vector2(540.0, 500.0)
## Summon buttons: up to six allies, one per unlocked ally. They are as big as fits (up to
## SUMMON_MAX_SIZE x the UI scale) in one row between the two side clusters, never smaller than
## SUMMON_MIN_SIZE (44 pt); when even that does not fit they wrap to two rows.
const MAX_SUMMONS: int = 6
const SUMMON_MAX_SIZE: float = 170.0
const SUMMON_MIN_SIZE: float = 125.0
const SUMMON_GAP: float = 18.0
## Free space kept between the summon bar and the joystick / action cluster.
const SUMMON_SIDE_GAP: float = 24.0
## The ally stance button sits above the summon bar.
const STANCE_SIZE: Vector2 = Vector2(210.0, 125.0)
const STANCE_GAP: float = 58.0
## Right-handed positions inside the action cluster: arcs around the Attack button, which sits under the thumb in the
## corner. Closest ring: Heavy (to its left) and Dash (above it). Next ring: Spirit and Bow. Furthest: the Ultimate
## (bottom left) and the War Cry (top). Every button is a circle at least 44 pt across and none touch.
const ACTION_BUTTONS: Dictionary = {
	"attack": Rect2(350.0, 308.0, 190.0, 190.0),
	"heavy": Rect2(186.0, 328.0, 150.0, 150.0),
	"dash": Rect2(370.0, 149.0, 150.0, 150.0),
	"slash": Rect2(120.0, 170.0, 140.0, 140.0),
	"bow": Rect2(235.0, 65.0, 140.0, 140.0),
	# The Ultimate is big, and glows when it is ready.
	"ultimate": Rect2(3.0, 310.0, 170.0, 170.0),
	"war_cry": Rect2(385.0, 0.0, 140.0, 140.0),
}


static func clamp_scale(ui_scale: float) -> float:
	return clampf(ui_scale, GameSettings.MIN_UI_SCALE, GameSettings.MAX_UI_SCALE)


## How the summon buttons are laid out for `count` allies in `available_width`: {"size": button edge,
## "cols", "rows", "gap", "cluster": the bar's size}. One row if the buttons fit at 44 pt or more,
## otherwise two rows.
static func summon_metrics(count: int, available_width: float, ui_scale: float) -> Dictionary:
	var n: int = clampi(count, 1, MAX_SUMMONS)
	var max_size: float = SUMMON_MAX_SIZE * clamp_scale(ui_scale)
	var gap: float = SUMMON_GAP
	var cols: int = n
	var rows: int = 1
	var size: float = (available_width - float(n - 1) * gap) / float(n)
	if size < SUMMON_MIN_SIZE and n > 1:
		rows = 2
		cols = ceili(float(n) / 2.0)
		size = (available_width - float(cols - 1) * gap) / float(cols)
	size = clampf(size, SUMMON_MIN_SIZE, maxf(max_size, SUMMON_MIN_SIZE))
	var row_gap: float = maxf(gap, size * 0.25 + 8.0)
	return {"size": size, "cols": cols, "rows": rows, "gap": gap, "row_gap": row_gap,
			"cluster": Vector2(float(cols) * size + float(cols - 1) * gap, float(rows) * size + float(rows - 1) * row_gap)}


## Cluster rects: "joystick", "actions", "summons". Left-handed mirrors joystick and actions.
## `summon_count` = how many allies are unlocked (the summons bar is as wide as they need).
static func compute(viewport_size: Vector2, safe_rect: Rect2, ui_scale: float, left_handed: bool,
		summon_count: int = 2) -> Dictionary:
	var scale_factor: float = clamp_scale(ui_scale)
	var safe: Rect2 = safe_rect.intersection(Rect2(Vector2.ZERO, viewport_size))
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		safe = Rect2(Vector2.ZERO, viewport_size)
	var joystick_size: Vector2 = JOYSTICK_SIZE * scale_factor
	var actions_size: Vector2 = ACTION_CLUSTER_SIZE * scale_factor
	var left_x: float = safe.position.x + MARGIN
	var right_x: float = safe.end.x - MARGIN
	var bottom_y: float = safe.end.y - MARGIN

	var joystick: Rect2 = Rect2(Vector2(left_x, bottom_y - joystick_size.y), joystick_size)
	var actions: Rect2 = Rect2(Vector2(right_x - actions_size.x, bottom_y - actions_size.y), actions_size)
	if left_handed:
		joystick.position.x = right_x - joystick_size.x
		actions.position.x = left_x
	# The summon bar sits between the two side clusters, centered on the screen if it fits there.
	var span_left: float = (actions.end.x if left_handed else joystick.end.x) + SUMMON_SIDE_GAP
	var span_right: float = (joystick.position.x if left_handed else actions.position.x) - SUMMON_SIDE_GAP
	var metrics: Dictionary = summon_metrics(summon_count, span_right - span_left, ui_scale)
	var summons_size: Vector2 = metrics["cluster"]
	var summons_x: float = clampf(safe.get_center().x - summons_size.x * 0.5, span_left, maxf(span_right - summons_size.x, span_left))
	var summons: Rect2 = Rect2(Vector2(summons_x, bottom_y - summons_size.y), summons_size)
	# On narrow screens or large UI scales, lift the summons above the side clusters.
	if summons.intersects(joystick) or summons.intersects(actions):
		summons.position.x = safe.get_center().x - summons_size.x * 0.5
		summons.position.y = minf(joystick.position.y, actions.position.y) - MARGIN - summons_size.y
	var stance_size: Vector2 = STANCE_SIZE * minf(scale_factor, 1.15)
	stance_size = Vector2(maxf(stance_size.x, MIN_TOUCH_TARGET), maxf(stance_size.y, MIN_TOUCH_TARGET))
	var stance: Rect2 = Rect2(Vector2(summons.get_center().x - stance_size.x * 0.5, summons.position.y - STANCE_GAP - stance_size.y), stance_size)
	return {"joystick": joystick, "actions": actions, "summons": summons, "stance": stance}


## How far (in screen units) the view must move up so the ground line, currently at
## `ground_screen_y`, ends GROUND_CLEARANCE above the joystick and action clusters.
## Units and the gate stand on the ground, so this keeps them all above the controls.
static func ground_lift(rects: Dictionary, ground_screen_y: float) -> float:
	var joystick: Rect2 = rects["joystick"]
	var actions: Rect2 = rects["actions"]
	var clusters_top: float = minf(joystick.position.y, actions.position.y)
	return maxf(ground_screen_y - (clusters_top - GROUND_CLEARANCE), 0.0)


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


## Summon button rects local to the summons bar, in slot order (left to right, top row first).
static func summon_button_rects(count: int, bar_size: Vector2, ui_scale: float) -> Array[Rect2]:
	var n: int = clampi(count, 1, MAX_SUMMONS)
	# Recover the layout from the bar's own size: it was built by summon_metrics().
	var metrics: Dictionary = summon_metrics(n, bar_size.x, ui_scale)
	var size: float = metrics["size"]
	var cols: int = metrics["cols"]
	var gap: float = metrics["gap"]
	var row_gap: float = metrics["row_gap"]
	var result: Array[Rect2] = []
	for i: int in n:
		result.append(Rect2(Vector2(float(i % cols) * (size + gap), float(i / cols) * (size + row_gap)), Vector2(size, size)))
	return result


## Smallest button edge at this UI scale (must stay >= MIN_TOUCH_TARGET).
static func smallest_touch_target(ui_scale: float) -> float:
	var smallest: float = JOYSTICK_SIZE.x
	for rect: Rect2 in ACTION_BUTTONS.values():
		smallest = minf(smallest, minf(rect.size.x, rect.size.y))
	return minf(smallest * clamp_scale(ui_scale), SUMMON_MIN_SIZE)


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
