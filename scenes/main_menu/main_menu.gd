extends Control
## Title screen: Continue (the first stage not cleared yet, "Start" on a new save), Stages (the stage select), Upgrades,
## Settings, Credits and Quit, as brush-stroke buttons that slide and fade in one after another when the menu opens,
## plus a summary of saved progress.

## Seconds between one button starting its entrance and the next, and how far each slides in from the left.
const INTRO_STEP: float = 0.07
const INTRO_FADE: float = 0.3
const INTRO_SLIDE_TIME: float = 0.38
const INTRO_SLIDE: float = 70.0

## Overridable so automated runs never touch the player's real save/settings.
@export var save_path: String = SaveManager.DEFAULT_PATH
@export var settings_path: String = SettingsStore.DEFAULT_PATH

@onready var _continue_button: InkMenuButton = %ContinueButton
@onready var _stages_button: Button = %StagesButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _settings_button: Button = %SettingsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _warning_label: Label = %WarningLabel
@onready var _settings_panel: SettingsPanel = %SettingsPanel

var _settings_store: SettingsStore
var _settings: GameSettings
var _region: RegionData
## The stage Continue starts.
var _continue_stage: StageData
var _intro: Array[Tween] = []


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_stages_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.STAGE_SELECT))
	_upgrades_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.UPGRADE_MENU))
	_settings_button.pressed.connect(_open_settings)
	_credits_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.CREDITS))
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_panel.save_path = save_path
	_settings_panel.progress_reset.connect(_on_progress_reset)
	_settings_panel.changed.connect(_on_settings_changed)
	_settings_panel.closed.connect(_on_settings_closed)

	_settings_store = SettingsStore.new(settings_path)
	_settings = _settings_store.load_settings()
	_settings.apply_audio()
	AudioManager.play_music(&"menu")

	var save_manager: SaveManager = SaveManager.new(save_path)
	var progress: PlayerProgress = save_manager.load_progress()
	_region = StageProgression.default_region()
	_show_progress(progress)
	var warnings: PackedStringArray = []
	for warning: String in [save_manager.last_warning, _settings_store.last_warning]:
		if not warning.is_empty():
			warnings.append(warning)
	_warning_label.text = "\n".join(warnings)
	_warning_label.visible = not warnings.is_empty()
	_continue_button.grab_focus()
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _settings_panel.is_open():
		get_viewport().set_input_as_handled()
		_settings_panel.close()


func _open_settings() -> void:
	_settings_panel.open(_settings)


func _on_settings_changed(settings: GameSettings) -> void:
	settings.apply_audio()


func _on_settings_closed(settings: GameSettings) -> void:
	_settings = settings
	var error: Error = _settings_store.save_settings(settings)
	if error != OK:
		_warning_label.text = "Could not save settings (error %d)." % error
		_warning_label.visible = true
	_settings_button.grab_focus()


func _on_quit_pressed() -> void:
	await AudioManager.shutdown_audio(get_tree())
	get_tree().quit()


func _on_progress_reset() -> void:
	_show_progress(SaveManager.new(save_path).load_progress())


## The gold and level line, and what Continue says and starts.
func _show_progress(progress: PlayerProgress) -> void:
	_progress_label.text = "Gold %d   -   Level %d" % [progress.gold, progress.get_level()]
	_continue_stage = StageProgression.continue_stage(progress, _region)
	_continue_button.text = "Start" if StageProgression.is_fresh(progress) else "Continue"
	_continue_button.sub_caption = StageProgression.stage_line(_region, _continue_stage)


func get_continue_stage() -> StageData:
	return _continue_stage


func _on_continue_pressed() -> void:
	if _continue_stage != null:
		SceneRoutes.go_to_battle(get_tree(), _continue_stage)
	else:
		SceneRoutes.go_to(get_tree(), SceneRoutes.STAGE_SELECT)


## The six buttons come in one after another: each fades up while it slides in from the left.
func _play_intro() -> void:
	var step: int = 0
	for slot_name: String in ["Continue", "Stages", "Upgrades", "Settings", "Credits", "Quit"]:
		var slot: Control = get_node("%" + slot_name + "Slot")
		var button: Control = slot.get_child(0)
		slot.modulate.a = 0.0
		button.position.x = -INTRO_SLIDE
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(slot, "modulate:a", 1.0, INTRO_FADE).set_delay(INTRO_STEP * step)
		tween.tween_property(button, "position:x", 0.0, INTRO_SLIDE_TIME).set_delay(INTRO_STEP * step) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_intro.append(tween)
		step += 1


## Finishes the entrance at once (a test, or a player who is quick).
func finish_intro() -> void:
	for tween: Tween in _intro:
		tween.kill()
	_intro.clear()
	for slot_name: String in ["Continue", "Stages", "Upgrades", "Settings", "Credits", "Quit"]:
		var slot: Control = get_node("%" + slot_name + "Slot")
		slot.modulate.a = 1.0
		slot.get_child(0).position.x = 0.0
