extends "res://tests/test_case.gd"
const SAVE: String = "user://test_saves/enemy_briefing.json"


func cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	super.cleanup()


func test_briefing_lists_every_type_once_and_remembers_first_encounters() -> void:
	var stage: StageData = load("res://data/stages/stage_10.tres") as StageData
	var progress: PlayerProgress = PlayerProgress.new()
	var briefing: EnemyBriefing = add_to_tree(EnemyBriefing.new()) as EnemyBriefing
	briefing.open(stage, progress)
	assert_eq(briefing.card_count, stage.enemy_types().size(), "one painted card per enemy including boss")
	assert_eq(briefing.new_count, briefing.card_count, "unseen enemies have NEW")
	assert_eq(SaveManager.new(SAVE).save_progress(progress), OK, "discoveries can be saved before battle outcome")
	var loaded: PlayerProgress = SaveManager.new(SAVE).load_progress()
	briefing.open(stage, loaded)
	assert_eq(briefing.new_count, 0, "reopening/retrying does not mark known enemies NEW")
	assert_eq(loaded.duplicate_progress().seen_enemy_ids, loaded.seen_enemy_ids, "save copies retain discoveries")


func test_old_saves_know_completed_stages_and_key_dismissal_consumes_input() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1"] as Array[String]
	var soldier: EnemyData = load("res://data/enemies/hollow_soldier.tres") as EnemyData
	assert_true(not EnemyBriefing.first_encounter(soldier, progress), "completed-stage foes are known without new save field")
	var briefing: EnemyBriefing = add_to_tree(EnemyBriefing.new()) as EnemyBriefing
	briefing.open(load("res://data/stages/stage_1.tres") as StageData, progress)
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	briefing._input(event)
	assert_true(not briefing.visible, "any pressed key dismisses")
	briefing.open(load("res://data/stages/stage_1.tres") as StageData, progress, false)
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	briefing._input(touch)
	assert_true(not briefing.visible, "a tap dismisses")


func test_settings_tabs_are_joined_to_their_titled_content_panel() -> void:
	var panel: SettingsPanel = add_to_tree(load("res://scenes/ui/settings_panel.tscn").instantiate()) as SettingsPanel
	panel.open(GameSettings.new())
	for index: int in 3:
		panel.select_tab(index)
		assert_true(panel._pages[index].get_node("SectionTitle") is Label, "section title is visible above settings")
		var style: StyleBoxFlat = panel._tab_buttons[index].get_theme_stylebox("pressed") as StyleBoxFlat
		assert_eq(style.border_width_bottom, 0, "selected tab joins panel rather than looking like a toggle")


func test_briefing_freezes_the_world_and_pause_review_returns_to_pause() -> void:
	var tree: SceneTree = tree_root.get_tree()
	var field: Node = load("res://scenes/battlefield/battlefield.tscn").instantiate()
	field.set("save_path", SAVE)
	field.set("settings_path", "user://test_saves/briefing_settings.cfg")
	field.set("enemy_briefing_enabled", false)
	add_to_tree(field)
	field.call("_open_enemy_briefing", false)
	assert_true(tree.paused, "opening intelligence stops combat before wave 1")
	var briefing: EnemyBriefing = field.get("_enemy_briefing") as EnemyBriefing
	for i: int in 3: await tree.process_frame
	assert_eq((field.get_node("World/EnemySpawner") as EnemySpawner).get_alive_count(), 0, "no enemies spawn while reading")
	briefing.dismiss()
	for i: int in 3: await tree.process_frame
	assert_true(not tree.paused, "first briefing resumes after consuming dismissal frame")
	field.call("_pause")
	field.call("_open_enemy_briefing", true)
	briefing.dismiss()
	assert_true(tree.paused and (field.get_node("PauseMenu") as PauseMenu).is_open(), "review returns to Pause instead of resuming combat")
	tree.paused = false
