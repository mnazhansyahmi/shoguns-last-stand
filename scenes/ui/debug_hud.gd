class_name DebugHud
extends CanvasLayer
## Temporary text HUD for Phase 2 testing. Replaced by the mobile HUD in Phase 5.

@onready var _player_health_label: Label = %PlayerHealthLabel
@onready var _gate_health_label: Label = %GateHealthLabel
@onready var _cooldown_label: Label = %CooldownLabel
@onready var _enemy_count_label: Label = %EnemyCountLabel
@onready var _status_label: Label = %StatusLabel


func set_player_health(current: float, maximum: float) -> void:
	_player_health_label.text = "Samurai HP: %d / %d" % [ceili(current), roundi(maximum)]


func set_gate_health(current: float, maximum: float) -> void:
	_gate_health_label.text = "Gate HP: %d / %d" % [ceili(current), roundi(maximum)]


func set_cooldowns(dash_left: float, heavy_left: float, slash_left: float) -> void:
	_cooldown_label.text = "Dash: %s   Heavy: %s   Spirit Slash: %s" % [
		_format_cooldown(dash_left), _format_cooldown(heavy_left), _format_cooldown(slash_left)]


func set_enemy_count(count: int) -> void:
	_enemy_count_label.text = "Enemies: %d" % count


func show_status(text: String) -> void:
	_status_label.text = text
	_status_label.visible = true


func hide_status() -> void:
	_status_label.visible = false


func _format_cooldown(seconds: float) -> String:
	return "ready" if seconds <= 0.0 else "%.1fs" % seconds
