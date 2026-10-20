extends Control
## The Credits screen (main menu -> Credits): everything in docs/CREDITS.md, scrollable, with a Back button.
## Escape (the pause key) goes back too.

@onready var _text: RichTextLabel = %Text
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	AudioManager.play_music(&"menu")
	_text.bbcode_enabled = true
	_text.text = CreditsText.to_bbcode(CreditsText.load_markdown())
	_text.meta_clicked.connect(_on_link_clicked)
	_back_button.pressed.connect(_go_back)
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)


func _on_link_clicked(meta: Variant) -> void:
	if CreditsText.is_openable(meta):
		OS.shell_open(str(meta))
