class_name GameHud
extends CanvasLayer
## Battle HUD. Top-left: samurai/energy/gate bars and ability cooldown bars (fill + text).
## Top-center: wave and enemies remaining. Top-right: pause button. Keyboard hints at the bottom
## are hidden while touch controls are shown. Respects the safe area and UI scale.

signal pause_requested

const BANNER_FADE_TIME: float = 0.4
const SCREEN_MARGIN: Vector2 = Vector2(32.0, 24.0)
## Room kept free above the touch summon buttons for messages.
const TOUCH_BOTTOM_SPACE: float = 230.0
## Edge indicator tabs start this far below the top of the safe area (under the top HUD).
const INDICATOR_TOP: float = 196.0

@onready var _margin: MarginContainer = $Margin
@onready var _top_left: VBoxContainer = %TopLeft
@onready var _wave_box: VBoxContainer = %WaveBox
@onready var _player_bar: FillBar = %PlayerBar
@onready var _energy_bar: FillBar = %EnergyBar
@onready var _gate_bar: FillBar = %GateBar
@onready var _ability_row: HBoxContainer = %AbilityRow
@onready var _ability_bars: Dictionary = {"dash": %DashBar, "heavy": %HeavyBar, "slash": %SlashBar}
@onready var _wave_label: Label = %WaveLabel
@onready var _remaining_label: Label = %RemainingLabel
@onready var _pause_button: Button = %PauseButton
@onready var _banner_label: Label = %BannerLabel
@onready var _status_label: Label = %StatusLabel
@onready var _message_label: Label = %MessageLabel
@onready var _summon_label: Label = %SummonLabel
@onready var _hint_label: Label = %HintLabel
@onready var _debug_hint_label: Label = %DebugHintLabel
@onready var _touch_spacer: Control = %TouchSpacer

var _gate_indicator: EdgeIndicator
var _enemy_indicator: EdgeIndicator
var _banner_tween: Tween
var _message_tween: Tween
var _touch_mode: bool = false
var _debug_hint_allowed: bool = false
var _ui_scale: float = 1.0


func _ready() -> void:
	_gate_indicator = EdgeIndicator.new()
	_gate_indicator.name = "GateIndicator"
	_gate_indicator.points_left = true
	add_child(_gate_indicator)
	_enemy_indicator = EdgeIndicator.new()
	_enemy_indicator.name = "EnemyIndicator"
	_enemy_indicator.points_left = false
	add_child(_enemy_indicator)
	_place_indicators(get_viewport().get_visible_rect())
	_pause_button.pressed.connect(pause_requested.emit)
	_top_left.resized.connect(_update_pivots)
	_wave_box.resized.connect(_update_pivots)


func set_player_health(current: float, maximum: float) -> void:
	_player_bar.set_value(current, maximum)


func set_gate_health(current: float, maximum: float) -> void:
	_gate_bar.set_value(current, maximum)


func set_energy(current: float, maximum: float) -> void:
	_energy_bar.set_ratio_text(current / maxf(maximum, 0.001), "%d / %d" % [floori(current), roundi(maximum)])


## cooldowns: {"dash": Vector2(seconds_left, total), "heavy": ..., "slash": ...}
func set_ability_cooldowns(cooldowns: Dictionary) -> void:
	for key: String in _ability_bars:
		var info: Vector2 = cooldowns.get(key, Vector2.ZERO)
		var bar: FillBar = _ability_bars[key]
		var readiness: float = 1.0 - info.x / maxf(info.y, 0.001) if info.x > 0.0 else 1.0
		bar.set_ratio_text(readiness, format_cooldown(info.x))


func set_wave_text(text: String) -> void:
	_wave_label.text = text


func set_remaining(count: int) -> void:
	_remaining_label.text = "Enemies remaining: %d" % count


func set_summon_text(text: String) -> void:
	_summon_label.text = text


func set_debug_hint_visible(visible_flag: bool) -> void:
	_debug_hint_allowed = visible_flag
	_refresh_bottom()


## Touch controls show cooldowns and summons themselves, so keyboard-only parts are hidden.
func set_touch_mode(enabled: bool) -> void:
	_touch_mode = enabled
	_refresh_bottom()


## Keeps HUD content inside the safe area and scales the corner clusters around their corners.
func apply_layout(safe_rect: Rect2, viewport_size: Vector2, ui_scale: float) -> void:
	_ui_scale = TouchLayout.clamp_scale(ui_scale)
	_margin.add_theme_constant_override("margin_left", roundi(safe_rect.position.x + SCREEN_MARGIN.x))
	_margin.add_theme_constant_override("margin_top", roundi(safe_rect.position.y + SCREEN_MARGIN.y))
	_margin.add_theme_constant_override("margin_right", roundi(viewport_size.x - safe_rect.end.x + SCREEN_MARGIN.x))
	_margin.add_theme_constant_override("margin_bottom", roundi(viewport_size.y - safe_rect.end.y + SCREEN_MARGIN.y))
	for control: Control in [_top_left, _wave_box, _pause_button]:
		control.scale = Vector2(_ui_scale, _ui_scale)
	_place_indicators(safe_rect)
	_refresh_bottom()
	_update_pivots()


## Off-screen markers: the gate (left edge) and incoming enemies (right edge).
## gate_ratio = gate health 0..1; at_gate = enemies off screen to the left (at the gate).
func set_edge_indicators(gate_hidden: bool, gate_ratio: float, at_gate: int, gate_alert: bool,
		incoming: int, oni_incoming: bool) -> void:
	if gate_hidden:
		_gate_indicator.show_info("Gate %d%%" % roundi(gate_ratio * 100.0),
				("%d at the gate" % at_gate) if at_gate > 0 else "", gate_ratio, gate_alert)
	else:
		_gate_indicator.hide_info()
	if incoming > 0:
		_enemy_indicator.show_info("%d incoming" % incoming, "Oni Brute!" if oni_incoming else "", -1.0, oni_incoming)
	else:
		_enemy_indicator.hide_info()


func get_gate_indicator() -> EdgeIndicator:
	return _gate_indicator


func get_enemy_indicator() -> EdgeIndicator:
	return _enemy_indicator


## Tabs sit at the screen edges just below the top HUD (health bars, pause button), above
## the fighters' heads and well clear of the touch controls.
func _place_indicators(safe_rect: Rect2) -> void:
	var y: float = safe_rect.position.y + INDICATOR_TOP * _ui_scale
	for indicator: EdgeIndicator in [_gate_indicator, _enemy_indicator]:
		if indicator == null:
			continue
		indicator.scale = Vector2(_ui_scale, _ui_scale)
		var width: float = EdgeIndicator.TAB_SIZE.x * _ui_scale
		var x: float = safe_rect.position.x + 8.0 if indicator.points_left else safe_rect.end.x - 8.0 - width
		indicator.position = Vector2(x, y)


func get_pause_button_rect() -> Rect2:
	return _pause_button.get_global_rect()


## Big centered text that fades out after `duration` seconds.
func show_banner(text: String, duration: float = 2.0) -> void:
	_banner_tween = _show_fading(_banner_label, text, duration, _banner_tween)


## Small message above the summon area (e.g. why a summon failed).
func show_message(text: String, duration: float = 1.2) -> void:
	_message_tween = _show_fading(_message_label, text, duration, _message_tween)


func show_status(text: String, color: Color = InkPalette.EMBER_TEXT) -> void:
	_banner_label.visible = false
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)
	_status_label.visible = true


func hide_status() -> void:
	_status_label.visible = false


static func format_cooldown(seconds: float) -> String:
	return "ready" if seconds <= 0.0 else "%.1fs" % seconds


func _refresh_bottom() -> void:
	_summon_label.visible = not _touch_mode
	_hint_label.visible = not _touch_mode
	_debug_hint_label.visible = _debug_hint_allowed and not _touch_mode
	_ability_row.visible = not _touch_mode
	_touch_spacer.custom_minimum_size.y = TOUCH_BOTTOM_SPACE * _ui_scale if _touch_mode else 0.0


func _update_pivots() -> void:
	_top_left.pivot_offset = Vector2.ZERO
	_wave_box.pivot_offset = Vector2(_wave_box.size.x * 0.5, 0.0)
	_pause_button.pivot_offset = Vector2(_pause_button.size.x, 0.0)


func _show_fading(label: Label, text: String, duration: float, previous: Tween) -> Tween:
	if previous != null and previous.is_valid():
		previous.kill()
	label.text = text
	label.modulate.a = 1.0
	label.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, BANNER_FADE_TIME)
	tween.tween_callback(label.hide)
	return tween
