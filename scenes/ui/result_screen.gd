class_name ResultScreen
extends CanvasLayer
## Victory / Defeat overlay with the rewards earned. Keeps working while the tree is paused.

signal retry_requested
signal upgrades_requested
signal main_menu_requested
signal next_stage_requested

const VICTORY_COLOR: Color = InkPalette.GOLD_BRIGHT
const DEFEAT_COLOR: Color = InkPalette.EMBER_TEXT
const WARNING_COLOR: Color = InkPalette.EMBER_TEXT
const OK_COLOR: Color = InkPalette.PARCHMENT_DIM

@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _kills_label: Label = %KillsLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _xp_label: Label = %XpLabel
@onready var _totals_label: Label = %TotalsLabel
@onready var _level_up_label: Label = %LevelUpLabel
@onready var _save_label: Label = %SaveLabel
@onready var _retry_button: Button = %RetryButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _menu_button: Button = %MenuButton
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	visible = false
	_retry_button.pressed.connect(retry_requested.emit)
	_upgrades_button.pressed.connect(upgrades_requested.emit)
	_menu_button.pressed.connect(main_menu_requested.emit)
	_next_button.pressed.connect(next_stage_requested.emit)
	_next_button.visible = false


## `next_stage_name` non-empty shows the Next Stage button (only after a first clear).
func show_result(reward: BattleReward, progress: PlayerProgress, levels_gained: int, save_error: Error,
		next_stage_name: String = "", new_allies: PackedStringArray = PackedStringArray()) -> void:
	if reward.victory:
		_title_label.text = "VICTORY"
		_title_label.add_theme_color_override("font_color", VICTORY_COLOR)
		_subtitle_label.text = "The village is safe."
		if not new_allies.is_empty():
			_subtitle_label.text += "   New ally: %s!" % ", ".join(new_allies)
		_gold_label.text = "Gold earned: +%d   (enemies %d + stage bonus %d)" % [reward.gold, reward.kill_gold, reward.bonus_gold]
		_xp_label.text = "XP earned: +%d   (enemies %d + stage bonus %d)" % [reward.xp, reward.kill_xp, reward.bonus_xp]
	else:
		_title_label.text = "DEFEAT"
		_title_label.add_theme_color_override("font_color", DEFEAT_COLOR)
		_subtitle_label.text = "The village gate has fallen."
		var percent: int = roundi(reward.kill_ratio * 100.0)
		_gold_label.text = "Gold earned: +%d   (%d%% of enemy rewards)" % [reward.gold, percent]
		_xp_label.text = "XP earned: +%d   (%d%% of enemy rewards)" % [reward.xp, percent]
	if reward.replay:
		_gold_label.text += "   - replay: %d%% gold" % roundi(reward.replay_multiplier * 100.0)
	_kills_label.text = "Enemies defeated: %d" % reward.enemies_defeated

	var level: int = progress.get_level()
	var next_level_xp: int = PlayerProgress.xp_for_level(level + 1)
	_totals_label.text = "Total gold: %d      Level %d   (%d / %d XP)" % [progress.gold, level, progress.xp, next_level_xp]
	_level_up_label.visible = levels_gained > 0
	_level_up_label.text = "Level up! You are now level %d." % level

	if save_error == OK:
		_save_label.text = "Progress saved."
		_save_label.add_theme_color_override("font_color", OK_COLOR)
	else:
		_save_label.text = "Could not save progress (error %d). Rewards are lost if you quit." % save_error
		_save_label.add_theme_color_override("font_color", WARNING_COLOR)

	_next_button.visible = not next_stage_name.is_empty()
	_next_button.text = "Next: %s" % next_stage_name if not next_stage_name.is_empty() else "Next Stage"
	visible = true
	if _next_button.visible:
		_next_button.grab_focus()
	else:
		_retry_button.grab_focus()
