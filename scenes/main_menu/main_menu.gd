extends Control
## Title screen. Start loads the battlefield; Quit exits the game.

const BATTLEFIELD_SCENE: String = "res://scenes/battlefield/battlefield.tscn"

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	var error: Error = get_tree().change_scene_to_file(BATTLEFIELD_SCENE)
	if error != OK:
		push_error("MainMenu: failed to load '%s' (error %d)" % [BATTLEFIELD_SCENE, error])


func _on_quit_pressed() -> void:
	get_tree().quit()
