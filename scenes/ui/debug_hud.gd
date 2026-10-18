class_name DebugHud
extends CanvasLayer
## Temporary text HUD for testing. Replaced by the mobile HUD in Phase 5.

const BANNER_FADE_TIME: float = 0.4

@onready var _player_health_label: Label = %PlayerHealthLabel
@onready var _gate_health_label: Label = %GateHealthLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _cooldown_label: Label = %CooldownLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _remaining_label: Label = %RemainingLabel
@onready var _banner_label: Label = %BannerLabel
@onready var _status_label: Label = %StatusLabel
@onready var _message_label: Label = %MessageLabel
@onready var _summon_label: Label = %SummonLabel
@onready var _debug_hint_label: Label = %DebugHintLabel

var _banner_tween: Tween
var _message_tween: Tween


func set_player_health(current: float, maximum: float) -> void:
	_player_health_label.text = "Samurai HP: %d / %d" % [ceili(current), roundi(maximum)]


func set_gate_health(current: float, maximum: float) -> void:
	_gate_health_label.text = "Gate HP: %d / %d" % [ceili(current), roundi(maximum)]


func set_energy(current: float, maximum: float) -> void:
	_energy_label.text = "Spirit Energy: %d / %d" % [floori(current), roundi(maximum)]


func set_cooldowns(dash_left: float, heavy_left: float, slash_left: float) -> void:
	_cooldown_label.text = "Dash: %s   Heavy: %s   Spirit Slash: %s" % [
		format_cooldown(dash_left), format_cooldown(heavy_left), format_cooldown(slash_left)]


func set_wave_text(text: String) -> void:
	_wave_label.text = text


func set_remaining(count: int) -> void:
	_remaining_label.text = "Enemies remaining: %d" % count


func set_summon_text(text: String) -> void:
	_summon_label.text = text


func set_debug_hint_visible(visible_flag: bool) -> void:
	_debug_hint_label.visible = visible_flag


## Big centered text that fades out after `duration` seconds.
func show_banner(text: String, duration: float = 2.0) -> void:
	_banner_tween = _show_fading(_banner_label, text, duration, _banner_tween)


## Small message above the summon bar (e.g. why a summon failed).
func show_message(text: String, duration: float = 1.2) -> void:
	_message_tween = _show_fading(_message_label, text, duration, _message_tween)


func show_status(text: String, color: Color = Color(1.0, 0.3, 0.25)) -> void:
	_banner_label.visible = false
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)
	_status_label.visible = true


func hide_status() -> void:
	_status_label.visible = false


static func format_cooldown(seconds: float) -> String:
	return "ready" if seconds <= 0.0 else "%.1fs" % seconds


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
