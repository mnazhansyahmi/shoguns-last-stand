class_name SettingsPanel
extends Control
## Settings overlay used by the main menu and the pause menu. Edits a GameSettings object live
## (emits `changed`) and emits `closed` when dismissed; the owner saves and applies it.
## Every control is at least 124 units tall (44 pt on iPhone 16): full-size toggle buttons,
## no dropdowns or small switches.

signal changed(settings: GameSettings)
signal closed(settings: GameSettings)
signal progress_reset

@export var save_path: String = SaveManager.DEFAULT_PATH

const TOUCH_MODE_NAMES: PackedStringArray = ["Auto", "Always", "Off"]

@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_value: Label = %SfxValue
@onready var _ui_scale_slider: HSlider = %UiScaleSlider
@onready var _ui_scale_value: Label = %UiScaleValue
@onready var _vibration_toggle: Button = %VibrationToggle
@onready var _shake_toggle: Button = %ShakeToggle
@onready var _blood_toggle: Button = %BloodToggle
@onready var _left_handed_toggle: Button = %LeftHandedToggle
@onready var _touch_buttons: Array[Button] = [%TouchAutoButton, %TouchAlwaysButton, %TouchOffButton]
@onready var _reset_button: Button = %ResetButton
@onready var _reset_dialog: ConfirmationDialog = %ResetDialog

@onready var _back_button: Button = %BackButton

var _settings: GameSettings = GameSettings.new()
var _syncing: bool = false


func _ready() -> void:
	visible = false
	_ui_scale_slider.min_value = GameSettings.MIN_UI_SCALE
	_ui_scale_slider.max_value = GameSettings.MAX_UI_SCALE
	var group: ButtonGroup = ButtonGroup.new()
	for i: int in _touch_buttons.size():
		var button: Button = _touch_buttons[i]
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_on_touch_mode_selected.bind(i))
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	_vibration_toggle.toggled.connect(_on_vibration_toggled)
	_shake_toggle.toggled.connect(_on_shake_toggled)
	_blood_toggle.toggled.connect(_on_blood_toggled)
	_left_handed_toggle.toggled.connect(_on_left_handed_toggled)
	_back_button.pressed.connect(close)
	_reset_button.pressed.connect(_reset_dialog.popup_centered)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)
	_reset_dialog.get_label().add_theme_font_size_override("font_size", 32)
	for button: Button in [_reset_dialog.get_ok_button(), _reset_dialog.get_cancel_button()]:
		button.custom_minimum_size = Vector2(240.0, 124.0)
		button.add_theme_font_size_override("font_size", 32)


func open(settings: GameSettings) -> void:
	_settings = settings if settings != null else GameSettings.new()
	_syncing = true
	_music_slider.value = _settings.music_volume
	_sfx_slider.value = _settings.sfx_volume
	_ui_scale_slider.value = _settings.ui_scale
	_vibration_toggle.button_pressed = _settings.vibration
	_shake_toggle.button_pressed = _settings.screen_shake
	_blood_toggle.button_pressed = _settings.blood
	_left_handed_toggle.button_pressed = _settings.left_handed
	_touch_buttons[int(_settings.touch_mode)].button_pressed = true
	_syncing = false
	_refresh_value_labels()
	visible = true
	_back_button.grab_focus()


func close() -> void:
	if not visible:
		return
	_reset_dialog.hide()
	visible = false
	closed.emit(_settings)


func is_open() -> bool:
	return visible


func _on_music_changed(value: float) -> void:
	_apply(func() -> void: _settings.music_volume = value)


func _on_sfx_changed(value: float) -> void:
	_apply(func() -> void: _settings.sfx_volume = value)


func _on_ui_scale_changed(value: float) -> void:
	_apply(func() -> void: _settings.ui_scale = value)


func _on_vibration_toggled(enabled: bool) -> void:
	_apply(func() -> void: _settings.vibration = enabled)


func _on_shake_toggled(enabled: bool) -> void:
	_apply(func() -> void: _settings.screen_shake = enabled)


func _on_blood_toggled(enabled: bool) -> void:
	_apply(func() -> void: _settings.blood = enabled)


func _on_left_handed_toggled(enabled: bool) -> void:
	_apply(func() -> void: _settings.left_handed = enabled)


func _on_touch_mode_selected(index: int) -> void:
	_apply(func() -> void: _settings.touch_mode = index as GameSettings.TouchMode)


func _apply(change: Callable) -> void:
	if _syncing:
		return
	change.call()
	_settings.sanitize()
	_refresh_value_labels()
	changed.emit(_settings)


## State is spelled out in text ("On"/"Off", brackets), not only shown by color or switch art.
func _refresh_value_labels() -> void:
	_music_value.text = "%d%%" % roundi(_settings.music_volume * 100.0)
	_sfx_value.text = "%d%%" % roundi(_settings.sfx_volume * 100.0)
	_ui_scale_value.text = "%d%%" % roundi(_settings.ui_scale * 100.0)
	_vibration_toggle.text = "Vibration: %s" % _on_off(_settings.vibration)
	_shake_toggle.text = "Shake: %s" % _on_off(_settings.screen_shake)
	_blood_toggle.text = "Blood: %s" % _on_off(_settings.blood)
	_left_handed_toggle.text = "Left-handed: %s" % _on_off(_settings.left_handed)
	for i: int in _touch_buttons.size():
		var label: String = TOUCH_MODE_NAMES[i]
		_touch_buttons[i].text = "[ %s ]" % label if i == int(_settings.touch_mode) else label


func _on_off(enabled: bool) -> String:
	return "On" if enabled else "Off"


func _on_reset_confirmed() -> void:
	var error: Error = SaveManager.new(save_path).reset_progress()
	if error == OK:
		_reset_button.text = "Progress reset"
		progress_reset.emit()
	else:
		_reset_button.text = "Reset failed (%d)" % error
