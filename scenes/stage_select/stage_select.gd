class_name StageSelect
extends Control
## Stage select for the campaign: a tab per region (Bamboo Outskirts, Burning Village) and, for the region shown, one card
## per stage (a picture of the stage's own sky, its number, name and one line), a gold check on a cleared stage and a
## padlock on a locked one. The card in focus (or clicked / tapped) is the selected card; its details (waves, enemies,
## first-clear and replay gold) are in the side panel, which also has the Play button. Stages unlock in order across the
## regions (StageProgression); unlock state comes from the save's cleared stages. Enter on a card (or the confirm button,
## or a double click) starts it; a single tap only selects it, so the details can be read first. Page up / down (or a
## tab) switches region; a locked region still shows its cards, padlocked.

## Cards share the width of the card area but never get wider than this (their picture is cropped to fit, not stretched).
const MAX_CARD_WIDTH: float = 540.0
const CARD_GAP: float = 22.0
const TAB_FONT_SIZE: int = 30

## Overridable so automated runs never touch the player's real save.
@export var save_path: String = SaveManager.DEFAULT_PATH
## The region shown first (null = the region of the stage Continue would start).
@export var region: RegionData

@onready var _title_label: Label = %TitleLabel
@onready var _level_label: Label = %LevelLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _card_flow: HFlowContainer = %CardFlow
@onready var _region_tabs: HBoxContainer = %RegionTabs
@onready var _back_button: Button = %BackButton
@onready var _play_button: Button = %PlayButton
@onready var _detail_name: Label = %DetailName
@onready var _detail_description: Label = %DetailDescription
@onready var _detail_stats: Label = %DetailStats
@onready var _detail_rewards: Label = %DetailRewards
@onready var _detail_lock: Label = %DetailLock
@onready var _detail_foes: Label = %DetailFoes

var _progress: PlayerProgress
var _regions: Array[RegionData] = []
var _tab_buttons: Array[Button] = []
var _cards: Array[StageCard] = []
var _selected: int = -1


func _ready() -> void:
	AudioManager.play_music(&"stage_select")
	var save_manager: SaveManager = SaveManager.new(save_path)
	_progress = save_manager.load_progress()
	_regions = StageProgression.regions()
	if region == null:
		region = StageProgression.region_of(StageProgression.campaign_continue_stage(_progress))
	if region == null:
		region = StageProgression.default_region()
	_level_label.text = "Gold %d   -   Level %d" % [_progress.gold, _progress.get_level()]
	_back_button.pressed.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	_play_button.pressed.connect(_on_play_pressed)
	_build_tabs()
	_scroll.resized.connect(_fit_cards)
	show_region(region)
	if _cards.is_empty():
		_back_button.grab_focus()
		return
	_cards[maxi(_selected, 0)].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)
	elif event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		get_viewport().set_input_as_handled()
		var step: int = 1 if event.is_action_pressed("ui_page_down") else -1
		var index: int = _region_index(region)
		if not _regions.is_empty():
			show_region(_regions[posmod(index + step, _regions.size())])
			if not _cards.is_empty():
				_cards[maxi(_selected, 0)].grab_focus()


## How many cards go on a row, and how wide each is, for a card area `area_width` wide: as many as fit, then the rows are
## balanced (five cards in a space for four make a row of three and a row of two).
static func card_layout(count: int, area_width: float) -> Vector2:
	if count <= 0:
		return Vector2(1.0, StageCard.CARD_SIZE.x)
	var columns: int = clampi(floori((area_width + CARD_GAP) / (StageCard.CARD_SIZE.x + CARD_GAP)), 1, count)
	var rows: int = ceili(float(count) / float(columns))
	columns = ceili(float(count) / float(rows))
	var width: float = floorf((area_width - CARD_GAP * float(columns - 1)) / float(columns))
	return Vector2(float(columns), clampf(width, StageCard.CARD_SIZE.x, MAX_CARD_WIDTH))


func _fit_cards() -> void:
	var layout: Vector2 = card_layout(_cards.size(), _scroll.size.x - 12.0)
	for card: StageCard in _cards:
		card.custom_minimum_size = Vector2(layout.y, StageCard.CARD_SIZE.y)


func get_stage_card(index: int) -> StageCard:
	return _cards[index] if index >= 0 and index < _cards.size() else null


func get_selected_index() -> int:
	return _selected


func get_play_button() -> Button:
	return _play_button


## The region whose cards are shown.
func get_region() -> RegionData:
	return region


func get_region_tab(index: int) -> Button:
	return _tab_buttons[index] if index >= 0 and index < _tab_buttons.size() else null


## Shows `shown`'s cards, with the stage Continue would start there (its first stage not cleared) selected.
func show_region(shown: RegionData) -> void:
	if shown == null:
		return
	region = shown
	_title_label.text = region.display_name
	var tab: int = _region_index(region)
	for i: int in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == tab)
	_build_cards()
	_fit_cards()
	if _cards.is_empty():
		_selected = -1
		return
	_select(maxi(region.index_of(StageProgression.continue_stage(_progress, region)), 0))


func _region_index(shown: RegionData) -> int:
	for i: int in _regions.size():
		if shown != null and _regions[i].region_id == shown.region_id:
			return i
	return -1


func _build_tabs() -> void:
	var group: ButtonGroup = ButtonGroup.new()
	for i: int in _regions.size():
		var button: Button = Button.new()
		button.name = "RegionTab%d" % (i + 1)
		button.text = _regions[i].display_name
		button.toggle_mode = true
		button.button_group = group
		button.theme_type_variation = &"ToggleButton"
		button.custom_minimum_size = Vector2(300.0, 124.0)
		button.add_theme_font_size_override("font_size", TAB_FONT_SIZE)
		button.pressed.connect(_on_tab_pressed.bind(i))
		_region_tabs.add_child(button)
		_tab_buttons.append(button)


func _on_tab_pressed(index: int) -> void:
	if index >= 0 and index < _regions.size() and _regions[index] != region:
		show_region(_regions[index])


func _build_cards() -> void:
	for card: StageCard in _cards:
		_card_flow.remove_child(card)
		card.queue_free()
	_cards.clear()
	if region == null:
		push_error("StageSelect: no region assigned.")
		return
	var first_number: int = StageProgression.first_stage_number(region)
	for i: int in region.stages.size():
		var stage: StageData = region.stages[i]
		if stage == null:
			push_error("StageSelect: region has an empty stage slot at %d." % i)
			continue
		var unlocked: bool = StageProgression.is_unlocked(_progress, region, i)
		var locked_text: String = ""
		var required: StageData = StageProgression.required_stage(region, i)
		if not unlocked and required != null:
			locked_text = "Clear %s" % required.display_name
		var card: StageCard = StageCard.new()
		card.setup(stage, i, unlocked, _progress.is_stage_cleared(stage.stage_id), locked_text, first_number + i)
		card.selected.connect(_on_card_selected)
		card.activated.connect(_on_card_activated)
		_card_flow.add_child(card)
		_cards.append(card)


func _on_card_selected(card: StageCard) -> void:
	_select(card.index)


func _on_card_activated(card: StageCard) -> void:
	if card.unlocked:
		SceneRoutes.go_to_battle(get_tree(), card.stage)


func _on_play_pressed() -> void:
	var card: StageCard = get_stage_card(_selected)
	if card != null and card.unlocked:
		SceneRoutes.go_to_battle(get_tree(), card.stage)


func _select(index: int) -> void:
	_selected = index
	for card: StageCard in _cards:
		card.is_selected = card.index == index
	_show_details(get_stage_card(index))


## The side panel: the selected stage's name, description, enemies, waves and gold (or, for a locked stage, what unlocks it).
func _show_details(card: StageCard) -> void:
	if card == null:
		return
	var stage: StageData = card.stage
	_detail_name.text = "%d. %s" % [card.get_number(), stage.display_name]
	_detail_description.text = stage.description
	var unlocked: bool = card.unlocked
	_detail_stats.visible = unlocked
	_detail_rewards.visible = unlocked
	_detail_lock.visible = not unlocked
	# The new foes and how to beat them show even on a locked stage, so the player can prepare.
	_detail_foes.text = foes_text(stage)
	_detail_foes.visible = not _detail_foes.text.is_empty()
	_play_button.disabled = not unlocked
	_play_button.text = "Play" if unlocked else "Locked"
	if not unlocked:
		_detail_lock.text = "%s first." % card.locked_text if not card.locked_text.is_empty() else "Locked."
		return
	_detail_stats.text = stats_text(stage)
	_detail_rewards.text = rewards_text(stage, card.cleared)


## "5 waves", "42 soldiers", "3 Oni Brutes", "12 Flying Spirits" and, for a boss stage, "Boss: The Fallen Daimyo".
static func stats_text(stage: StageData) -> String:
	var lines: Array[String] = ["%d %s" % [stage.waves.size(), "wave" if stage.waves.size() == 1 else "waves"]]
	lines.append_array(StageBriefing.count_lines(stage))
	if stage.has_boss():
		lines.append("Boss: %s" % stage.boss_name())
	return "\n".join(lines)


## How to beat the foes this stage brings for the first time ("New - Shield Bearer: ..."), or "".
static func foes_text(stage: StageData) -> String:
	var lines: Array[String] = []
	for enemy: EnemyData in StageBriefing.new_foes(stage):
		lines.append("New - " + StageBriefing.hint_line(enemy))
	return "\n".join(lines)


## The gold for a first clear and for a replay (a cleared stage says what its replays pay).
static func rewards_text(stage: StageData, cleared: bool) -> String:
	var first_gold: int = stage.get_full_clear_gold()
	var replay_gold: int = floori(first_gold * stage.replay_gold_multiplier)
	var text: String = "First clear: %d gold\nReplay: %d gold" % [first_gold, replay_gold]
	if cleared:
		text += "\n(replays pay %d%% of the first clear)" % roundi(stage.replay_gold_multiplier * 100.0)
	return text
