class_name PauseMenu
extends CanvasLayer
## Pause overlay: Resume, Restart, Settings, Main Menu. Runs while the tree is paused.
## The owner pauses/unpauses the tree; this scene only reports what the player chose.

signal resume_requested
signal restart_requested
signal main_menu_requested
signal settings_changed(settings: GameSettings)
signal settings_closed(settings: GameSettings)

@onready var _menu: Control = %Menu
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _settings_panel: SettingsPanel = %SettingsPanel

var _settings: GameSettings


func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(resume_requested.emit)
	_restart_button.pressed.connect(restart_requested.emit)
	_main_menu_button.pressed.connect(main_menu_requested.emit)
	_settings_button.pressed.connect(_open_settings)
	_settings_panel.changed.connect(settings_changed.emit)
	_settings_panel.closed.connect(_on_settings_closed)


func open(settings: GameSettings) -> void:
	_settings = settings
	visible = true
	_menu.visible = true
	_resume_button.grab_focus()


func close() -> void:
	if _settings_panel.is_open():
		_settings_panel.close()
	visible = false


func is_open() -> bool:
	return visible


func is_settings_open() -> bool:
	return _settings_panel.is_open()


func close_settings() -> void:
	_settings_panel.close()


func _open_settings() -> void:
	_menu.visible = false
	_settings_panel.open(_settings)


func _on_settings_closed(settings: GameSettings) -> void:
	_menu.visible = visible
	if visible:
		_settings_button.grab_focus()
	settings_closed.emit(settings)
