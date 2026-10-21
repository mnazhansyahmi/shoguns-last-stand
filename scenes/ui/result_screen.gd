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
@onready var _gold_detail: Label = %GoldDetail
@onready var _xp_detail: Label = %XpDetail
@onready var _xp_track: ProgressBar = %XpTrack
@onready var _celebration: ResultCelebration = %Celebration
var _presentation: Tween


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
		_gold_detail.text = "Enemies %d + bonus %d" % [reward.kill_gold, reward.bonus_gold]
		_xp_detail.text = "Enemies %d + bonus %d" % [reward.kill_xp, reward.bonus_xp]
	else:
		_title_label.text = "DEFEAT"
		_title_label.add_theme_color_override("font_color", DEFEAT_COLOR)
		_subtitle_label.text = "The village gate has fallen."
		var percent: int = roundi(reward.kill_ratio * 100.0)
		_gold_detail.text = "%d%% of enemy rewards" % percent
		_xp_detail.text = "%d%% of enemy rewards" % percent
	if reward.replay:
		_gold_detail.text += "\nReplay: %d%% gold" % roundi(reward.replay_multiplier * 100.0)
	_gold_label.text = "+%d" % reward.gold
	_xp_label.text = "+%d" % reward.xp
	_kills_label.text = str(reward.enemies_defeated)

	var level: int = progress.get_level()
	var next_level_xp: int = PlayerProgress.xp_for_level(level + 1)
	_totals_label.text = "Gold %d     /     Level %d     /     %d of %d XP" % [progress.gold, level, progress.xp, next_level_xp]
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
	_next_button.custom_minimum_size.x = maxf(430.0, (_next_button as InkMenuButton).minimum_label_width())
	(_retry_button as InkMenuButton).primary = not reward.victory
	(_upgrades_button as InkMenuButton).primary = reward.victory and next_stage_name.is_empty()
	_retry_button.queue_redraw()
	_upgrades_button.queue_redraw()
	_celebration.victory = reward.victory
	_celebration.reveal = 1.0
	if _presentation != null and _presentation.is_valid():
		_presentation.kill()
	var base_xp: int = PlayerProgress.xp_for_level(level)
	var fill: float = 100.0 * float(progress.xp - base_xp) / maxf(1.0, next_level_xp - base_xp)
	_xp_track.value = fill
	if not GameSettings.reduced_decorative_motion:
		_celebration.reveal = 0.0
		_xp_track.value = 0.0
		_presentation = create_tween().set_parallel(true)
		_presentation.tween_property(_celebration, "reveal", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_presentation.tween_property(_xp_track, "value", fill, 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	visible = true
	if _next_button.visible:
		_next_button.grab_focus()
	else:
		(_upgrades_button if reward.victory else _retry_button).grab_focus()
