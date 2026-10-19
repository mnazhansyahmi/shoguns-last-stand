class_name TouchControls
extends CanvasLayer
## On-screen controls: joystick, action buttons and summon buttons.
## Touches are routed by touch index in _input, so moving and attacking work at the same time.
## Controls ignore the mouse; with "emulate touch from mouse" they can be tested on Windows.
## Pausable: input stops while paused and every held action is released.

@onready var _joystick: TouchJoystick = $Root/Joystick
@onready var _action_cluster: Control = $Root/ActionCluster
@onready var _summon_cluster: Control = $Root/SummonCluster
@onready var _buttons: Dictionary = {
	"attack": $Root/ActionCluster/AttackButton,
	"heavy": $Root/ActionCluster/HeavyButton,
	"dash": $Root/ActionCluster/DashButton,
	"slash": $Root/ActionCluster/SlashButton,
	"ultimate": $Root/ActionCluster/UltimateButton,
	"summon_1": $Root/SummonCluster/Summon1Button,
	"summon_2": $Root/SummonCluster/Summon2Button,
	"summon_3": $Root/SummonCluster/Summon3Button,
	"summon_4": $Root/SummonCluster/Summon4Button,
	"summon_5": $Root/SummonCluster/Summon5Button,
	"summon_6": $Root/SummonCluster/Summon6Button,
}

var _active: bool = true
var _left_handed: bool = false
## How many summon buttons are shown (the unlocked allies).
var _summon_count: int = 2
var _last_layout: Array = []


func _input(event: InputEvent) -> void:
	if _active and handle_input(event):
		get_viewport().set_input_as_handled()


## Routes a touch/drag event to the widget that owns it. Returns true if consumed.
func handle_input(event: InputEvent) -> bool:
	if not _active or not TouchInput.is_touch_event(event):
		return false
	if _joystick.handle_touch(event):
		return true
	for button: TouchActionButton in _buttons.values():
		if button.visible and button.handle_touch(event):
			return true
	return false


func set_active(active: bool) -> void:
	_active = active
	visible = active
	if not active:
		release_all()


func is_active() -> bool:
	return _active


func release_all() -> void:
	_joystick.release()
	for button: TouchActionButton in _buttons.values():
		button.release()


## Positions every cluster from TouchLayout using corner anchors plus safe-area offsets.
func apply_layout(viewport_size: Vector2, safe_rect: Rect2, ui_scale: float, left_handed: bool) -> void:
	_left_handed = left_handed
	_last_layout = [viewport_size, safe_rect, ui_scale, left_handed]
	var rects: Dictionary = TouchLayout.compute(viewport_size, safe_rect, ui_scale, left_handed, _summon_count)
	_place(_joystick, rects["joystick"], viewport_size)
	_place(_action_cluster, rects["actions"], viewport_size)
	_place(_summon_cluster, rects["summons"], viewport_size)
	var action_rects: Dictionary = TouchLayout.action_button_rects(ui_scale, left_handed)
	for key: String in action_rects:
		_set_local_rect(_buttons[key], action_rects[key])
	var summons: Rect2 = rects["summons"]
	var summon_rects: Array[Rect2] = TouchLayout.summon_button_rects(_summon_count, summons.size, ui_scale)
	for slot: int in TouchLayout.MAX_SUMMONS:
		var button: TouchActionButton = _buttons["summon_%d" % (slot + 1)]
		button.visible = slot < _summon_count
		if slot < summon_rects.size():
			_set_local_rect(button, summon_rects[slot])
			# Smaller buttons get smaller captions so "Guardian" and "Hatamoto" still fit.
			button.font_size = roundi(28.0 * clampf(summon_rects[slot].size.x / TouchLayout.SUMMON_MAX_SIZE, 0.8, 1.0) * font_factor(ui_scale))
	var font_scale: float = TouchLayout.clamp_scale(ui_scale)
	for key: String in _buttons:
		var button: TouchActionButton = _buttons[key]
		if not key.begins_with("summon_"):
			button.font_size = roundi(30.0 * font_scale)
		button.queue_redraw()
	_joystick.queue_redraw()


## Caption size factor at a UI scale (the summon buttons' own size already carries the scale).
static func font_factor(ui_scale: float) -> float:
	return clampf(TouchLayout.clamp_scale(ui_scale), 0.9, 1.15)


## Shows one summon button per unlocked ally (1..6) and re-lays out the bar.
func set_summon_count(count: int) -> void:
	_summon_count = clampi(count, 1, TouchLayout.MAX_SUMMONS)
	for slot: int in TouchLayout.MAX_SUMMONS:
		var button: TouchActionButton = _buttons["summon_%d" % (slot + 1)]
		button.visible = slot < _summon_count
		if not button.visible:
			button.release()
	if _last_layout.size() == 4:
		apply_layout(_last_layout[0], _last_layout[1], _last_layout[2], _last_layout[3])


func get_summon_count() -> int:
	return _summon_count


func is_left_handed() -> bool:
	return _left_handed


## Global rect of a widget: "joystick", "attack", "heavy", "dash", "slash", "ultimate", "summon_1", "summon_2".
func get_widget_rect(widget: String) -> Rect2:
	if widget == "joystick":
		return _joystick.get_global_rect()
	var button: TouchActionButton = _buttons.get(widget)
	return button.get_global_rect() if button != null else Rect2()


func set_ability_cooldown(widget: String, ratio: float, seconds: float) -> void:
	var button: TouchActionButton = _buttons.get(widget)
	if button != null:
		button.set_cooldown(ratio, seconds)


## The Ultimate button's charge ring and glow.
func set_ultimate_charge(ratio: float, is_ready: bool) -> void:
	var button: TouchActionButton = _buttons.get("ultimate")
	if button == null:
		return
	button.set_charge(ratio, is_ready)
	button.set_captions("Ultimate", "READY" if is_ready else "%d%%" % floori(ratio * 100.0))


func set_summon_state(slot: int, name: String, cost: int, ratio: float, seconds: float, affordable: bool,
		accent: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
	var button: TouchActionButton = _buttons.get("summon_%d" % (slot + 1))
	if button == null:
		return
	if accent.a > 0.0 and accent != button.base_color:
		button.base_color = accent
		button.queue_redraw()
	button.set_captions(name, "%d SE" % cost)
	button.set_cooldown(ratio, seconds)
	button.set_available(affordable, "need %d" % cost)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_node_ready():
		release_all()


## Leaving the scene (Restart, Retry, Main Menu) must not leave actions held into the next scene.
func _exit_tree() -> void:
	release_all()


func _place(control: Control, rect: Rect2, viewport_size: Vector2) -> void:
	var center: Vector2 = rect.get_center()
	var anchor_x: float = 0.5
	if center.x < viewport_size.x * 0.4:
		anchor_x = 0.0
	elif center.x > viewport_size.x * 0.6:
		anchor_x = 1.0
	var anchor_y: float = 1.0 if center.y > viewport_size.y * 0.5 else 0.0
	control.anchor_left = anchor_x
	control.anchor_right = anchor_x
	control.anchor_top = anchor_y
	control.anchor_bottom = anchor_y
	control.offset_left = rect.position.x - anchor_x * viewport_size.x
	control.offset_top = rect.position.y - anchor_y * viewport_size.y
	control.offset_right = control.offset_left + rect.size.x
	control.offset_bottom = control.offset_top + rect.size.y


func _set_local_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
