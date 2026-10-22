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
enum Tab { AUDIO, DISPLAY, GAMEPLAY }
const TAB_NAMES: PackedStringArray = ["Audio", "Display", "Gameplay"]

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
var _controls_page: CenterContainer
var _controls_button: Button
var _motion_toggle: Button
var _pages: Array[VBoxContainer] = []
var _tab_buttons: Array[Button] = []
var _tab: Tab = Tab.AUDIO


func _ready() -> void:
	visible = false
	_build_controls_page()
	_motion_toggle = Button.new()
	_motion_toggle.name = "MotionToggle"
	_motion_toggle.toggle_mode = true
	_motion_toggle.theme_type_variation = &"ToggleButton"
	_motion_toggle.custom_minimum_size = Vector2(260.0, 124.0)
	_motion_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_motion_toggle.add_theme_font_size_override("font_size", 30)
	_motion_toggle.tooltip_text = "Reduce decorative hair and cloth motion. Combat poses stay responsive."
	_shake_toggle.get_parent().add_child(_motion_toggle)
	_motion_toggle.toggled.connect(func(enabled: bool) -> void: _apply(func() -> void: _settings.reduced_motion = enabled))
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
	_build_tabs()


func open(settings: GameSettings) -> void:
	show_controls(false)
	select_tab(Tab.AUDIO)
	_settings = settings if settings != null else GameSettings.new()
	_syncing = true
	_music_slider.value = _settings.music_volume
	_sfx_slider.value = _settings.sfx_volume
	_ui_scale_slider.value = _settings.ui_scale
	_vibration_toggle.button_pressed = _settings.vibration
	_shake_toggle.button_pressed = _settings.screen_shake
	_motion_toggle.button_pressed = _settings.reduced_motion
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
	show_controls(false)
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
	_motion_toggle.text = "Motion: %s" % ("Reduced" if _settings.reduced_motion else "Full")
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


func _build_controls_page() -> void:
	_controls_button = Button.new()
	_controls_button.name = "ControlsButton"
	_controls_button.text = "Controls"
	_controls_button.custom_minimum_size = Vector2(300.0, 124.0)
	_controls_button.add_theme_font_size_override("font_size", 34)
	_back_button.get_parent().add_child(_controls_button)
	_back_button.get_parent().move_child(_controls_button, _back_button.get_index())
	_controls_button.pressed.connect(show_controls.bind(true))
	_controls_page = CenterContainer.new()
	_controls_page.name = "ControlsPage"
	_controls_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_controls_page)
	var panel: PanelContainer = PanelContainer.new()
	_controls_page.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	panel.add_child(margin)
	var guide: ControlsGuide = ControlsGuide.new()
	margin.add_child(guide)
	guide.back_requested.connect(show_controls.bind(false))
	_controls_page.hide()


func show_controls(enabled: bool = true) -> void:
	var returning: bool = _controls_page.visible and not enabled
	$Center.visible = not enabled
	_controls_page.visible = enabled
	if returning: select_tab(Tab.GAMEPLAY)
	if visible:
		if enabled:
			var guide: ControlsGuide = _controls_page.get_child(0).get_child(0).get_child(0) as ControlsGuide
			(guide.get_child(guide.get_child_count() - 1) as Button).grab_focus()
		else:
			if _tab == Tab.GAMEPLAY: _controls_button.grab_focus()
			elif not _tab_buttons.is_empty(): _tab_buttons[_tab].grab_focus()


func is_controls_open() -> bool:
	return visible and _controls_page.visible


func _build_tabs() -> void:
	var content: VBoxContainer = $Center/Panel/Margin/VBox
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.add_theme_constant_override("separation", 16)
	content.add_child(tabs)
	content.move_child(tabs, 1)
	var pages: VBoxContainer = VBoxContainer.new()
	pages.name = "Pages"
	pages.custom_minimum_size.y = 400.0
	content.add_child(pages)
	content.move_child(pages, 2)
	var group: ButtonGroup = ButtonGroup.new()
	for index: int in TAB_NAMES.size():
		var button: Button = Button.new()
		button.text = TAB_NAMES[index]
		button.name = TAB_NAMES[index] + "Tab"
		button.toggle_mode = true
		button.button_group = group
		button.theme_type_variation = &"ToggleButton"
		button.custom_minimum_size = Vector2(300, 124)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 34)
		button.pressed.connect(select_tab.bind(index))
		button.focus_entered.connect(select_tab.bind(index))
		tabs.add_child(button)
		_tab_buttons.append(button)
		var page: VBoxContainer = VBoxContainer.new()
		page.name = TAB_NAMES[index] + "Page"
		page.add_theme_constant_override("separation", 16)
		pages.add_child(page)
		_pages.append(page)
	var audio_grid: GridContainer = content.get_node("Sliders")
	audio_grid.reparent(_pages[Tab.AUDIO])
	var display_grid: GridContainer = GridContainer.new()
	display_grid.columns = 3
	display_grid.add_theme_constant_override("h_separation", 28)
	_pages[Tab.DISPLAY].add_child(display_grid)
	for node_name: String in ["UiScaleLabel", "UiScaleSlider", "UiScaleValue"]:
		audio_grid.get_node(NodePath(node_name)).reparent(display_grid)
	var effects: HBoxContainer = HBoxContainer.new()
	effects.add_theme_constant_override("separation", 16)
	_pages[Tab.DISPLAY].add_child(effects)
	for button: Button in [_motion_toggle, _shake_toggle, _blood_toggle]: button.reparent(effects)
	var input_toggles: HBoxContainer = HBoxContainer.new()
	input_toggles.add_theme_constant_override("separation", 16)
	_pages[Tab.GAMEPLAY].add_child(input_toggles)
	for button: Button in [_left_handed_toggle, _vibration_toggle]: button.reparent(input_toggles)
	content.get_node("TouchRow").reparent(_pages[Tab.GAMEPLAY])
	var gameplay_actions: HBoxContainer = HBoxContainer.new()
	gameplay_actions.add_theme_constant_override("separation", 16)
	_pages[Tab.GAMEPLAY].add_child(gameplay_actions)
	for button: Button in [_controls_button, _reset_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.reparent(gameplay_actions)
	content.get_node("Toggles").queue_free()
	select_tab(Tab.AUDIO)


func select_tab(index: int) -> void:
	_tab = clampi(index, 0, TAB_NAMES.size() - 1) as Tab
	for page: int in _pages.size():
		_pages[page].visible = page == int(_tab)
		_tab_buttons[page].set_pressed_no_signal(page == int(_tab))


func get_selected_tab() -> Tab:
	return _tab


func _unhandled_input(event: InputEvent) -> void:
	if not visible or is_controls_open(): return
	var direction: int = 1 if event.is_action_pressed("ui_page_down") else (-1 if event.is_action_pressed("ui_page_up") else 0)
	if direction == 0: return
	select_tab((int(_tab) + direction + TAB_NAMES.size()) % TAB_NAMES.size())
	_tab_buttons[_tab].grab_focus()
	get_viewport().set_input_as_handled()
