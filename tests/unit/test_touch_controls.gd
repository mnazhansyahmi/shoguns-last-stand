extends "res://tests/test_case.gd"
## Touch layout (mirroring, safe area, target size) and multitouch input on the real scene.

const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const VIEWPORT: Vector2 = Vector2(1920.0, 1080.0)
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"attack", &"heavy_attack",
		&"dash", &"spirit_slash", &"summon_1", &"summon_2"]


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
		for control: Control in controls:
			var minimum: Vector2 = control.get_combined_minimum_size()
			assert_true(minimum.y >= TouchLayout.MIN_TOUCH_TARGET and minimum.x >= TouchLayout.MIN_TOUCH_TARGET,
					"%s: %s is %.0fx%.0f (needs >= %.0f)" % [label, control.name, minimum.x, minimum.y, TouchLayout.MIN_TOUCH_TARGET])


func test_touch_outside_widgets_is_not_consumed() -> void:
	var controls: TouchControls = _make_controls(false)
	assert_true(not controls.handle_input(_touch(0, Vector2(960.0, 300.0), true)), "touch in the play area passes through")
