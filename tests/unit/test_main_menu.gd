extends "res://tests/test_case.gd"
## The main menu: Continue (the first stage not cleared, "Start" on a new save), the six panel buttons in order and all
## the same shape, the stage line inside Continue clear of its label, the brighter border and glow on hover and focus, and
## the staggered entrance.

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main_menu/main_menu.tscn")
const SAVE_DIR: String = "user://test_main_menu/"
const ORDER: Array[String] = ["Continue", "Stages", "Upgrades", "Settings", "Credits", "Quit"]


func _region() -> RegionData:
	return StageProgression.default_region()


func _menu(cleared: Array[String], last_stage: String = "", battles: int = 0) -> Control:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path: String = SAVE_DIR + "menu_save.json"
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = cleared.duplicate()
	progress.last_stage_id = last_stage
	progress.battles_played = battles
	SaveManager.new(path).save_progress(progress)
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	menu.set("save_path", path)
	menu.set("settings_path", SAVE_DIR + "menu_settings.cfg")
	add_to_tree(menu)
	return menu


func test_continue_starts_the_first_uncleared_stage() -> void:
	var region: RegionData = _region()
	var progress: PlayerProgress = PlayerProgress.new()
	assert_eq(StageProgression.continue_stage(progress, region).stage_id, "stage_1", "a new save starts stage 1")
	progress.stages_cleared = ["stage_1", "stage_2"] as Array[String]
	assert_eq(StageProgression.continue_stage(progress, region).stage_id, "stage_3", "two cleared: stage 3")
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	assert_eq(StageProgression.continue_stage(progress, region).stage_id, "stage_5", "four cleared: the boss stage")


func test_with_every_stage_cleared_continue_replays_the_last_stage_played() -> void:
	var region: RegionData = _region()
	var progress: PlayerProgress = PlayerProgress.new()
	for stage: StageData in region.stages:
		progress.stages_cleared.append(stage.stage_id)
	progress.last_stage_id = "stage_3"
	assert_eq(StageProgression.continue_stage(progress, region).stage_id, "stage_3", "it offers the stage played last")
	progress.last_stage_id = ""
	assert_eq(StageProgression.continue_stage(progress, region).stage_id, "stage_5", "or the last stage when that is not known")
	progress.last_stage_id = "no_such_stage"
	assert_eq(StageProgression.continue_stage(progress, region).stage_id, "stage_5", "and when it names a stage that does not exist")
	assert_true(StageProgression.continue_stage(null, null) == null, "no region, no stage")


func test_a_new_save_is_fresh_and_a_save_that_has_played_is_not() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	assert_true(StageProgression.is_fresh(progress), "nothing played")
	progress.battles_played = 1
	assert_true(not StageProgression.is_fresh(progress), "one lost battle is not fresh")
	progress.battles_played = 0
	progress.last_stage_id = "stage_1"
	assert_true(not StageProgression.is_fresh(progress), "nor a recorded last stage")
	assert_eq(StageProgression.stage_line(_region(), _region().stages[2]), "Stage 3 - Misty Grove", "the line under Continue")


func test_the_last_stage_played_is_saved_with_the_progress() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	var defeat: BattleReward = BattleReward.new()
	progress.record_battle(defeat, "stage_2")
	assert_eq(progress.last_stage_id, "stage_2", "a lost battle still counts as the last stage played")
	progress.record_battle(defeat, "")
	assert_eq(progress.last_stage_id, "stage_2", "a battle with no stage leaves it")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var manager: SaveManager = SaveManager.new(SAVE_DIR + "last_stage_save.json")
	manager.save_progress(progress)
	assert_eq(manager.load_progress().last_stage_id, "stage_2", "it survives a save and a load")
	assert_eq(progress.duplicate_progress().last_stage_id, "stage_2", "and a copy")
	var old: FileAccess = FileAccess.open(SAVE_DIR + "old_save.json", FileAccess.WRITE)
	old.store_string('{"version": 1, "saved_at_unix": 1, "data": {"gold": 5, "xp": 0, "stages_cleared": ["stage_1"]}}')
	old.close()
	var loaded: PlayerProgress = SaveManager.new(SAVE_DIR + "old_save.json").load_progress()
	assert_eq(loaded.gold, 5, "a save from before the field still loads")
	assert_eq(loaded.last_stage_id, "", "with no last stage")


func test_the_menu_has_the_six_buttons_in_order() -> void:
	var menu: Control = _menu([] as Array[String])
	var vbox: Control = menu.get_node("Menu/VBox")
	var found: Array[String] = []
	for child: Node in vbox.get_children():
		if child.name.ends_with("Slot"):
			found.append(String(child.name).trim_suffix("Slot"))
	assert_eq(found, ORDER, "Continue, Stages, Upgrades, Settings, Credits, Quit")
	for slot_name: String in ORDER:
		var button: Button = menu.get_node("%" + slot_name + "Button") as Button
		assert_true(button is InkMenuButton, "%s is a menu panel button" % slot_name)
		assert_true(button.theme_type_variation == &"MenuButtonPanel" or button.theme_type_variation == &"MenuButtonPanelSub", "%s uses the panel theme variation" % slot_name)
		assert_eq(button.size.x, (menu.get_node("%ContinueButton") as Control).size.x, "%s is as wide as the others" % slot_name)
		assert_true(button.custom_minimum_size.y >= TouchLayout.MIN_TOUCH_TARGET and button.custom_minimum_size.x >= TouchLayout.MIN_TOUCH_TARGET, "%s keeps its 44 pt target" % slot_name)
		assert_true(button.focus_mode == Control.FOCUS_ALL, "%s takes keyboard and gamepad focus" % slot_name)
	assert_eq((menu.get_node("%StagesButton") as Button).text, "Stages", "Stages says Stages")
	var rect: Rect2 = Rect2(Vector2.ZERO, menu.get_viewport_rect().size)
	for slot_name: String in ORDER:
		assert_true(rect.encloses((menu.get_node("%" + slot_name + "Slot") as Control).get_global_rect()), "%s fits on the screen" % slot_name)


func test_continue_says_start_on_a_new_save_and_names_the_stage_it_will_play() -> void:
	var fresh: Control = _menu([] as Array[String])
	var button: InkMenuButton = fresh.get_node("%ContinueButton") as InkMenuButton
	assert_eq(button.text, "Start", "a new save says Start")
	assert_eq(button.sub_caption, "Stage 1 - The Village Gate", "and names stage 1")
	assert_eq((fresh.call("get_continue_stage") as StageData).stage_id, "stage_1", "and starts it")
	fresh.free()
	var mid: Control = _menu(["stage_1", "stage_2"] as Array[String], "stage_2", 2)
	var again: InkMenuButton = mid.get_node("%ContinueButton") as InkMenuButton
	assert_eq(again.text, "Continue", "a save in progress says Continue")
	assert_eq(again.sub_caption, "Stage 3 - Misty Grove", "with the next stage under it")
	assert_eq((mid.call("get_continue_stage") as StageData).stage_id, "stage_3", "which is the one it starts")


func test_the_stage_line_sits_inside_continue_clear_of_its_label() -> void:
	var region: RegionData = _region()
	var menu: Control = _menu([] as Array[String])
	var button: InkMenuButton = menu.get_node("%ContinueButton") as InkMenuButton
	var panel: Rect2 = Rect2(Vector2.ZERO, button.size).grow(-float(InkMenuButton.BORDER))
	for stage: StageData in region.stages:
		for word: String in ["Start", "Continue"]:
			button.text = word
			button.sub_caption = StageProgression.stage_line(region, stage)
			var label: Rect2 = button.get_label_rect()
			var line: Rect2 = button.get_sub_caption_rect()
			assert_true(panel.encloses(label), "'%s' is inside the panel" % word)
			assert_true(panel.encloses(line), "'%s' is inside the panel" % button.sub_caption)
			assert_true(label.end.y <= line.position.y, "'%s' does not touch '%s' (%.1f / %.1f)" % [word, button.sub_caption, label.end.y, line.position.y])


func test_hover_or_focus_brightens_the_border_and_fades_in_the_glow() -> void:
	var menu: Control = _menu([] as Array[String])
	var button: InkMenuButton = menu.get_node("%UpgradesButton") as InkMenuButton
	assert_almost_eq(button.get_glow(), 0.0, "idle: no glow")
	button.grab_focus()
	assert_true(button.is_active(), "focusing it (keyboard, gamepad) lights it")
	for i: int in 30:
		button._process(1.0 / 30.0)
	assert_almost_eq(button.get_glow(), 1.0, "the glow has faded all the way in")
	assert_almost_eq(button.scale.x, 1.0, "the panel keeps its size and shape")
	button.release_focus()
	assert_true(not button.is_active(), "losing focus puts it out")
	for i: int in 30:
		button._process(1.0 / 30.0)
	assert_almost_eq(button.get_glow(), 0.0, "the glow is gone")


func test_hover_and_focus_are_silent_and_press_plays_one_soft_click() -> void:
	var entry: SfxEntry = (load("res://data/audio/sfx_library.tres") as SfxLibrary).find(&"button_click")
	assert_true(entry != null and entry.stream != null, "press click has a fallback")
	assert_true(entry.volume_db <= -16.0 and entry.max_length > 0.0 and entry.max_length <= 0.1, "quieter and short")
	for path: String in entry.override_paths:
		assert_true(ResourceLoader.exists(path), "%s exists" % path)
	var audio: AudioManager = AudioManager.instance
	if audio == null:
		return
	var menu: Control = _menu([] as Array[String])
	var button: InkMenuButton = menu.get_node("%StagesButton") as InkMenuButton
	var before: int = audio.play_count
	button.grab_focus()
	assert_eq(audio.play_count, before, "focus in the first moments is silent (the menu grabs it itself)")
	button.release_focus()
	button.grab_focus()
	button.mouse_entered.emit()
	button.mouse_exited.emit()
	assert_eq(audio.play_count, before, "hover and keyboard focus remain silent")
	OS.delay_msec(40)
	button.pressed.emit()
	assert_eq(audio.play_count, before + 1, "one press plays exactly one sound")
	assert_eq(audio.last_played, &"button_click", "press uses the soft click")


func test_the_buttons_come_in_one_after_another() -> void:
	var menu: Control = _menu([] as Array[String])
	var first: Control = menu.get_node("%ContinueSlot")
	assert_almost_eq(first.modulate.a, 0.0, "the first starts invisible")
	assert_true((first.get_child(0) as Control).position.x < 0.0, "and off to the left")
	menu.call("finish_intro")
	for slot_name: String in ORDER:
		var slot: Control = menu.get_node("%" + slot_name + "Slot")
		assert_almost_eq(slot.modulate.a, 1.0, "%s is fully visible once the entrance is done" % slot_name)
		assert_almost_eq((slot.get_child(0) as Control).position.x, 0.0, "%s is in place" % slot_name)
