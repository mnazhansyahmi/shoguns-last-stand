extends Control
## Title screen: Start, Upgrades, Quit, plus a summary of saved progress.

## Overridable so automated runs never touch the player's real save.
@export var save_path: String = SaveManager.DEFAULT_PATH

@onready var _start_button: Button = %StartButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _quit_button: Button = %QuitButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _warning_label: Label = %WarningLabel


func _ready() -> void:
	_start_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.BATTLEFIELD))
	_upgrades_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.UPGRADE_MENU))
	_quit_button.pressed.connect(_on_quit_pressed)

	var save_manager: SaveManager = SaveManager.new(save_path)
	var progress: PlayerProgress = save_manager.load_progress()
	_progress_label.text = "Gold %d   -   Level %d" % [progress.gold, progress.get_level()]
	_warning_label.text = save_manager.last_warning
	_warning_label.visible = not save_manager.last_warning.is_empty()
	_start_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
