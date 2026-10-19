extends Control
## Title screen: Start (stage select), Upgrades, Settings, Quit, plus a summary of saved progress.

## Overridable so automated runs never touch the player's real save/settings.
@export var save_path: String = SaveManager.DEFAULT_PATH
@export var settings_path: String = SettingsStore.DEFAULT_PATH

@onready var _start_button: Button = %StartButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _warning_label: Label = %WarningLabel
@onready var _settings_panel: SettingsPanel = %SettingsPanel

var _settings_store: SettingsStore
var _settings: GameSettings


func _ready() -> void:
	_start_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.STAGE_SELECT))
	_upgrades_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.UPGRADE_MENU))
	_settings_button.pressed.connect(_open_settings)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_panel.changed.connect(_on_settings_changed)
	_settings_panel.closed.connect(_on_settings_closed)

	_settings_store = SettingsStore.new(settings_path)
	_settings = _settings_store.load_settings()
	_settings.apply_audio()

	var save_manager: SaveManager = SaveManager.new(save_path)
	var progress: PlayerProgress = save_manager.load_progress()
	_progress_label.text = "Gold %d   -   Level %d" % [progress.gold, progress.get_level()]
	var warnings: PackedStringArray = []
	for warning: String in [save_manager.last_warning, _settings_store.last_warning]:
		if not warning.is_empty():
			warnings.append(warning)
	_warning_label.text = "\n".join(warnings)
	_warning_label.visible = not warnings.is_empty()
	_start_button.grab_focus()


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
