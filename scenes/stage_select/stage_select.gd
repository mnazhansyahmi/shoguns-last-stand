extends Control
## Stage select for a region. Stages unlock in order (StageProgression); locked stages are
## listed but disabled. Unlock state comes from the save's cleared stages.

const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const CLEARED_COLOR: Color = InkPalette.JADE
const NEW_COLOR: Color = InkPalette.GOLD_BRIGHT
const LOCKED_COLOR: Color = InkPalette.UI_DISABLED

## Overridable so automated runs never touch the player's real save.
@export var save_path: String = SaveManager.DEFAULT_PATH
@export var region: RegionData

@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _stage_list: VBoxContainer = %StageList
@onready var _back_button: Button = %BackButton

var _progress: PlayerProgress
## Stage button per stage index, for tests and focus.
var _buttons: Array[Button] = []


func _ready() -> void:
	if region == null:
		region = StageProgression.default_region()
	AudioManager.play_music(&"stage_select")
	var save_manager: SaveManager = SaveManager.new(save_path)
	_progress = save_manager.load_progress()
	_title_label.text = region.display_name if region != null else "Stages"
	_progress_label.text = "Gold %d   -   Level %d   -   %d / %d stages unlocked" % [
		_progress.gold, _progress.get_level(), StageProgression.unlocked_count(_progress, region),
		region.stages.size() if region != null else 0]
	_back_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	_build_rows()
	var focus: Button = _back_button
	for button: Button in _buttons:
		if not button.disabled:
			focus = button
	focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)


func get_stage_button(index: int) -> Button:
	return _buttons[index] if index >= 0 and index < _buttons.size() else null


func _build_rows() -> void:
	if region == null:
		push_error("StageSelect: no region assigned.")
		return
	for i: int in region.stages.size():
		var stage: StageData = region.stages[i]
		if stage == null:
			push_error("StageSelect: region has an empty stage slot at %d." % i)
			continue
		var unlocked: bool = StageProgression.is_unlocked(_progress, region, i)
		var cleared: bool = _progress.is_stage_cleared(stage.stage_id)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)

		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(620.0, 124.0)
		button.add_theme_font_size_override("font_size", 34)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var status: String = "LOCKED"
		var color: Color = LOCKED_COLOR
		if unlocked:
			status = "CLEARED" if cleared else "NEW"
			color = CLEARED_COLOR if cleared else NEW_COLOR
		button.text = "  %d.  %s   [%s]" % [i + 1, stage.display_name, status]
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_disabled_color", LOCKED_COLOR)
		button.disabled = not unlocked
		button.pressed.connect(SceneRoutes.go_to_battle.bind(get_tree(), stage))
		row.add_child(button)

		var info: Label = Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 26)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if unlocked:
			var first_gold: int = stage.get_full_clear_gold()
			var replay_gold: int = floori(first_gold * stage.replay_gold_multiplier)
			var oni: int = stage.count_enemy(ONI_BRUTE)
			info.text = "%s\n%d waves, %d soldiers, %d Oni Brute%s  -  first clear %d gold, replay %d gold%s" % [
				stage.description, stage.waves.size(), stage.count_enemy(HOLLOW_SOLDIER), oni, "" if oni == 1 else "s",
				first_gold, replay_gold, "  (cleared: replay pays 50%)" if cleared else ""]
		else:
			info.text = "Clear \"%s\" first." % region.stages[i - 1].display_name
			info.add_theme_color_override("font_color", LOCKED_COLOR)
		row.add_child(info)
		_stage_list.add_child(row)
		_buttons.append(button)
