extends "res://tests/test_case.gd"
## Touch layout (mirroring, safe area, target size) and multitouch input on the real scene.

const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const VIEWPORT: Vector2 = Vector2(1920.0, 1080.0)
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"attack", &"heavy_attack",
		&"dash", &"spirit_slash", &"ultimate", &"summon_1", &"summon_2", &"summon_3", &"summon_4", &"summon_5", &"summon_6"]
## Viewports: 16:9, the iPhone 16 landscape shape (2556 x 1179 -> 2341 x 1080 canvas) and a narrow one.
const VIEWPORTS: Array[Vector2] = [Vector2(1920.0, 1080.0), Vector2(2341.0, 1080.0), Vector2(1664.0, 1080.0)]


func cleanup() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)
	super.cleanup()


func _full() -> Rect2:
	return Rect2(Vector2.ZERO, VIEWPORT)


func test_left_handed_layout_mirrors_clusters() -> void:
	var right: Dictionary = TouchLayout.compute(VIEWPORT, _full(), 1.0, false)
	var left: Dictionary = TouchLayout.compute(VIEWPORT, _full(), 1.0, true)
	var right_joystick: Rect2 = right["joystick"]
	var left_joystick: Rect2 = left["joystick"]
	var right_actions: Rect2 = right["actions"]
	var left_actions: Rect2 = left["actions"]
	assert_true(right_joystick.get_center().x < VIEWPORT.x * 0.5, "right-handed: joystick on the left")
	assert_true(left_joystick.get_center().x > VIEWPORT.x * 0.5, "left-handed: joystick on the right")
	assert_almost_eq(right_joystick.get_center().x + left_joystick.get_center().x, VIEWPORT.x, "joystick mirrored")
	assert_almost_eq(right_actions.get_center().x + left_actions.get_center().x, VIEWPORT.x, "actions mirrored")
	assert_almost_eq(right_joystick.position.y, left_joystick.position.y, "same height")
	var right_summons: Rect2 = right["summons"]
	var left_summons: Rect2 = left["summons"]
	assert_eq(right_summons, left_summons, "summons stay centered")


func test_action_buttons_mirror_inside_cluster() -> void:
	var right: Dictionary = TouchLayout.action_button_rects(1.0, false)
	var left: Dictionary = TouchLayout.action_button_rects(1.0, true)
	var width: float = TouchLayout.ACTION_CLUSTER_SIZE.x
	for key: String in right:
		var r: Rect2 = right[key]
		var l: Rect2 = left[key]
		assert_almost_eq(r.get_center().x + l.get_center().x, width, "%s mirrored" % key)
		assert_almost_eq(r.position.y, l.position.y, "%s same height" % key)
	var attack_right: Rect2 = right["attack"]
	var attack_left: Rect2 = left["attack"]
	assert_true(attack_right.get_center().x > width * 0.5, "right-handed: Attack toward the outer edge")
	assert_true(attack_left.get_center().x < width * 0.5, "left-handed: Attack toward the outer edge")


func test_layout_respects_safe_area() -> void:
	var safe: Rect2 = Rect2(Vector2(132.0, 0.0), Vector2(VIEWPORT.x - 264.0, VIEWPORT.y - 60.0))
	for left_handed: bool in [false, true]:
		var rects: Dictionary = TouchLayout.compute(VIEWPORT, safe, 1.4, left_handed)
		for key: String in rects:
			var rect: Rect2 = rects[key]
			assert_true(safe.encloses(rect), "%s inside safe area (left_handed=%s)" % [key, left_handed])


func test_clusters_never_overlap() -> void:
	for scale_value: float in [GameSettings.MIN_UI_SCALE, 1.0, GameSettings.MAX_UI_SCALE]:
		var rects: Dictionary = TouchLayout.compute(Vector2(1664.0, 1080.0), Rect2(Vector2.ZERO, Vector2(1664.0, 1080.0)), scale_value, false)
		var joystick: Rect2 = rects["joystick"]
		var actions: Rect2 = rects["actions"]
		var summons: Rect2 = rects["summons"]
		assert_true(not summons.intersects(joystick) and not summons.intersects(actions),
				"summons clear of side clusters at scale %.2f" % scale_value)


func test_touch_targets_meet_44pt_minimum() -> void:
	assert_true(TouchLayout.smallest_touch_target(GameSettings.MIN_UI_SCALE) >= TouchLayout.MIN_TOUCH_TARGET,
			"smallest button at minimum UI scale is >= 44 pt on iPhone 16 (%.0f units)" % TouchLayout.smallest_touch_target(GameSettings.MIN_UI_SCALE))


func _make_controls(left_handed: bool) -> TouchControls:
	var controls: TouchControls = add_to_tree(TOUCH_SCENE.instantiate()) as TouchControls
	var viewport_size: Vector2 = controls.get_viewport().get_visible_rect().size
	controls.apply_layout(viewport_size, Rect2(Vector2.ZERO, viewport_size), 1.0, left_handed)
	controls.set_active(true)
	return controls


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func test_scene_layout_mirrors_widgets() -> void:
	var right: TouchControls = _make_controls(false)
	var viewport_width: float = right.get_viewport().get_visible_rect().size.x
	var right_joystick: Rect2 = right.get_widget_rect("joystick")
	var right_attack: Rect2 = right.get_widget_rect("attack")
	right.apply_layout(right.get_viewport().get_visible_rect().size,
			right.get_viewport().get_visible_rect(), 1.0, true)
	var left_joystick: Rect2 = right.get_widget_rect("joystick")
	var left_attack: Rect2 = right.get_widget_rect("attack")
	assert_almost_eq(right_joystick.get_center().x + left_joystick.get_center().x, viewport_width, "joystick node mirrored", 0.5)
	assert_almost_eq(right_attack.get_center().x + left_attack.get_center().x, viewport_width, "attack node mirrored", 0.5)
	assert_true(right.is_left_handed(), "left-handed flag stored")


func test_move_and_attack_at_the_same_time() -> void:
	var controls: TouchControls = _make_controls(false)
	var joystick: Rect2 = controls.get_widget_rect("joystick")
	var attack: Rect2 = controls.get_widget_rect("attack")
	assert_true(controls.handle_input(_touch(0, joystick.get_center(), true)), "joystick takes finger 0")
	assert_true(controls.handle_input(_drag(0, joystick.get_center() + Vector2(joystick.size.x * 0.45, 0.0))),
			"joystick follows finger 0")
	assert_true(controls.handle_input(_touch(1, attack.get_center(), true)), "attack takes finger 1")
	assert_true(Input.is_action_pressed(&"move_right"), "moving right")
	assert_true(Input.get_action_strength(&"move_right") > 0.5, "analog strength from the stick")
	assert_true(not Input.is_action_pressed(&"move_left"), "not moving left")
	assert_true(Input.is_action_pressed(&"attack"), "attack held while moving")

	controls.handle_input(_touch(1, attack.get_center(), false))
	assert_true(Input.is_action_pressed(&"move_right"), "lifting finger 1 keeps moving")
	controls.handle_input(_touch(0, joystick.get_center(), false))
	assert_true(not Input.is_action_pressed(&"move_right"), "lifting finger 0 stops moving")


func test_dead_zone_ignores_small_offsets() -> void:
	var controls: TouchControls = _make_controls(false)
	var joystick: Rect2 = controls.get_widget_rect("joystick")
	controls.handle_input(_touch(0, joystick.get_center() + Vector2(joystick.size.x * 0.05, 0.0), true))
	assert_true(not Input.is_action_pressed(&"move_right") and not Input.is_action_pressed(&"move_left"),
			"tiny offset inside the dead zone does not move")


func test_summon_button_presses_summon_action() -> void:
	var controls: TouchControls = _make_controls(false)
	var summon: Rect2 = controls.get_widget_rect("summon_2")
	controls.handle_input(_touch(3, summon.get_center(), true))
	assert_true(Input.is_action_pressed(&"summon_2"), "summon button presses the Input Map action")


func test_deactivating_releases_held_actions() -> void:
	var controls: TouchControls = _make_controls(false)
	var joystick: Rect2 = controls.get_widget_rect("joystick")
	var dash: Rect2 = controls.get_widget_rect("dash")
	controls.handle_input(_touch(0, joystick.get_center() - Vector2(joystick.size.x * 0.45, 0.0), true))
	controls.handle_input(_touch(1, dash.get_center(), true))
	assert_true(Input.is_action_pressed(&"move_left") and Input.is_action_pressed(&"dash"), "both held")
	controls.set_active(false)
	assert_true(not Input.is_action_pressed(&"move_left") and not Input.is_action_pressed(&"dash"),
			"hiding the controls (e.g. pausing) releases everything")
	assert_true(not controls.handle_input(_touch(2, joystick.get_center(), true)), "inactive controls ignore touches")


## Every button and slider in every menu must be at least ~44 pt on iPhone 16 (121 units).
func test_menu_controls_meet_44pt_minimum() -> void:
	var scenes: Dictionary = {
		"main menu": "res://scenes/main_menu/main_menu.tscn",
		"upgrade menu": "res://scenes/upgrade_menu/upgrade_menu.tscn",
		"pause menu": "res://scenes/ui/pause_menu.tscn",
		"settings panel": "res://scenes/ui/settings_panel.tscn",
		"result screen": "res://scenes/ui/result_screen.tscn",
		"hud": "res://scenes/ui/game_hud.tscn",
		"stage select": "res://scenes/stage_select/stage_select.tscn",
	}
	for label: String in scenes:
		var node: Node = (load(scenes[label]) as PackedScene).instantiate()
		if "save_path" in node:
			node.set("save_path", "user://test_saves/touch_target_save.json")
		if "settings_path" in node:
			node.set("settings_path", "user://test_saves/touch_target_settings.cfg")
		add_to_tree(node)
		var controls: Array[Node] = node.find_children("*", "BaseButton", true, false)
		controls.append_array(node.find_children("*", "Slider", true, false))
		assert_true(not controls.is_empty(), "%s has controls to check" % label)
		# Switch/checkbox art is tiny even when the row is tall; menus must use full toggle buttons.
		for small: Node in node.find_children("*", "CheckButton", true, false) + node.find_children("*", "CheckBox", true, false):
			assert_true(false, "%s: %s is a small switch/checkbox; use a toggle Button" % [label, small.name])
		for control: Control in controls:
			var minimum: Vector2 = control.get_combined_minimum_size()
			assert_true(minimum.y >= TouchLayout.MIN_TOUCH_TARGET and minimum.x >= TouchLayout.MIN_TOUCH_TARGET,
					"%s: %s is %.0fx%.0f (needs >= %.0f)" % [label, control.name, minimum.x, minimum.y, TouchLayout.MIN_TOUCH_TARGET])


func test_settings_toggles_are_full_size_buttons() -> void:
	var panel: SettingsPanel = add_to_tree(load("res://scenes/ui/settings_panel.tscn").instantiate()) as SettingsPanel
	var settings: GameSettings = GameSettings.new()
	settings.vibration = true
	settings.screen_shake = false
	settings.left_handed = true
	panel.open(settings)
	var expected: Dictionary = {
		"VibrationToggle": "Vibration: On",
		"ShakeToggle": "Shake: Off",
		"LeftHandedToggle": "Left-handed: On",
	}
	for toggle_name: String in expected:
		var toggle: Button = panel.get_node("%" + toggle_name) as Button
		assert_true(toggle != null and not (toggle is CheckButton) and not (toggle is CheckBox),
				"%s is a plain toggle Button" % toggle_name)
		if toggle == null:
			continue
		assert_true(toggle.toggle_mode, "%s toggles" % toggle_name)
		var minimum: Vector2 = toggle.get_combined_minimum_size()
		assert_true(minimum.y >= 124.0 and minimum.x >= TouchLayout.MIN_TOUCH_TARGET,
				"%s is at least 124 units tall (%.0fx%.0f)" % [toggle_name, minimum.x, minimum.y])
		assert_eq(toggle.text, expected[toggle_name], "%s spells out its state" % toggle_name)
	var shake: Button = panel.get_node("%ShakeToggle") as Button
	shake.button_pressed = true
	assert_true(settings.screen_shake, "pressing the toggle updates the setting")
	assert_eq(shake.text, "Shake: On", "label follows the toggle")


func test_touch_widgets_are_semi_transparent_until_pressed() -> void:
	var controls: TouchControls = _make_controls(false)
	var attack_button: TouchActionButton = controls.get_node("Root/ActionCluster/AttackButton")
	var joystick: TouchJoystick = controls.get_node("Root/Joystick")
	assert_almost_eq(attack_button.modulate.a, TouchLayout.IDLE_OPACITY, "button at rest is 60% opaque")
	assert_almost_eq(joystick.modulate.a, TouchLayout.IDLE_OPACITY, "joystick at rest is 60% opaque")
	var attack: Rect2 = controls.get_widget_rect("attack")
	var stick: Rect2 = controls.get_widget_rect("joystick")
	controls.handle_input(_touch(1, attack.get_center(), true))
	controls.handle_input(_touch(0, stick.get_center(), true))
	assert_almost_eq(attack_button.modulate.a, 1.0, "pressed button is fully opaque")
	assert_almost_eq(joystick.modulate.a, 1.0, "held joystick is fully opaque")
	controls.release_all()
	assert_almost_eq(attack_button.modulate.a, TouchLayout.IDLE_OPACITY, "released button back to 60%")
	assert_almost_eq(joystick.modulate.a, TouchLayout.IDLE_OPACITY, "released joystick back to 60%")


func test_ground_lift_keeps_units_above_controls() -> void:
	for scale_value: float in [GameSettings.MIN_UI_SCALE, 1.0, GameSettings.MAX_UI_SCALE]:
		var rects: Dictionary = TouchLayout.compute(VIEWPORT, _full(), scale_value, false)
		var joystick: Rect2 = rects["joystick"]
		var actions: Rect2 = rects["actions"]
		var clusters_top: float = minf(joystick.position.y, actions.position.y)
		var lift: float = TouchLayout.ground_lift(rects, 880.0)
		assert_true(lift > 0.0, "ground at y=880 needs lifting at scale %.2f" % scale_value)
		assert_almost_eq(880.0 - lift, clusters_top - TouchLayout.GROUND_CLEARANCE,
				"ground ends just above the controls at scale %.2f" % scale_value)
	var rects_default: Dictionary = TouchLayout.compute(VIEWPORT, _full(), 1.0, false)
	assert_almost_eq(TouchLayout.ground_lift(rects_default, 400.0), 0.0, "no lift when the ground is already clear")


func test_auto_mode_ignores_mouse_emulation() -> void:
	var previous: bool = GameSettings.real_touch_detected
	GameSettings.real_touch_detected = false
	assert_true(Input.emulate_touch_from_mouse, "project emulates touch from mouse (the original trigger)")
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		assert_true(not GameSettings.detect_touchscreen(), "desktop is not a touchscreen just because of mouse emulation")
	var emulated: InputEventScreenTouch = _touch(0, Vector2.ZERO, true)
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	var real: InputEventScreenTouch = _touch(0, Vector2.ZERO, true)
	real.device = 0
	assert_true(not GameSettings.is_real_touch(emulated), "mouse-emulated touch is not a real touch")
	assert_true(GameSettings.is_real_touch(real), "finger touch is a real touch")
	GameSettings.real_touch_detected = true
	assert_true(GameSettings.detect_touchscreen(), "after a real touch, AUTO treats the device as a touchscreen")
	GameSettings.real_touch_detected = previous


func test_freeing_controls_releases_held_actions() -> void:
	var controls: TouchControls = _make_controls(false)
	var stick: Rect2 = controls.get_widget_rect("joystick")
	controls.handle_input(_touch(0, stick.get_center() + Vector2(stick.size.x * 0.45, 0.0), true))
	controls.handle_input(_touch(1, controls.get_widget_rect("attack").get_center(), true))
	assert_true(Input.is_action_pressed(&"move_right") and Input.is_action_pressed(&"attack"), "held before the scene changes")
	controls.free()
	assert_true(not Input.is_action_pressed(&"move_right") and not Input.is_action_pressed(&"attack"),
			"freeing the controls (scene change) does not leave actions stuck")


func test_touch_outside_widgets_is_not_consumed() -> void:
	var controls: TouchControls = _make_controls(false)
	assert_true(not controls.handle_input(_touch(0, Vector2(960.0, 300.0), true)), "touch in the play area passes through")


# --- Summon bar for up to six allies -------------------------------------------

func _bar_buttons(viewport_size: Vector2, ui_scale: float, left_handed: bool, count: int) -> Dictionary:
	var rects: Dictionary = TouchLayout.compute(viewport_size, Rect2(Vector2.ZERO, viewport_size), ui_scale, left_handed, count)
	var bar: Rect2 = rects["summons"]
	var local: Array[Rect2] = TouchLayout.summon_button_rects(count, bar.size, ui_scale)
	var global: Array[Rect2] = []
	for rect: Rect2 in local:
		global.append(Rect2(bar.position + rect.position, rect.size))
	return {"rects": rects, "buttons": global}


func test_summon_bar_fits_one_to_six_allies_everywhere() -> void:
	for viewport_size: Vector2 in VIEWPORTS:
		for ui_scale: float in [GameSettings.MIN_UI_SCALE, 1.0, GameSettings.MAX_UI_SCALE]:
			for left_handed: bool in [false, true]:
				for count: int in range(1, 7):
					var label: String = "%d allies, %dx%d, scale %.1f, left_handed=%s" % [count, viewport_size.x, viewport_size.y, ui_scale, left_handed]
					var layout: Dictionary = _bar_buttons(viewport_size, ui_scale, left_handed, count)
					var rects: Dictionary = layout["rects"]
					var buttons: Array = layout["buttons"]
					var full: Rect2 = Rect2(Vector2.ZERO, viewport_size)
					assert_eq(buttons.size(), count, "one button per ally (%s)" % label)
					for i: int in buttons.size():
						var button: Rect2 = buttons[i]
						assert_true(button.size.x >= TouchLayout.MIN_TOUCH_TARGET, "button %d is at least 44 pt (%s)" % [i + 1, label])
						assert_true(full.encloses(button), "button %d is on screen (%s)" % [i + 1, label])
						assert_true(not button.intersects(rects["joystick"]) and not button.intersects(rects["actions"]),
								"button %d clear of the joystick and action buttons (%s)" % [i + 1, label])
						for j: int in range(i + 1, buttons.size()):
							assert_true(not button.intersects(buttons[j]), "buttons %d and %d do not overlap (%s)" % [i + 1, j + 1, label])


func test_six_allies_fit_in_one_row_on_a_phone_and_two_rows_when_narrow() -> void:
	var phone: Dictionary = TouchLayout.compute(Vector2(2341.0, 1080.0), Rect2(Vector2.ZERO, Vector2(2341.0, 1080.0)), 1.0, false, 6)
	var phone_bar: Rect2 = phone["summons"]
	assert_true(phone_bar.size.y <= TouchLayout.SUMMON_MAX_SIZE + 0.5, "on a phone-shaped screen six buttons are one row")
	assert_almost_eq(phone_bar.get_center().x, 2341.0 * 0.5, "centered on the screen", 0.6)
	var narrow: Dictionary = TouchLayout.compute(Vector2(1664.0, 1080.0), Rect2(Vector2.ZERO, Vector2(1664.0, 1080.0)), 1.4, false, 6)
	var narrow_bar: Rect2 = narrow["summons"]
	var narrow_buttons: Array[Rect2] = TouchLayout.summon_button_rects(6, narrow_bar.size, 1.4)
	var tops: Dictionary = {}
	for rect: Rect2 in narrow_buttons:
		tops[snappedf(rect.position.y, 0.01)] = true
	assert_eq(tops.size(), 2, "with large UI on a narrow screen they wrap to two rows")
	var few: Dictionary = TouchLayout.compute(Vector2(1920.0, 1080.0), Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)), 1.0, false, 2)
	var few_bar: Rect2 = few["summons"]
	assert_true(few_bar.size.x < phone_bar.size.x, "two allies need a narrower bar than six")


func test_only_unlocked_summon_buttons_are_shown_and_touchable() -> void:
	var controls: TouchControls = _make_controls(false)
	controls.set_summon_count(4)
	for slot: int in range(1, 7):
		var button: TouchActionButton = controls.find_child("Summon%dButton" % slot, true, false) as TouchActionButton
		assert_eq(button.visible, slot <= 4, "button %d is shown only when that ally is unlocked" % slot)
	var third: Rect2 = controls.get_widget_rect("summon_3")
	assert_true(controls.handle_input(_touch(5, third.get_center(), true)), "an unlocked button takes the touch")
	assert_true(Input.is_action_pressed(&"summon_3"), "and presses summon_3")
	controls.handle_input(_touch(5, third.get_center(), false))
	var hidden_button: TouchActionButton = controls.find_child("Summon6Button", true, false) as TouchActionButton
	hidden_button.position = Vector2(-1500.0, -700.0)
	var hidden: Rect2 = controls.get_widget_rect("summon_6")
	assert_true(not controls.handle_input(_touch(6, hidden.get_center(), true)), "a hidden button ignores touches")
	controls.set_summon_count(6)
	var sixth: TouchActionButton = controls.find_child("Summon6Button", true, false) as TouchActionButton
	assert_true(sixth.visible and sixth.size.x >= TouchLayout.MIN_TOUCH_TARGET, "unlocking the sixth ally shows its button at a usable size")
	var bar_top: float = INF
	for slot: int in range(1, 7):
		bar_top = minf(bar_top, controls.get_widget_rect("summon_%d" % slot).position.y)
	assert_true(controls.get_widget_rect("summon_6").end.y <= controls.get_viewport().get_visible_rect().size.y, "all six are on screen")


func test_summon_buttons_wear_their_ally_accent() -> void:
	var controls: TouchControls = _make_controls(false)
	controls.set_summon_count(6)
	controls.set_summon_state(2, "Healer", 65, 0.0, 0.0, true, FigureKinds.spec(InkFigure.Kind.SHRINE_HEALER).accent)
	var button: TouchActionButton = controls.find_child("Summon3Button", true, false) as TouchActionButton
	assert_eq(button.base_color, InkPalette.HEALER_JADE, "the Healer's button is jade")
	assert_eq(button.sub_caption, "65 SE", "it shows the cost")
